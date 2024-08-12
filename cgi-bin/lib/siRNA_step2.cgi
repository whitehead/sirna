#!/usr/local/bin/perl -w -I/disk1/cgi-bin/siRNAext/lib 

# need to be change at production ????
chdir "/disk1/cgi-bin/siRNAext/lib";

#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     09/28/2001
# updated:     03/29/2005
#################################################################

package SiRNA;

### all files nobody created is xrwxrwxrw
umask 000;
use siRNA_env;
use siRNA_log;

myinfo( "=== Entering siRNA_step2.cgi (pid=$$)===\n");

use LWP::Simple qw(get);
use CGI qw(:standard :html13);

use integer;
use strict;

use siRNA_log;
use siRNA_util;
use siRNA_util_for_step2;
use GeneObject2;
use BlastParser;
use SiRNAObject;
use MainHtmlWriter;
use SubHtmlWriter;
use GD;
use Sort;
use File::Basename;
use Database;
use JobStatus;
use File::Copy;

my %sessions = %{ fileToHash($ARGV[0]) };
our $MySessionID = $sessions{"MySessionID"};
our $MySessionIDSub = $sessions{"MySessionIDSub"};
our $UserSessionID = $sessions{"UserSessionID"};

our ($MyDataTxt2, $MyDataOligo, $MyDataBlast, $MyDataHtml, $MyDataHtmlUrl, $MyDataPng, $MyDataPngFullPath, $MyDataTabTxt, $MyDataTabTxtUrl, $MyDataFasta, $MyDataFastaUrl, $MyDataAlign, $MyDataAlignUrl, $MyLastFile, $MyHomePage, $MyUserLink, $MyUserLinkUrl, $cgiHome, $SiRNAUrlHome);
our ($MyBlastDir, $MyBlastDataDir, $MyBlatHuman, $MyBlatMouse, $DateDir, $DataDirUrl, $MyBlastDB, $MyClusterLib);
our ($MyTopHtml, $MyTopHtmlUrl, $MyCenterHtml, $MyCenterHtmlUrl, $MyLeftHtml, $MyLeftHtmlUrl); 
our ($MyFAQHtmlUrl,  $MyGetsiRNABottonUrl, $MyContactUrl, $MyResultNoteUrl, $MyDataTxt3, $MyDataTxt3Url);
our ($LENGTH, $ENDING, $DATABASE, $BLAST, $SPECIES, $EMAIL, $GENE_ID, $ACC, $GI, $LSRUN_DIR);
our ($BlastFilterHashRef, $PosRef, $SelectedSirnaHref, $SortImgHref, $USERGENEID, $OrgCenterHtml, $OrgCenterHtmlUrl);
our $BlastSeqLength = 18;
our $SORT_NAME = "energy";     # default: sort by energy
our ($IDENTITYNUM, $BlastStart, $BlastEnd);


my $ncbiCheckTime = 10;
my $ncbiMaxCheckTime = 60*60*2;
my $wuCheckTime = 120;
my $wuMaxCheckTime = 60*60*5;

$BlastFilterHashRef -> {"IDENTITY"} = "checked";
$BlastFilterHashRef -> {"POSITION"} = "";


$IDENTITYNUM = $BlastSeqLength - 3;  # based on Tuscle paper
$BlastStart = 2;
$BlastEnd  = $BlastSeqLength + $BlastStart -1;

for ( my $i=1; $i<=$BlastSeqLength; $i++  ) {
    $PosRef->[$i] = "POS_$i";
    $PosRef->[$i] = "checked";
}


### initialize constants ###
validateSession();
initialize();

### initialize step2 constants ###
initializeStep2();

$ENV{'LD_LIBRARY_PATH'} .= ":$MyClusterLib";

### user input variables
my %param    = %{ fileToHash($MyDataTxt2) };

my @oligo    = ();
$EMAIL    = "";
$GENE_ID  = "";
$ACC      = "";
$GI       = "";
# picked oligos
@oligo = toArray($param{"oligo"}); 

