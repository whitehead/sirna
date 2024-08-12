#! /usr/bin/perl -w 
 
#################################################################
# Copyright(c) 2003 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     4/11/2003
# Updated:     7/29/2004
# author:      Bingbing Yuan
#################################################################

# ====================================================== #
# purpose: write information about the siRNAs results
#          for sort_sirnas.cgi to make the center page
#          write all the blast result files and
#          file used by sort_sirna.cgi
# need:    sort_sirnas.cgi         
# called by siRNA_step2.cgi
# ====================================================== #

 
package SiRNA;

use strict;
use File::Basename;
use siRNA_log;
use siRNA_util;
use CGI;
use GeneObject2;
use siRNA_util_for_step2;

our ($MyDataTxt3, $MyDataAlignUrl, $DateDir, $DataDirUrl, $MySessionIDSub, $ENDING, $MyCenterHtml, $MyDataTabTxt, $cgiHome, $LENGTH);


our ($FILE, $UNIQID, $SORT_NAME, $SELECTED_SIRNA, $BlastFilterHashRef, $PosRef, $IDENTITYNUM, $BlastSeqLength, $BlastStart, $BlastEnd);
our ($SelectedSirnaHref, $ParamRef, $SirnaAref, $GENE_ID, $SortImgHref, $USERGENEID, $OrgCenterHtmlUrl, $OrgCenterHtml);
our ($BLAST, $DATABASE, $SPECIES, $ACC, $GI);


