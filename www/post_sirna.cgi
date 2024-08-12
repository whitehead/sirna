#!/usr/local/bin/perl -w -I./  -I/cgi-bin/siRNAext/lib/
 
#################################################################
# Copyright(c) 2004 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     7/18/2004
# author:      Bingbing Yuan
#################################################################

# ====================================================== #
# purpose: write center html and download pages
#          
# need:    Sort.pm
# called by siRNA_step2.cgi or by web user
# ====================================================== #

package SiRNA;
 
use strict;
use File::Basename;
use siRNA_log;
use siRNA_util;
use CGI;
use Sort;
use Check;
use SubHtmlWriter;
use BlastParser;
use GeneObject2;
use SiRNAObject;
use Database;
use File::Copy;

my $query = new CGI;

our $ACTION    = $query->param('action');
our $MySessionIDSub    = $query->param('UNIQID');
our $MyDataTxt3   = $query->param('DATA');
our $SORT_NAME = $query->param('sort');

our $BlastFilterHashRef;
$BlastFilterHashRef->{'IDENTITY'} = "";
$BlastFilterHashRef->{'POSITION'} = "";
my $blastfilter = $query->param('BLASTFILTER');
$BlastFilterHashRef->{$blastfilter}="checked";

our $IDENTITYNUM = $query->param('IDENTITYNUM');
our $USERGENEID  = $query->param('USERGENEID');
$IDENTITYNUM =~ s/\s+//g if ($IDENTITYNUM);
$USERGENEID  =~ s/\s+//g if ($USERGENEID);

our ($ParamRef, $SirnaAref);
our $SelectedSirnaHref;  # 157 "checked", 595, ""
our ($BlastSeqLength);
our $SortImgHref;        # kyes: pos, gc, energy, type
our ($MyDataAlignUrl, $DateDir, $DataDirUrl, $ENDING, $MyCenterHtml, $MyDataTabTxt, $cgiHome, $LENGTH);
our ($SPECIES, $BLAST, $DATABASE, $ACC, $GI, $GENE_ID, $LOCUSLINK, $UNIGENECLUSTER, $ENSEMBL, $OrgCenterHtmlUrl,$OrgCenterHtml, $BlastStart, $BlastEnd);

our $PosRef;