$EMAIL    = $param{"EMAIL"} if ($param{"EMAIL"});     # email address
$GENE_ID  = $param{"GENE_ID"} if ($param{"GENE_ID"}); # user's seq input as acc/gi
$DATABASE = $param{"DATABASE"};                       # REFSEQ/UNIGENE/ENSEMBL
$BLAST    = $param{"BLAST"};                          # NCBI/WU
$SPECIES  = $param{"SPECIES"};                        # HUMAN/MOUSE/RAT
$LENGTH   = $param{"LENGTH"};                         # 23
$ENDING   = $param{"ENDING"};                         # TT or UU
$ACC      = $param{"ACC"};                            # acc only if user's seq is input as acc/gi 
$GI       = $param{"GI"};                             # gi only if user's seq is input as acc/gi 

mydebug( "email =$EMAIL" );
mydebug( "database=$DATABASE" );
mydebug( "blast=$BLAST" );
mydebug( "species=$SPECIES" );
mydebug( "gene_id=$GENE_ID" );
mydebug( "acc=$ACC" );
mydebug( "gi=$GI" );
mydebug( "siRNA size=$LENGTH" );
mydebug( "ending=$ENDING" );
mydebug( "oligo=", @oligo );

# blast database
$MyBlastDB = getBlastDB($SPECIES, $DATABASE);
mydebug( "MyBlastDB=$MyBlastDB" );

# ncbiblast/wublast
$MyBlastDir = getBlastDir($BLAST);
mydebug( "MyBlastDir=$MyBlastDir" );

# ALL the oligos after primary filter ###
my %hash_blast_candidate = %{ fileToHashOfArray($MyDataOligo, 0) };


### =============================== main ====================================

########## retreivie qualified oligo candidate for blasting(gc, nase_run, base_variation) ########

my %mer_hash = ();             # results after exon_intron, snp process
my $sEmail = "";               # content in user's mail
my $user_link_content = "";    # the content in user's primary web link
my %mer_short_hash = ();       # store blast parsed results for similiar ones
my %no_match_hash = ();        # store blast parsed results for different ones
my %no_match_mer_hash = ();    # store blast parsed results for different ones, after adding previous
my $mer_exist = 1;             # label if there is siRNA candidate exist in whole seq, assume exist at first
my @Buffer = ();
my @count_id = ();              # id in the table
my %hash_figure_id = ();
my $query_align_start;
my $query_align_end;
my $query_length = parse_fasta_file($MyDataFasta);
my $attention_blast ="";
my $MER_LIMIT;
my $HEAD_GENBANK_FLAT = "";
my $GOOD_SINRA_COUNT = 0;

my $GENE_OBJECT = GeneObject2->new(
				  seq_file        => $MyDataFasta,
				  acc             => $ACC,
				  gi              => $GI,
				  no_sirna_reason => "",
				  );
				  

# get LocusID/UnigeneCluster for input acc  
if ($ACC) {
    if ($DATABASE =~ /REFSEQ/i) {
	$GENE_OBJECT->locuslink($GENE_OBJECT->getLocuslink($ACC));
    }
    elsif ($DATABASE =~ /UNIGENE/i) {
	$GENE_OBJECT->unigene_cluster($GENE_OBJECT->get_unigeneCluster($SPECIES, $ACC) );
    }
    elsif ($DATABASE =~ /ENSEMBL/i ) {
	$GENE_OBJECT->ensembl($GENE_OBJECT->getEnsemblGene($SPECIES, $ACC) );
    }
}

# used in filtering step
$USERGENEID = getUserGeneID($GENE_OBJECT, $DATABASE);  # 125464/Hs#123736/ENSG00000117859/""

# check the status of previous process before running BLAST
# ======================================================= #
# check if there is unfinished job for this ID
# each subID can go only after done with previous subID
# ======================================================= #

if ($BLAST =~ /NCBI/i) {
    my $t = 0;
    while ($t < $ncbiMaxCheckTime) {
	if (! job_status()) {
	    sleep $ncbiCheckTime;
	    $t += $ncbiCheckTime;
	}
	else {
	    last;
	}
    }
    myfatal("Could not wait because the previous jobs takes more than $ncbiMaxCheckTime seconds. ID=$MySessionIDSub") if ($t >= $ncbiMaxCheckTime);
}