sub centerHtml{
    
    my $geneObj = shift;
    my $selections = "";
    my $siRNA_count = 0;
    #my $suggest_identity = $BlastSeqLength -3;  # based on Tuscle paper

    mydebug( "MYCENTERHTML=", $MyCenterHtml );
    #mydebug( "sirnas are: ", @{ $geneObj->sirnas });
    open(GENE, ">$MyCenterHtml") || myfatal( "SubHtmlWriter: can't write to $MyCenterHtml" );
    open(TXT, ">$MyDataTabTxt") || myfatal( "SubHtmlWriter: can't write to $MyDataTabTxt" );

    my $posImage    = $SortImgHref->{"pos"};
    my $energyImage = $SortImgHref->{"energy"};
    my $gcImage     = $SortImgHref->{"gc"};
    my $typeImage   = $SortImgHref->{"type"};
    my $GeneGroup   = getGroup($DATABASE);      # gene_id/Unigene Cluster/Ensembl Gene

    # GENE parameters, and sirnas infor
    print GENE get_html_header();
    print GENE <<EOF
	<html>
	<head> <title>siRNAs</title>
	<style TYPE="text/css">
            <!--
	    .rowPlain {}
            .rowFocus  {background-color: #CCCCFF}
	    .rowSelect {background-color: #CCFFFF}
      	    .rowAlt1   {background-color: #FFFFFF}
     	    .rowAlt2   {background-color: #CCFFCC}
    	    -->
	 </style>
        <SCRIPT language=JAVASCRIPT src="../../siRNAhelp.js"></SCRIPT>
EOF
;

			write_js_function(*GENE);

			print GENE
			    "</head>\n",
			    "<body>\n<p>";
			
			
			if ( ! $geneObj->numOfSiRNAs) {
			    print GENE "Sorry, there is no siRNA meet your selections.";
			    print TXT "Sorry, there is no siRNA meet your selections.";
			    if ( -e $OrgCenterHtml) {
				print GENE <<EOF
				    <p /><a href="$OrgCenterHtmlUrl">Back to Previous BLAST Results</a>
				    <br>
EOF
;
			    }
			}
			else {
			    
			    
			    # TAB DELIMITED FILE
			    print TXT 
				"No.\tPos\tsiRNA\tPattern\tGC%\tThermodynamics\tSNP\tblast_result\n";
	
			    print GENE <<EOF
				
				<!-- post_sirna.cgi -->
				<form name="mainForm" method="post" action="../../post_sirna.cgi">\n
				<input type=hidden name="UNIQID" value="$MySessionIDSub" />\n
				<input type=hidden name="DATA" value="$MyDataTxt3" />\n
				<input type=hidden name="sort" value="$SORT_NAME" />\n
				<input type=hidden name="action" value="FILTER" />\n
				    
				<!--  ************ filtering  parameters ************  -->
				<center>
				<table width=80%><tr>
EOF
;
			    if ( -e $OrgCenterHtml) {
				print GENE <<EOF
				<td align="left"><a href="$OrgCenterHtmlUrl">Back to Previous BLAST Results</a></td>
EOF
;
			    }

			    print GENE <<EOF
				<td align="right"><input type="button" name="FILTERSIRNA" value="Filter siRNAs" onclick="javascript:filterSirna()" / ></td>
				</tr>
				</table>
				<h3>View BLAST Results and Filter Results to reduce off-target effects</h3>

				<b>To eliminate siRNAs that may produce off-target effects, we provide several filtering methods: <a href='javascript:help("../../keep/FAQ.html#offtarget")'><img align="middle" src="../../keep/help.gif" alt="help" /></a></b>
			<!--	<b>Filter Non-Specific siRNAs by BLAST Result to Reduce Off-target Effects:</b> <a href='javascript:help("../../keep/FAQ.html#offtarget")'><img align="middle" src="../../keep/help.gif" alt="help" /></a><br /> -->
				<p>


				<!--  filter by identity   -->
				<input name="BLASTFILTER" type="radio" value="IDENTITY" $BlastFilterHashRef->{'IDENTITY'} />
				<strong><font color="green">by Number of Matches:</font></strong> <a href='javascript:help("../../keep/FAQ.html#identity")'><img align="middle" src="../../keep/help.gif" alt="help" /></a> &nbsp <a href='javascript:help("../../keep/identity_eg.html")'><img align="middle" src="../../keep/examples.gif" alt="example" /></a> <br>
				Eliminate siRNAs with off-target BLAST hits sharing more than   
				<input name="IDENTITYNUM" type="text" value="$IDENTITYNUM" size="4" maxlength="4" />
				matched bases of the antisense strand
				<p>

				<input name="BLASTFILTER" type="radio" value="POSITION" $BlastFilterHashRef->{'POSITION'} >
				<strong><font color="green">by Positions:</font></strong> <a href='javascript:help("../../keep/FAQ.html#position")'><img align="middle" src="../../keep/help.gif" alt="help" /></a> &nbsp <a href='javascript:help("../../keep/position_eg.html")'><img align="middle" src="../../keep/examples.gif" alt="example" /></a> <br>
				Eliminate siRNAs with off-target BLAST hits aligning with its antisense strand at the specified positions</p>\n
				
				<!--      position table            -->
				
				<table border="1">
				<tr>
EOF
;
			    
			    for (my $q = $BlastStart; $q <= $BlastEnd; $q++) {
				print GENE "<td>$q</td>\n";
			    }
			    print GENE "</tr>\n<tr>\n";
			    for (my $q = 1; $q <= $BlastSeqLength; $q++) {
				print GENE "<td><input name='POS_$q' type='checkbox' value='$q' $PosRef->[$q] >&nbsp;</td>\n";
			    }

			    print GENE <<EOF
				</tr>
				</tr>
				</table><p />
				
				<!--  gene id for input sequence -->
				<p>The $GeneGroup for your specific target: <input name="USERGENEID" type="text" value="$USERGENEID" size="30" maxlength="50" /> <a href='javascript:help("../../keep/FAQ.html#geneID")'>How to get $GeneGroup</a>?
				<p>

EOF
;
			    print GENE <<EOF
				
				
			    <!--  ********** start the main table  *********** -->
			    
			    <table width='780' cellpadding='1' cellspacing='2' align='center'>
			    <tr bgcolor='#CCCCCC' align='center'><th />
			    <th>No.</th>
			    <th><a href='javascript:help("../../keep/query_position.html")'>pos</a> &nbsp; <a href="javascript:sortSirna('pos')"><img src="../../keep/$posImage" alt="sortByPosition" align="middle" /></a></th>
			    <th>siRNA</th>
			    <th><a href='javascript:help("../../keep/type.html")'>type</a> &nbsp; <a href="javascript:sortSirna('type')"><img src="../../keep/$typeImage" alt="sortByType" align="middle" /></a></th>
			    <th><a href='javascript:help("../../keep/gc.html")'>GC%</a> &nbsp; <a href="javascript:sortSirna('gc')"><img src="../../keep/$gcImage" alt="sortByGC" align="middle" /></a></th>
			    <th><a href='javascript:help("../../keep/thermodynamics.html")'>thermodynamics</a> &nbsp; <a href="javascript:sortSirna('energy')"><img src="../../keep/$energyImage" alt="sortByEnergy" align="middle" /></a></th>
			    <th><a href='javascript:help("../../keep/snp.html")'>SNP</a></th>
			    <th nowrap><a href='javascript:help("../../keep/FAQ.html#blast")'>blast</a></th>
			    </tr>
			    
EOF
;
			
			    my $this_style = "rowAlt2";
			    foreach my $sirna ( @{ $geneObj->sirnas } ) {
			        mydebug("writer is writing ",$sirna);	
				# print GENE "<font color=blue>", $sirna, "</font>";
				my $position = $sirna->pos;
				my $type     = $sirna->type;
				my $gc       = $sirna->gc_percentage;
				my $energy   = $sirna->energy;
				my $ratio    = "LINK";
				my $full_seq = $sirna->full_seq;
				
				if ( $SelectedSirnaHref->{$sirna->pos}) {

				    $siRNA_count ++;
				    
				    # =================
				    # utr5/coding/utr3
				    # =================
				    my $color_position = "";
				    if ($sirna->region && 
					$sirna->region !~ /NA/) {
					$color_position = color_position3($sirna->pos, $sirna->region, $LENGTH);
				    }
				    else {
					my $end_pos = $sirna->pos + $LENGTH - 1;
					$color_position = $sirna->pos . "-" . $end_pos;
				    }
				    
				    # include sense/as siRNAs
				    my $nice_seq_format = get_nice_sirna_format( $sirna->full_seq, $ENDING );
				    
				
				    # =========
				    # snp_link
				    # =========
				    my $snp_ids_full = "";
				    if ($sirna-> snp_id  &&  
					$sirna-> snp_id  !~ /NA/ ) {
					( $snp_ids_full = get_snp_link($sirna->snp_id) ) =~ s/\;/rs\;/g;
				    }
				    else {
					$snp_ids_full = $sirna->snp_id;
				    }
				    
				    SiRNA::mydebug("Done with print SNP");
				    
				    # background color
				    if ($this_style eq "rowAlt1") {
					$this_style = "rowAlt2";
				    }
				    elsif ($this_style eq "rowAlt2") {
					$this_style = "rowAlt1";
				    }
				    #print GENE "<font color=red> have ", $sirna->blasthtml, "</font>";
				    my $blast_html = basename($sirna->blasthtml);
				    
				    
				    
				    print GENE <<EOF
					<tr class='${this_style}' align='center'> 
					<td><input type='checkbox'  name="SIRNA" value=$position  $SelectedSirnaHref->{$position} /></td>
					<td>$siRNA_count</td>
					<td>$color_position</td> 
					<td><font face="courier, courier new">$nice_seq_format</font></td>
					<td> $type </td>
					<td> $gc </td>
					<td nowrap> $energy </td>
					<td> $snp_ids_full </td>
					<td><a target='new' href="$blast_html"> $ratio</a></td>
EOF
;
				    $selections .= "$position;";
				    print TXT "$siRNA_count\t$position\t$full_seq\t$type\t$gc\t$energy\t$snp_ids_full\t$ratio\n";
				    
				    print GENE "</tr>\n";
				}
			    }
			    # remove the last ";"
			    chop($selections);
			
			    print GENE "    <input type=hidden name='SELECTIONS' value='$selections' />\n";
			    
			    print GENE "\n</form>\n";
			}
			print GENE "\n</body></html>\n";
			close(GENE); 
			close(TXT);
			
			return 1;
		    }		
			
			
sub get_nice_sirna_format {
    
    my ($seq, $ending) = @_;
    
    my $sense = SiRNA::find_siRNA_sense($seq, $ending);
    my $as = SiRNA::find_siRNA_antisense($seq, $ending);
    SiRNA::mydebug( "sense=$sense, as=$as" );
    $as = reverse($as);
    my $center_length = length($seq) -4;
    my $one_side_length = length($sense) - $center_length;

    my $sense_center = substr($sense, 0, $center_length);
    my $sense_overhang = substr($sense, $center_length);

    # draw a table to align well
    my $screen  = '<table boundary=1>';
    $screen .= 
	"<tr>" . 
	"<td align='right' nowrap>S 5':</td>" . 
	"<td align='right'></td>" . 
	"<td>" . substr($sense, 0, $center_length) .  "</td>" . 
	"<td align='left'>" . substr($sense, $center_length) . "</td>" . 
	"</tr>";

    $screen .=
	"<tr>" . 
	"<td align='right' nowrap>mRNA:</td>" . 
	"<td align='right'>" . substr($seq, 0, 2) . "</td>" . 
	"<td>" . substr($seq, 2, $center_length) . "</td>" .
	"<td align='left'>" . substr($seq, 2+$center_length ) . "</td>" .
	"</tr>";

    $screen .= 
	"<tr>" . 
	"<td align='right' nowrap>AS 3':</td>" . 
	"<td align='right'>" . substr($as, 0, $one_side_length) . "</td>" . 
	"<td>" . substr($as, $one_side_length) . "</td>" . 
	"<td align='left'></td>" .
	"</tr>";	
    
    $screen .= "</table>";

    return $screen;
    
}

# get the group name(entrez_gene id/UniGene Cluster/Ensembl Transcript ID) that database is based (REFSEQ/UNIGENE/ENSEMBL)
sub getGroup {
    my $database = shift;
    my $group = "";
    if ($database =~ /REFSEQ/i ) {
	$group = "entrez_gene ID";
    }
    elsif ($database =~ /UNIGENE/i ) {
	$group = "UniGene Cluster";
    }
    elsif ($database =~ /ENSEMBL/i ) {
	$group = "Ensembl Gene ID";
    }
    return $group;
}

# get zamore sense seq: replace only pos 21 of 23 mer

sub zamore_seq {
    my $seq = shift;
    my $head = substr($seq, 0, 18);
    my $tail = substr($seq,19);
    my $zamore_base = "";
    my $zamore_seq = "";

    # replace C w/ U: GC bond
    if (substr($seq, 18, 1) eq "C") {
	$zamore_base = "U";
    }
    # replace "A" with G: GC bond
    elsif (substr($seq, 18, 1) eq "A") {
	$zamore_base = "G";
    }
    # replace "G" with "A": AC bond
    elsif (substr($seq, 18, 1) eq "G") {
	$zamore_base = "A";
    }
    # replace "A" with "C": AC bond
    elsif ( substr($seq, 18, 1) eq "U") {
	$zamore_base = "C";
    }
    
    $zamore_seq = $head . $zamore_base . $tail;

    return $zamore_seq;
}

sub get_html_header {
    
    my $header = 
	"<!DOCTYPE html
	PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'
	'http://www.w3.org/TR/html4/loose.dtd'>
	<html xmlns='http://www.w3.org/1999/xhtml' lang='en-US'>";

    return $header;
}

sub get_gb_link {

    my $gi = shift;
    my $link = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=retrieve&db=Nucleotide&dopt=GenBank&dispmax=20&uid=${gi}";
    
    return $link;
}


sub get_unigene_link {

    my $id = shift;
    my $link = "";

    # gnl|UG|Hs#S1728506
    if ($id =~ /UG\|(.*)\#S([\d]+)/) {
	$link = "http://www.ncbi.nlm.nih.gov/UniGene/seq.cgi?ORG=$1&SID=$2";
    }
    SiRNA::mydebug( "link=$link" );
    return $link;
}

# # color the position to indicate the utr/coding region
# sub color_position {
#     my ($position, $coding_start, $coding_end, $seq) = @_;
#     my $colored_pos = "";
    
#     my @all_pos = split(';', $position);
    
#     foreach my $pos ( @all_pos ) {
# 	my $end_pos = $pos + length($seq);
    
# 	if ( ($coding_start =~ /^\d+$/) &&
# 	     ($coding_end =~ /^\d+$/) ) {
	    
# 	    # red if inside cds #
# 	    if ( ($pos >= $coding_start) && 
# 		 ($end_pos <= $coding_end) ) {
# 		$colored_pos .= '<font color="red">' . $pos . '</font>';
# 	    }
# 	    # green if upstream of cds
# 	    elsif ($end_pos < $coding_start) {
# 		$colored_pos =  '<font color="green">' . $pos . '</font>'; 
# 	    }
# 	    # blue if downstream of cds
# 	    elsif ($pos > $coding_end) {
# 		$colored_pos = '<font color="blue">' . $pos . '</font>';
# 	    }
	    
# 	    # utr/coding boundary
# 	    else {
# 		$colored_pos = '<font color="black">' . $pos . '</font>';
# 	    }
# 	}
# 	else {
# 	    $colored_pos .= "$pos";
# 	}
#     }
    
#     chop($colored_pos);

#     return $colored_pos;
# }


# Color the position to indicate the utr/coding region
sub color_position_2 {
    my ($position, $coding_start, $coding_end, $seq, $head_start, $head_end) = @_;
    my $colored_pos = "";
    my ($head_low, $head_high);
    
    if (! $head_start || ! $head_start) {
	$colored_pos = '<font color="black">' . $position . '</font>';
	return $colored_pos;
    }

    # get the numeric order
    if ($head_start <= $head_end) {
	$head_low  = $head_start;
	$head_high = $head_end;
    }
    else {
	$head_low  = $head_end;
	$head_high = $head_start;
    }
    
    if ( ($coding_start =~ /^\d+$/) ||
	 ($coding_end   =~ /^\d+$/) ) {
	
	SiRNA::mydebug( "head_start=$head_start, head_end=$head_end, head_low=$head_low, head_high=$head_high, coding_start=$coding_start, coding_end=$coding_end" );
	# red if inside cds #
	if ( ($head_low >= $coding_start) && 
	     ($head_high <= $coding_end) ) {
	    $colored_pos .= '<font color="red">' . $position . '</font>';
	}
	# green if upstream of cds
	elsif ($head_high < $coding_start) {
	    $colored_pos =  '<font color="green">' . $position . '</font>'; 
	}
	# blue if downstream of cds
	elsif ( $head_low > $coding_end) {
	    $colored_pos = '<font color="blue">' . $position . '</font>';
	}
    	# utr/coding boundary
	else {
	    $colored_pos = '<font color="black">' . $position . '</font>';
	}
    }
    else {
	$colored_pos = $position;
    }
    
    return $colored_pos;
}


sub sortbyblast {
    my $arrofarrref = shift;
    my $columnIndex = shift;
    my @arr = @$arrofarrref;
    @arr = sort {
	fraction_top($a->[$columnIndex]) <=> fraction_top($b->[$columnIndex])
    } @arr;
    return \@arr;
}

## TO BE DONE ###
sub sortbyzamore {
    my $arrofarrref = shift;
    my $columnIndex = 2;
    my @arr = @$arrofarrref;
    @arr = sort {
        my $aa = zamore_score($a->[$columnIndex]);
	my $bb = zamore_score($b->[$columnIndex]);
	$bb <=> $aa
	} @arr;
    return \@arr;
}


sub zamore_score {
    my $seq = shift;
    my $score;

    if (substr($seq, 20, 1) eq "C") {
	$score = 20;
    }
    elsif (substr($seq, 20, 1) eq "A") {
	$score = 20;
    }
    else {
	$score = 1;
    }

    return $score;
}


## TO BE DONE ###
sub sortbysnp {
    my $arrofarrref = shift;
    my $columnIndex = shift;
    my @arr = @$arrofarrref;
    @arr = sort {
	my $aa = count_snp($a->[$columnIndex]);
	my $bb = count_snp($b->[$columnIndex]);
	$aa = 0 if (!$aa);
	$bb = 0 if (!$bb);
	$aa = 0.5 if ($aa eq "-");
	$bb = 0.5 if ($bb eq "-");
	$aa <=> $bb
	} @arr;
    return \@arr;
}

sub sortbypos {
    my $arrofarrref = shift;
    my $columnIndex = shift;
    my @arr = @$arrofarrref;
    @arr = sort {
	my @aa = split(';', $a->[$columnIndex]);
	my @bb = split(';', $b->[$columnIndex]);
	@aa = sort {$a <=> $b} @aa;
	@bb = sort {$a <=> $b} @bb;
        $aa[0] <=> $bb[0]
    } @arr;
    return \@arr;
}

sub sortbynumberminus {
    my $arrofarrref = shift;
    my $columnIndex = 7;
    my @arr = @$arrofarrref;
    @arr = sort {
	my $aa = $a->[$columnIndex];
	my $bb = $b->[$columnIndex];
	$aa = 0 if (!$aa);
	$bb = 0 if (!$bb);
	$aa = 0.5 if ($aa eq "-");
	$bb = 0.5 if ($bb eq "-");
	$aa <=> $bb
    } @arr;
    return \@arr;
}


sub fraction_top {
	my $fra = shift;
	if ($fra =~ /(.*)\//) {  
		return $1; 
        } 
}

sub count_snp {
    my $snp_ids = shift;
    
    if ( ($snp_ids) &&
	 ($snp_ids =~ /\d+/) ) {
	my @array = split(/\;/, $snp_ids);
	my $count_id = $#array +1;
	return $count_id;
    }
    else {
	return $snp_ids;
    }

}

# =====================================================
# Color the position to indicate the utr/coding region
# =====================================================
sub color_position3 {
    my ($position, $region, $length) = @_;
    my $colored_pos = "";

    my $end_pos = $position + $length -1;
    
    # red if coding
    if ( $region =~ /coding/ ) {
	$colored_pos .= '<font color="red">' .  $position. "-" .  $end_pos . '</font>';
    }
    # green if upstream of cds
    elsif ( $region =~ /utr5/ ) {
	$colored_pos =  '<font color="green">' . $position . "-" .  $end_pos . '</font>'; 
    }
    # blue if downstream of cds
    elsif ( $region =~ /utr3/ ) {
	$colored_pos = '<font color="blue">' . $position . "-" .  $end_pos . '</font>';
    }
    
    return $colored_pos;
}

# ==========================
# get the snp link from NCBI
# ==========================
sub get_snp_link {
    
    my $snp_ids = shift;
    my $snp_links = "";
    
    if ( ($snp_ids ne "") && ($snp_ids  ne "-")){
        my @array = split(/\;/, $snp_ids);

        foreach my $id(@array) {
            $snp_links .= '<a target="SNP" href="http://www.ncbi.nlm.nih.gov/SNP/snp_ref.cgi?type=rs&rs=' . $id .'">rs#' . $id . '</
a>;';
        }

        chop($snp_links);
    }
    
    return $snp_links;
}



sub SubOutTxt {
    my $gene_object = shift;
    my $acc             = $gene_object->acc;
    my $gi              = $gene_object->gi;
    
    my $query = new CGI;

    open(STORAGE, ">$MyDataTxt3") || SiRNA::myfatal( "SubHtmlWriter: can't write to $MyDataTxt3 $! ." );

    print STORAGE
	"OUTDIR\t$DateDir\n",
	"CGIDIR\t$cgiHome\n",
	"MYCENTERHTML\t$MyCenterHtml\n",
	"ORGCENTERHTMLURL\t$OrgCenterHtmlUrl\n",
	"ORGCENTERHTML\t$OrgCenterHtml\n",
	"DOWNLOAD\t$MyDataTabTxt\n",
	"LENGTH\t$LENGTH\n";
    
    if ( $gene_object->no_sirna_reason) {
	print STORAGE "SIRNA\tn\t", $gene_object->no_sirna_reason, "\n";

    }
    else {

	print STORAGE
	    "ACCID\t$acc\n",
	    "GI\t$gi\n",
	    "ENDING\t$ENDING\n",
	    "GENE_ID\t$GENE_ID\n",
	    "BLAST\t$BLAST\n",
	    "SPECIES\t$SPECIES\n",
	    "DATABASE\t$DATABASE\n",
	    "BLASTSEQLENGTH\t$BlastSeqLength\n",
	    "BlastStart\t$BlastStart\n",
	    "BlastEnd\t$BlastEnd\n";

	print STORAGE "LOCUSLINK\t";
	if ($gene_object->locuslink) {
	    print STORAGE $gene_object->locuslink,"\n";
	}
	else {
	    print STORAGE "\n";
	}
	print STORAGE "UNIGENECLUSTER\t";
	if ($gene_object->unigene_cluster) {
	    print STORAGE $gene_object->unigene_cluster,"\n";
	}
	else {
	    print STORAGE "\n";
	}
	print STORAGE "ENSEMBL\t";
	if ($gene_object->ensembl) {
	    print STORAGE $gene_object->ensembl,"\n";
	}
	else {
	    print STORAGE "\n";
	}


        my $this_gene_siRNA_count = 0;
	
	foreach my $sirna (sort { $a->pos <=> $b->pos } @{$gene_object->sirnas}) {
	    
	    next if ($sirna->failure_reason);
	    
	    $this_gene_siRNA_count ++;
	    
	    my $non_target_ratio = "LINK";
	    
	    # ==================================
	    # write blast tabular html
	    # write_blast_html is in SiRNAObject
	    # ==================================
	    $sirna->write_blast_html_txt($sirna);
	    
	    print STORAGE 
		"LIST\t",
		"$this_gene_siRNA_count\t",
		$sirna->pos, "\t",
		$sirna->full_seq, "\t",
		$sirna->type, "\t",
		$sirna->gc_percentage, "\t",
		$sirna->energy, "\t",
		$sirna->snp_id, "\t",
		$non_target_ratio, "\t",
		basename($sirna->blastout), "\t",
		$sirna->region, "\n";
	    
	}
	
	if (! $this_gene_siRNA_count ) {
	    print STORAGE "SIRNA\tn\tNo siRNAs meets your rule\n";
	}
	else {
	    print STORAGE "SIRNA\ty\n";
	}
    }
    close(STORAGE); 
}




# put array to string: 123:234:843
sub convert_pos_to_string {
    my $sirna = shift;
    my $positions = "";         # positions w/o color
    foreach my $pos (@{ $sirna->pos }) {
	$positions = "$pos;";    
    }
    
    chop($positions);
    return ($positions);
}



1;