# ======================================== #
#                SORT
# ======================================== #
if ($ACTION eq "SORT") {
    print $query->header("text/html");
    
    # get parameters from file: txt3
    ($ParamRef, $SirnaAref) = get_parameters($MyDataTxt3);

    # match parameters to step2.cgi variables used in "centerHtml"
    matchParam();

    SiRNA::mydebug("%%%%%%%BlastSeqLength=",$BlastSeqLength);
    for (my $i=1; $i<=$BlastSeqLength; $i++) {
	SiRNA::mydebug("%%%%%%%",$query->param("POS_$i"));
	  if ($query->param("POS_$i")) {
	      SiRNA::mydebug("%%%%%%%checked");
		$PosRef->[$i] = "checked";
	    }
	  else {
	      $PosRef->[$i] = "";
	  }
      }

    my @chosenSirna  = $query->param('SIRNA');
    my $selections = $query->param('SELECTIONS');

    # construct hash and set whatever it is checked(chosen/unchosen)
    my @arr = split(";",$selections);
    SiRNA::mydebug("#####chosenSirna=", $#chosenSirna);
    SiRNA::mydebug("#####chosenSirna2=", $#arr);

    foreach my $a (@arr) {
	foreach my $c(@chosenSirna) {
	    SiRNA::mydebug("#####compare $a $c");
	    if ($a eq $c) {
	    SiRNA::mydebug("#####is true");
		$SelectedSirnaHref -> {$a} = "checked";
	      last;
	    }
	    else {
	    SiRNA::mydebug("#####is false");
		$SelectedSirnaHref -> {$a} = "";
	    }
	}
    }
    
    my $GeneObj = GeneObject2->new(
				  acc => $ACC,
				  gi  => $GI
				  );
    
    for my $a(0..$#{$SirnaAref}) {

	# html tab blast result
	# 1   147   AACTCTAGGAACAAATTGGACTT  A,B   40  0  rs#abc	18/23   2003-12-18-51919-28566_1_AACTCTAGGAACAAATTGGACTT.html coding
	my $blast_html = $SirnaAref->[$a][8];
	$blast_html =~ s/\_out/\.html/;
	
	my $sirna_obj = SiRNAObject->new(
					 pos                     => $SirnaAref->[$a][1],
					 full_seq                => $SirnaAref->[$a][2],
					 type                    => $SirnaAref->[$a][3],
					 gc_percentage           => $SirnaAref->[$a][4],
					 energy                  => $SirnaAref->[$a][5],
					 snp_id                  => $SirnaAref->[$a][6],
					 max_non_target_identity => $SirnaAref->[$a][7],
					 blastout                => $ParamRef->{"OUTDIR"}->[0] . "/" . $SirnaAref->[$a][8],
					 region                  => $SirnaAref->[$a][9],
					 species                 => $SPECIES,
					 blast                   => $BLAST,
					 database                => $DATABASE,
					 blasthtml               => $ParamRef->{"OUTDIR"}->[0] . "/" . $blast_html
					 );

	$GeneObj->addSiRNA($sirna_obj);
    }
    

    # sort the sirnas
    mydebug("sort_by=$SORT_NAME");
    my $sortedSirnaRef = sort_sirna($GeneObj->sirnas, $SORT_NAME);
    mydebug("sort returned ", @{$sortedSirnaRef});
    mydebug("before set: ", @{$GeneObj->sirnas});
    #$GeneObj->sirnas($sortedSirnaRef);
    my $sirnaIndex = 0;
    foreach my $sirna (@{$sortedSirnaRef}) {
        $GeneObj->sirnas->[$sirnaIndex++] = $sirna;
    } 
    mydebug("after set: ", @{$GeneObj->sirnas});

    # sort image
    my @items = qw(energy pos type gc);
    foreach my $i (@items) {
	if ($SORT_NAME =~ /$i/) {
	    $SortImgHref->{$i} = "sorted.gif";
	}
	else {
	    $SortImgHref->{$i} = "unsort.gif";
	}
    }
    
    # write the center html
    centerHtml($GeneObj);

    if ($ParamRef->{'MYCENTERHTML'}->[0] =~ /\/(tmp\/.*\/.*)$/) {
	Check->redirectToLoginPage($1);
    }
}

# =============================== #
#       Get sense/as siRNAs
# =============================== #
elsif ($ACTION eq "GET") {
	print $query->header("text/plain");
	
	# get parameters from file: txt3
	($ParamRef, $SirnaAref) = get_parameters($MyDataTxt3);
	
	my @CHOSEN_SIRNAS = $query->param('SIRNA');
	
	my @SIRNAS = sort { $a->[0]<=>$b->[0] } @{$SirnaAref};
	
	print "Start_Pos\tcDNA\tSense\tAntisense\n";
	
	if ($#CHOSEN_SIRNAS >=0 ) {
	    foreach my $id (sort { $a<=>$b } @CHOSEN_SIRNAS) {
		SiRNA::mydebug("%%%^^^id=", $id);
		foreach my $i(0 .. $#SIRNAS) {
		SiRNA::mydebug("%%%^^^i=", $i, "equal to ? ", $SIRNAS[$i][1]);
		    if ($id eq $SIRNAS[$i][1]) {
			# selected sirna
			# 1   147   AACTCTAGGAACAAATTGGACTT  A,B   40  0  rs#abc	18/23   2003-12-18-51919-28566_1_AACTCTAGGAACAAATTGGACTT.html
			my $sense = SiRNA::find_siRNA_sense( $SIRNAS[$i][2], $ParamRef->{'ENDING'}->[0] );
			my $antisnese = SiRNA::find_siRNA_antisense( $SIRNAS[$i][2], $ParamRef->{'ENDING'}->[0] );
			
			print 
			    "$SIRNAS[$i][1]\t",
			    "$SIRNAS[$i][2]\t",
			    "$sense\t",
			    "$antisnese\n";
			
		    }	
		    # avoid useless loop
		    elsif ($id > $SIRNAS[$i][0]) {
			next;
		    }
		}	
	    }
	}
	
}

# ======================================== #
#      filter siRNAs by BLAST results
# ======================================== #
elsif ($ACTION eq "FILTER") {
    
    print $query->header("text/html");
    
    # get parameters from file: txt3
    ($ParamRef, $SirnaAref) = get_parameters($MyDataTxt3);

    # match parameters to step2.cgi variables used in "centerHtml"
    matchParam();

    # make a copy for centerHtml: back
    copy($MyCenterHtml, $OrgCenterHtml) || SiRNA::myfatal ( "copy failed: $!" );

    my @chosenSirna = ();
    if ($ACTION eq "FILTER") {
	# only keep the chosen sirna
	# remove not chosen sirna
	@chosenSirna  = $query->param('SIRNA');

	# gene_id(32133/Hs#7436/ENSG00000117859) is required for filtering
	if (! $USERGENEID) {
	    my $GeneGroup = getGroup($DATABASE);
	    print $query->p("Please input the $GeneGroup for your target sequence");
	    exit;
	}
	# identitynumber is required if BLASTFILTER is IDENTITY
	if ($blastfilter =~ /IDENTITY/ && ! $IDENTITYNUM ) {
	    print $query->p('Please input your "Number of Matches" for filtering') if (! $IDENTITYNUM);
	    exit;
	}
    }
    
    for (my $i=1; $i<=$BlastSeqLength; $i++) {
	  if ($query->param("POS_$i")) {
		$PosRef->[$i] = "checked";
	    }
	  else {
	      $PosRef->[$i] = "";
	  }
      }
    

    my $GeneObj = GeneObject2->new(
				  acc             => $ACC,
				  gi              => $GI,
				  locuslink       => $LOCUSLINK,
				  unigene_cluster => $UNIGENECLUSTER,
				  ensembl         => $ENSEMBL
				  );

    # build sirna_objects, and parse blast result
    foreach my $c(@chosenSirna) {
	for my $a (0..$#{$SirnaAref}) {
	    if ($SirnaAref->[$a][1] eq $c) {
		# 1   147   AACTCTAGGAACAAATTGGACTT  A,B   40  0  rs#abc  18/20   2003-12-18-51919-28566_211_NCBI_hs.fna.html
		
		$SelectedSirnaHref -> {$a} = "checked";
		
		# html tab blast result
		my $blast_html = $SirnaAref->[$a][8];
		$blast_html    =~ s/\_out/\.html/;
		my $blast_txt  = $SirnaAref->[$a][8];
		$blast_txt     =~ s/\_out/\.txt/; 
		
		my $sirna_obj = SiRNAObject->new(
						 pos                     => $SirnaAref->[$a][1],
						 full_seq                => $SirnaAref->[$a][2],
						 type                    => $SirnaAref->[$a][3],
						 gc_percentage           => $SirnaAref->[$a][4],
						 energy                  => $SirnaAref->[$a][5],
						 snp_id                  => $SirnaAref->[$a][6],
						 max_non_target_identity => $SirnaAref->[$a][7],
						 blastout                => $ParamRef->{"OUTDIR"}->[0] . "/" . $SirnaAref->[$a][8],
						 region                  => $SirnaAref->[$a][9],
						 species                 => $SPECIES,
						 blast                   => $BLAST,
						 database                => $DATABASE,
						 blasttxt                => $ParamRef->{"OUTDIR"}->[0] . "/" . $blast_txt,
						 blasthtml               => $ParamRef->{"OUTDIR"}->[0] . "/" . $blast_html
						 );

		# filter sirnas
		SiRNA::mydebug( "before filter, pos: ", $sirna_obj->pos );
		if ($query->param("BLASTFILTER") eq "IDENTITY")
		{
		    if ($DATABASE =~ /REFSEQ/i) {
			$GeneObj ->addSiRNA($sirna_obj) if (! $sirna_obj->filter_by_identity_refseq($IDENTITYNUM, $USERGENEID) );
		    }
		    elsif ($DATABASE =~ /UNIGENE/i) {
			$GeneObj ->addSiRNA($sirna_obj) if (! $sirna_obj->filter_by_identity_unigene($IDENTITYNUM, $USERGENEID)  );	
		    }
		    elsif ($DATABASE =~ /ENSEMBL/i) {
			$GeneObj ->addSiRNA($sirna_obj) if (! $sirna_obj->filter_by_identity_ensembl($IDENTITYNUM, $USERGENEID)  );
		    }
		}
		elsif ($query->param("BLASTFILTER") eq "POSITION") {
		    if ($DATABASE =~ /REFSEQ/i) {
			$GeneObj ->addSiRNA($sirna_obj) if (! $sirna_obj->filter_by_position_refseq($PosRef, $BlastSeqLength, $USERGENEID)  );
		    }
		    elsif ($DATABASE =~ /UNIGENE/i) {
			  $GeneObj ->addSiRNA($sirna_obj) if (! $sirna_obj->filter_by_position_unigene($PosRef, $BlastSeqLength, $USERGENEID) );
		      }
		    elsif ($DATABASE =~ /ENSEMBL/i) {
			$GeneObj ->addSiRNA($sirna_obj) if (! $sirna_obj->filter_by_position_ensembl($PosRef, $BlastSeqLength, $USERGENEID) );
		      }
		    
		}
		last;
	    }
	}
    }
    
    # write
    foreach my $sirna ( @{ $GeneObj->sirnas} ) {
	$SelectedSirnaHref ->{ $sirna->pos } = "checked";
    }
    
    # sort image
    my @items = qw(energy pos type gc);
    foreach my $i (@items) {
	if ($SORT_NAME =~ /$i/) {
	    $SortImgHref->{$i} = "sorted.gif";
	}
	else {
	    $SortImgHref->{$i} = "unsort.gif";
	}
    }
    
    # write the center html
    centerHtml($GeneObj);
   
    if ($ParamRef->{'MYCENTERHTML'}->[0] =~ /\/(tmp\/.*\/.*)$/) {
      SiRNA::mydebug("redirect to :", $1);
	Check->redirectToLoginPage($1);
    }
    
}
else {
#    print $query->header("text/html");
#    print $query->p("please choose action type");
#    exit;
    
}



sub get_parameters {
    my $file = shift;
    my($sirna_ref, $param_ref);
    open (FL, $file) || SiRNA::myfatal( "Can not open $file" );
    while (<FL>) {
	chomp;
	my @list = split('\t', $_);

	# process the sirna list
	if ($list[0] eq "LIST") {
	    # remove 1st item "LIST"
	    shift @list;
	    push @{$sirna_ref}, [@list];
	}
	else {
	    for my $j(1..$#list) {
		push @{ $param_ref->{$list[0]} }, $list[$j];
		SiRNA::mydebug("push into ${list[0]} with ", $param_ref->{$list[0]});
	    }
	    
	}
    }
    close(FL);
    return ($param_ref, $sirna_ref);
    exit;
}


sub matchParam {

    $MyCenterHtml     = $ParamRef->{'MYCENTERHTML'}->[0];
    $MyDataTabTxt     = $ParamRef->{'DOWNLOAD'}->[0];
    $GENE_ID          = $ParamRef->{"GENE_ID"}->[0];
    $LENGTH           = $ParamRef->{'LENGTH'}->[0];
    $ENDING           = $ParamRef->{"ENDING"}->[0],
    $BlastSeqLength   = $ParamRef->{"BLASTSEQLENGTH"}->[0];
    $ACC              = $ParamRef->{"ACCID"}->[0];
    $GI               = $ParamRef->{"GI"}->[0];
    $SPECIES          = $ParamRef->{"SPECIES"}->[0];
    $BLAST            = $ParamRef->{"BLAST"}->[0];
    $DATABASE         = $ParamRef->{"DATABASE"}->[0];
    $LOCUSLINK        = $ParamRef->{"LOCUSLINK"}->[0];
    $UNIGENECLUSTER   = $ParamRef->{"UNIGENECLUSTER"}->[0];
    $ENSEMBL          = $ParamRef->{"ENSEMBL"}->[0];
    $OrgCenterHtmlUrl = $ParamRef->{"ORGCENTERHTMLURL"}->[0];
    $OrgCenterHtml    = $ParamRef->{"ORGCENTERHTML"}->[0];
    $BlastStart       = $ParamRef->{"BlastStart"}->[0];
    $BlastEnd         = $ParamRef->{"BlastEnd"}->[0];
}


#sub getLocuslink {
#    my $acc = shift;
    
#    my $dbh = Database::connect_db("locuslink");
#    my $locuslink = Database::get_locusid($dbh, $acc);
##    SiRNA::mydebug( "%%%%%%%%%%% acc=", $acc, "locuslink=", $locuslink );
#    Database::disconnect_db($dbh);
   
#    return $locuslink;
#}