elsif ($BLAST =~ /WU/i) {
    my $t = 0;
    while ($t < $wuMaxCheckTime) {
	if (! job_status()) {
	    sleep $wuCheckTime;
	    $t += $wuCheckTime;
	}
	else {
	    last;
	}
    }
    myfatal("Could not wait because the previous jobs takes more than $ncbiMaxCheckTime seconds. ID=$MySessionIDSub") if ($t >= $ncbiMaxCheckTime);
    
}


# =========================================== #
#       blasting oligos and parsing
#=========================================== #

myinfo( "Start blasting each oligos\n");

foreach my $candidate (@oligo) {
    
    if ( defined $hash_blast_candidate{$candidate} ) {
	
	my $antisense = find_siRNA_antisense($hash_blast_candidate{$candidate}->[0]->[1], $ENDING);
	mydebug( "antisense=$antisense, candidate=$candidate, ending=$ENDING" );
	$antisense =~ s/d//g;   # remove d
	my $sirna_object = SiRNAObject->new(
					    pos            => $hash_blast_candidate{$candidate}->[0]->[0], 
					    full_seq       => $hash_blast_candidate{$candidate}->[0]->[1],
					    blast_seq      => substr($antisense, 1, $BlastSeqLength),
					    type           => $hash_blast_candidate{$candidate}->[0]->[2],
					    gc_percentage  => $hash_blast_candidate{$candidate}->[0]->[3],
					    energy         => $hash_blast_candidate{$candidate}->[0]->[4],
					    region         => $hash_blast_candidate{$candidate}->[0]->[5],
					    snp_id         => $hash_blast_candidate{$candidate}->[0]->[6],
					    fasta          => ${MyDataBlast} . "_" . $hash_blast_candidate{$candidate}->[0]->[0],
					    blastout       => ${MyDataBlast} . "_" . $hash_blast_candidate{$candidate}->[0]->[0] . "_${BLAST}_" . basename($MyBlastDB) . "_out",
					    blasthtml      => ${MyDataBlast} . "_" . $hash_blast_candidate{$candidate}->[0]->[0] . "_${BLAST}_" . basename($MyBlastDB) . ".html",
					    blasttxt       => ${MyDataBlast} . "_" . $hash_blast_candidate{$candidate}->[0]->[0] . "_${BLAST}_" . basename($MyBlastDB) . ".txt",
					    failure_reason => "",
					    database       => $DATABASE,
					    blast          => $BLAST,
					    species        => $SPECIES,
					    );
	
	# run blast #
	# save oligo in fasta file
	save_seq_in_fasta_file($sirna_object->pos, $sirna_object->blast_seq, $sirna_object->fasta) if (! -e $sirna_object->fasta);

	my $time = `date`; mydebug( "before blast $time" );
	mydebug("#### blastout=", $sirna_object->blastout, "\n");
	run_blast($sirna_object->fasta, $sirna_object->blastout) if (! -e $sirna_object->blastout); 

	# ==============================================================
	# wait for up to 10sec after BLAST,
	# purpose: make sure that the results are move to storage place
	# ==============================================================
# 	$time = `date`; mydebug( "after blast $time" );	
# 	# there is some time diff between the end of lsrun and the seen lsrun result(STRANG)
# 	# a small loop
# 	my $max_waiting_time = 31;
# 	my $i = 0;
# 	while ($i < $max_waiting_time) {
# 	    if ( -e $sirna_object->blastout) {
# 		$time = `date`; mydebug( "seen file $time: $i" );
		
# 		last;
# 	    }
# 	    else {
# 		sleep 1;
# 	    }
# 	    if ($i == $max_waiting_time &&
# 		! -e $sirna_object->blastout) {
# 		myfatal( "there is two much time between the end of lsrun(BLAST) and its file" );
# 	    }
# 	    $i += 1;
# 	}
	
	my $blast_parser = BlastParser->new(
					    blast_out_file      => $sirna_object->blastout,
					    sirna_obj           => $sirna_object,
					    gene_obj            => $GENE_OBJECT,
					    blast_seq_start_pos => $BlastStart
					    );
	$blast_parser->parse_blast();
	
	$GENE_OBJECT->addSiRNA($sirna_object);
	# for the centerHtml
	$SelectedSirnaHref -> {$sirna_object->pos} = "checked";

    }
}

# sort image
my @items = qw(energy pos  type gc);
foreach my $i (@items) {
    if ($SORT_NAME =~ /$i/) {
	$SortImgHref->{$i} = "sorted.gif";
    }
    else {
	$SortImgHref->{$i} = "unsort.gif";
    }
}


# ========================================= #
#            write html
# ========================================= #

$GOOD_SINRA_COUNT = $GENE_OBJECT->numOfSiRNAs();
write_html();

# make a copy for centerHtml
copy($MyCenterHtml, $OrgCenterHtml) || myfatal ( "copy failed: $!" );


myinfo( "Start to write to userLink file\n" );

### print result message to user's link ###
#userLinkInfo($user_link_content);

if ( (defined $EMAIL) && ($EMAIL ne "") ) {
    $sEmail .= "Please click on the following link to see your results.\n" . 
	"$MyUserLinkUrl\n\n\n" .
	"Some email clients may improperly turn the URL into a " .
	"hyperlink.\nFor best results, please manually copy and " .
	"paste the link into your browser.\n\n";
    
    send_mail($sEmail);
    myinfo( "End of sending email\n" );
}

# write end file
write_end_file();

myinfo( "=========== END ===========\n" );


#############################################################
### ==================== subroutines =====================###
#############################################################


sub write_html {
    
    MainOutHtml( $GENE_OBJECT );
    
    SubOutTxt( $GENE_OBJECT );

    # write center and download files
    centerHtml( $GENE_OBJECT );
}

sub write_end_file {
    
    myinfo( "start end file\n" );
    ### write to to the end of file ###
    open(END,">$MyLastFile") || myfatal ( "can't write to $MyLastFile \n" );
    print END "This is the END of the program\n";
    close(END);
    myinfo( "end of end file\n" );
}


# sub find_oligo_chr_position {
#     my($best_unigene, $start, $end) = @_;
#     my $junction;

#     if ($real_database eq "Hs.seq.uniq") {
#         open(FH, $blat_human) || myfatal( "can't open $blat_human \n" ); # $refGene is global
#     }
#     else {
#         open(FH, $blat_mouse) || myfatal( "can't open $blat_mouse \n" ); # $refGene is global
#     }
#     while(<FH>) {
# 	chomp;
# 	my @array = split('\t', $_);
# 	if ($array[9] eq $best_unigene) { #seq_id
# 	    mydebug("best_unigene=", $best_unigene, "\tstart=", $start, "\tend=", $end, "\n");
# 	    ### can't predict if start or end position is beyond the alignment
# 	    if (($start < $array[11]) || ($end >=$array[12])) {
# 		mydebug("can't find pos because alignment_start=", $array[11], "\talignment_end=", $array[12], "\n");
# 		return("-");
# 	    }
# 	    else {
# 		my @exon_size = split(',', $array[18]);
# 		my @exon_start = split(',', $array[19]);
# 		my @chr_start = split(',', $array[20]);

#   		if ($array[8] eq "-") {
#   		    my @exon_start_tmp = @exon_start ;
#   		    for my $i (0 .. $#exon_start_tmp) {
#   			$exon_start[$i] = abs($array[10] - $exon_start_tmp[$i]);
#   		    }
#  		    my @exon_size_tmp = @exon_size ;
#   		    for my $i (0 .. $#exon_size_tmp) {
#   			$exon_size[$i] = $exon_size_tmp[$i];
#   		    }
#  		}
		
# 		for my $i (0 ..$#exon_start) {
# 		    #### within one_exon ###
# 		    my $oligo_start;
# 		    my $oligo_end;
# 		    if ((($array[8] eq "+") && ($start >= $exon_start[$i]) && ($end < $exon_start[$i]+$exon_size[$i])) ||
# 			(($array[8] eq "-") && ($end <= $exon_start[$i]) && ($start > $exon_start[$i]-$exon_size[$i])))
# 		    {
# 			my $junction;
# 			if ($array[8] eq "+") {
# 			    $oligo_start = $chr_start[$i] + ($start - $exon_start[$i]);
# 			    $oligo_end   = $chr_start[$i] + ($end - $exon_start[$i]);
# 			    if ($end >= $exon_start[$i]+$exon_size[$i]-25) { # too close to junction, bad
# 				$junction = 1;
# 			    }
# 			    else {
# 				$junction = 0;   ### good one
# 			    }
# 			}
# 			else #$array[8] eq "-" 
# 			{ 
# 			    $oligo_start = $chr_start[$i] - ($end - $exon_start[$i]);
# 			    $oligo_end   = $chr_start[$i] - ($start - $exon_start[$i]);
# 			    if ($start <= $exon_start[$i]-$exon_size[$i]+25) { # too close to junction, bad
# 				$junction = 1;
# 			    }
# 			    else {
# 				$junction = 0;   ### good one
# 			    }
# 			}
# 			close(FH);
# 			return ($junction);  #not at exon_intron junction
# 		    }
# 		    ### start, end are in different exons ###
# 		    elsif ((($array[8] eq "+") && ($start < $exon_start[$i]) && ($end >= $exon_start[$i])) ||
# 			   (($array[8] eq "-") && ($end > $exon_start[$i]) && ($start <= $exon_start[$i])))
# 		    {  
# 			return 1;
# 		    }
# 		}    
# 	    }
# 	}
#     }
#     close(FH);
#     return ("-");
# }

sub send_mail {
    my $sEmail = shift;
    open MAIL, "| /usr/lib/sendmail -t -i" or myfatal( "cannot open sendmail\n" );

print MAIL <<EOF;
From: admin\@domain.com
To: $EMAIL
Reply-To: admin\@domain.com
Subject: siRNA Results
$sEmail
EOF


    close MAIL or mywarn( "cannot close sendmail\n" );
}


sub getHelpHref {
    my ($url, $desc) = (@_);
#    return "<a href=\"javascript:help(\'../../keep/${url}\')\">${desc}</a>";
    return "<a href=\"javascript:help(\'../../keep/${url}/\')\">${desc}</a>";
}


sub find_best_value_from_hash {
    mydebug( "in sub find_best_value_from_hash: \n" );
    my $input_hash_ref = shift;
    my %input_hash = %$input_hash_ref;
    my $best_value = 0;
    my $best_key = "";
    foreach my $key (keys %input_hash) {
	mydebug( "key=", $key, "\tvalue=", $input_hash{$key}, "\n" );
	if ($best_value <  $input_hash{$key}) {
	    $best_value = $input_hash{$key};
	    $best_key = $key;
	    mydebug( "in loop: temp best_key=", $best_key, "\n" );
	}
    }
    mydebug( "end of sub find_best_value_from_hash.\n" );
    return $best_key;
}

sub print_array {
    my $array = shift;
    foreach my $i (0 .. $#{$array}) {
	print "$$array[$i]\n";
    }
}


sub addToBlastCandidateSingle {
    my ($val, $index, $mer) = @_;
    if (! @{ $hash_blast_candidate{$mer} }) {
	my @blank = ();
	$hash_blast_candidate{$mer} = [ @blank ];
    }
    my @arr = @{ $hash_blast_candidate{$mer} };
    if (!  $arr[$index]) {
	$arr[$index] = $val;
    }
}

sub addToBlastCandidate {
    my ($val, $index, $mer) = @_;
    if (!  @{ $hash_blast_candidate{$mer} }) {
	my @blank = ();
	$hash_blast_candidate{$mer} = [ @blank ];
    }
    my @arr = @{ $hash_blast_candidate{$mer} };
    if (! $arr[$index]) {
	my %blank = ();
	$arr[$index] = \%blank;
    }
    my %hash = %{ $arr[$index] };
    $hash{$val} = $val;
}

sub collapseHash {
    my $hashref = shift;
    my %hash = %$hashref;
    my $ret_val = "";
    foreach my $key (sort keys %hash) {
	$ret_val .= $key . ";" ;
    }
    chop($ret_val);
    return $ret_val;
}

####################
# sort simple array
####################
# 0               1             2       3      4        5        6            7         8        
#hits_per_mer  query_type_pos  mer     type    gc    hit_id    hit_name     hit_gb   gap_mismatch   
#----------------------------------------------------------------------------------------------
#  9               10               11           12         13         14       15
# alignment     exon_intron    snp_link     snp_count   hit_start   hit_end   sbj_strand
#----------------------------------------------------------------------------------------------

sub array_sort {
    my $not_sorted_array_ref = shift;
    my @not_sorted_array = @$not_sorted_array_ref;
    
    my @sort_array = sort { 

        my @a_fields = @{$a} ;
        my @b_fields = @{$b} ;
 
	my $a_gc = abs($a_fields[4] - 50);
	my $b_gc = abs($b_fields[4] - 50);
	mydebug( "a_fields=", @a_fields, "\ngc%=", $a_fields[4], "\n" );
	
	$a_fields[8] <=> $b_fields[8]         # sort #gap and mismatches in asc order, then
	    ||
	$a_fields[12] <=> $a_fields[12]       # sort by snp , then
	    ||
	$a_gc <=> $b_gc                       # sort by close to 50% gc, then
	    ||
	$a_fields[10] <=> $a_fields[10]       # sort by exon_intron junction , then

    } @not_sorted_array;
    
    return \@sort_array;
}
    
# sub parseBlast {
#     my ($blast_result_file, $limit) = @_;
#     my @mer_array = ();
#     open (FileH, "<$blast_result_file") ||myfatal( "Can't open $blast_result_file\n" );
#     my $report = new Bio::Tools::BPlite(-fh=>\*FileH);
#     my $hsp_count = 0;
#     my $noMatch = 0;
#     my @no_match_mer_array = ();
#     while(my $sbjct = $report->nextSbjct) {
#         while (my $hsp = $sbjct->nextHSP) {
# 	    my $match = $hsp->match;
# 	    my $sbj_name = $sbjct->name;
# 	    $hsp_count++;
# 	    if ( ($hsp_count == 1) && ($match < $limit) ) {
# 		$noMatch = 1;
# 	    }
# 	    if ($noMatch) {
# 		my $no_match_array = get_array($hsp, $sbj_name);
# 		push @no_match_mer_array, [ @$no_match_array ];
# 	    }
#             elsif ($match >= $limit ) {
# 		my $array = get_array($hsp, $sbj_name);
# 		push @mer_array, [ @$array ];
# 	    }
#         }
#     }
#     close(FileH) ||mywarn( "error: cannot close $blast_result_file\n" );
#     return (\@mer_array, \@no_match_mer_array);
# }
		
# sub get_array {
#     my ($hsp, $sbj_name) = @_;
#     my $alignment = "";
#     my $sbj_start;
#     my $sbj_end;
#     my @array = ();
#     my $match = $hsp->match;
    
#     my $hsp_sbj_strand = $hsp->hit->strand;
    
#     my $hsp_homologySeq = $hsp->homologySeq;
#     $alignment = 
# 	sprintf(" %-6d%-20s%6d \n", 
# 		$hsp->query->start,
# 		$hsp->querySeq,
# 		$hsp->query->end);
    
#     $alignment .= 
# 	sprintf("%7s$hsp_homologySeq\n", ' ');
    
#     if ( ($hsp_sbj_strand == 1) || ($hsp_sbj_strand == 0) ){
# 	$alignment .= 
# 	    sprintf(" %-6d%-20s%6d \n",
# 		    $sbj_start = $hsp->hit->start,
# 		    $hsp->sbjctSeq,
# 		    $sbj_end = $hsp->hit->end);
#     }
#     else {
# 	$alignment .= 
# 	    sprintf(" %-6d%-20s%6d \n",
# 		    $sbj_start = $hsp->hit->end,
# 		    $hsp->sbjctSeq,
# 		    $sbj_end = $hsp->hit->start);
#     }		    
    
#     my $gap_mm = 20 - $match;
#     my ($hit_name, $ug_link, $gb, $gb_link, $hit_id) = find_unigene_name($sbj_name);
		
#     @array = ($hit_id,$hit_name,$gb,$gap_mm,$alignment,$sbj_start,$sbj_end,$hsp_sbj_strand,);

#     ### hash unigene_seq_id to unigene_seq_link ###
#     if (! defined $hash_unigene_seq_link{$hit_id}) {
# 	$hash_unigene_seq_link{$hit_id} = $ug_link;
#     }
#     ### hash unigene_seq_id to genbank_link ###
#     if (! defined $hash_genbank_link{$hit_id}) {
# 	$hash_genbank_link{$hit_id} = $gb_link;
#     }

#     return \@array;
# }    


####################
# run blast search
####################
sub run_blast {
    my ($input, $blastout) = @_;
    my $command = "";
    mydebug ("############### BLAST=$BLAST");
    if ($BLAST =~ /NCBI/i) {
#	$command = "$MyBlastDir/blastall -p blastn -F F -W 7 -e 50 -q -1 -i $input -d $MyBlastDB -o $blastout -I T";
#	$command = "$MyBlastDir/blastall -p blastn -F F -W 7 -e 50 -i $input -d $MyBlastDB -o $blastout -I T";
#	blast executable changes with new blasta db
	$command = "$MyBlastDir/blastn -task blastn-short -dust no -soft_masking false -show_gis  -parse_deflines  -evalue 50 -query $input -db $MyBlastDB -out $blastout";
    }
    elsif ($BLAST =~ /WU/i) {
	$command = "$MyBlastDir/blastn $MyBlastDB $input -E=100000 -W=1 -V=10000 -B=10000 -sort_by_highscore -o $blastout -gi";
    }
    mydebug($command);
    
    `$command`; # || myfatal( "can not run $command $! " );
}


sub get_best_hit_info_2 {
    open (FileH, $MyDataAlign) ||myfatal( "error: cannot open $MyDataAlign\n" );
    my $report = new Bio::Tools::BPlite(-fh=>\*FileH);
    while(my $sbjct = $report->nextSbjct) {
	my $sbj_name = $sbjct->name;
        while (my $hsp = $sbjct->nextHSP) {
	    $query_align_start = $hsp->query->start;
	    $query_align_end = $hsp->query->end;
	    last;
	}
	return $sbj_name;
    }
    close($MyDataAlign);
}

sub fileToHashOfArray{
    my ($filename, $key) = @_;
    my %Hash = ();
    open (HH, $filename) || myfatal( "can't open $filename\n" );
    mydebug( "===== all oligos====\n" );
    while (<HH>) {
	if ($_ !~ /^$/) {  #no empty spaces
	    chomp($_);
	    my @Arr = split (/\t/, $_);
	    if (! defined $Hash{$Arr[$key]}) {
		$Hash{$Arr[$key]} = ();
	    }
	    push @{ $Hash{$Arr[$key]} }, [ @Arr ];
	    mydebug( "oligo=", @Arr, "\n" );
	    mydebug( "oligo_seq=$Arr[$key]\n" );
	}
    }
    close (HH) || mywarn( "can't close $filename\n" );
    return  \%Hash; 
}

sub parse_fasta_file {
    my $InFile = shift;
    local $/ = "\n>";
    my $num = 0;
    my $Seq;
    open (HH, $InFile) || myfatal( "Can't open $InFile\n" );
    while (<HH>) {
	chop;
	$num ++;
	if ($num ne 1) {
	    $Seq = ">" . $_;
#       print $Seq;
#       exit;
	}
	else {
	    $Seq = $_;
#       print "AA=$Seq";
	}
	return CountBP($Seq);
    }
    close (HH) || mywarn( "Can't close $InFile\n" );
}

sub CountBP {
    my $In =shift @_;
    my @Arr = split(/\n/, $In);
    my $Count =0;
    for (my $i = 0; $i <=$#Arr; $i++) {
        chomp;
        if ($Arr[$i] !~ /^\>/) {
            $Count += length($Arr[$i]);
        }
    }      
    return $Count;
}


sub print_array_tab_delimited {
    my $array = shift;
    foreach my $i (0 .. $#{$array}) {
	print "$$array[$i]\t";
    }
    chop;
    print "\n";
}


# get the 12365/Hs#748334/ENSG00000117859
sub getUserGeneID {
    my ($geneObj, $database) = @_;
    my $id = "";
    
    if ($database =~ /REFSEQ/i ) {
	$id = $geneObj->locuslink if ($geneObj->locuslink);
    }
    elsif ($database =~ /UNIGENE/i ) {
	$id = $geneObj->unigene_cluster if ($geneObj->unigene_cluster);;
    }
    elsif ($database =~ /ENSEMBL/i ) {
	$id = $geneObj->ensembl if ($geneObj->ensembl);
    }
    return $id;
}

