# purpose: write files for apache dir



package SiRNA;


use strict;
use siRNA_log;
use GeneObject;
use SiRNAObject;
use Sort;
use Seed;


our ($UserSessionID, $MySessionID, $MyDataOligo);

our ($DATABASE, $BLAST, $SPECIES, $SEQUENCE, $GENE_ID, $PATTERN, $TA_RUN_NUM, $G_RUN_NUM, $BASE_VARIATION, $BASE_VARIATION_NUM, $EMAIL, $CUSTOM_PATTERN, $ENDING, $MIN_GC, $MAX_GC, $SORT, $GC_RUN_MAX, $VIA, $LENGTH);




sub write_oligo_html {
    
    
    my ($gene_object, $query, $ending) = @_;
    
    # =======================
    # setup last checked list
    # =======================

    my %SortHash = ();
    $SortHash{"Position"} = "";
    $SortHash{"Patterns"} = "";    
    $SortHash{"GC"} = "";   
    $SortHash{"Thermodynamic"} = "";
    $SortHash{$SORT} = "selected" if ($SORT);
    
    # sort image
    my %SortImg = ();
    my @items = qw(Position Patterns GC Thermodynamic);
    foreach my $i (@items) {
	if ($SortHash{$i}) {
	    $SortImg{$i} = "keep/sorted.gif";
	}
	else {
	    $SortImg{$i} = "keep/unsort.gif";
	}
    }

    my %DatabaseHash = ();
    $DatabaseHash{"REFSEQ"} = "";
    $DatabaseHash{"UNIGENE"} = "";
    $DatabaseHash{"ENSEMBL"} = "";
    $DatabaseHash{$DATABASE} = "selected" if ($DATABASE);
    
    my %BlastHash = ();
    $BlastHash{"NCBI"} = "";
    $BlastHash{"WU"} = "";
    $BlastHash{$BLAST} = "selected" if ($BLAST);

    my %SpeciesHash = ();
    $SpeciesHash{"HUMAN"} = "";
    $SpeciesHash{"MOUSE"} = "";
    $SpeciesHash{"RAT"} = "";
    $SpeciesHash{$SPECIES} = "selected" if ($SPECIES);

    my %ViaHash = ();
    $ViaHash{"email"} = "";
    $ViaHash{"web"} = "";
    $ViaHash{$VIA} = "checked";

    mydebug( "set chosen parameters" );

    # ==============================
    # save the oligo list in table
    # ==============================
    my $mer_list;

    my $html_button_disabled = "";
    my $sirna_num = GeneObject::numOfSiRNAs($gene_object);
    
    if ($gene_object->sirnas) {
	
	# checked oligo
	my @oligoschecked = $query->param("oligo");
	my %OligoCheckedHash = (); # sirna_object
	foreach my $pos (keys %{$gene_object->sirnas} ) {
	    $OligoCheckedHash{$pos} = "";
	}
	foreach my $pos ( @oligoschecked ) {
	    $OligoCheckedHash{$pos} = "checked";
	}
	
	# html content and tabular file
	open DOLIGO, ">$MyDataOligo" || myfatal( "Cannot write to $MyDataOligo $!" );
	my $j = 0;
	my @sirna_objects = values( %{$gene_object->sirnas} );

	mydebug( "%%%%%%%%%%%% sort", $SORT );
	my $sorted_sirnas = sort_sirna(\@sirna_objects, $SORT);

	mydebug( "start go through each sirna" );
	foreach my $sirna_obj ( @$sorted_sirnas ) {
	    $j++;
	    
	    # snp_link
	    my $snp_ids_full = "";
	    if ( $sirna_obj->snp_id  &&  
		 $sirna_obj->snp_id !~ /NA/ ) {
		( $snp_ids_full = get_snp_link($sirna_obj->snp_id) ) =~ s/\;/rs\;/g;
	    }
	    else {
		$snp_ids_full = $sirna_obj->snp_id;
	    }
	    
	    # miRNA targets
	    my ($seed_gene_count, $seed_gene_id, $seed_ratio, $seed);
	    
	    $seed_gene_count = 0;
	    $seed_gene_count = $sirna_obj->seed->gene_count;
	    $seed_gene_id    = $sirna_obj->seed->gene_id;
	    $seed_ratio      = $sirna_obj->seed->ratio;
	    $seed            = $sirna_obj->seed->seed;
	    
	    #print "%%%%%","seed_gene_count=$seed_gene_count, seed_gene_id=$seed_gene_id", '\n<br>'; 
	    
	    # utr5/coding/utr3
	    my $color_position = "";
	    if ($sirna_obj->region && 
		$sirna_obj->region !~ /NA/) {
		$color_position = color_position($sirna_obj);
	    }
	    else {
		my $end_pos = $sirna_obj->pos + $LENGTH -1;
		$color_position = $sirna_obj->pos . "-" . $end_pos;
	    }

	    # include sense/as siRNAs
	    my $nice_seq_format = get_nice_sirna_format( $sirna_obj->candidate, $ending );


	    my $web_line = 
		" <td><input type='checkbox'" .  $OligoCheckedHash{$sirna_obj->pos} . " name='oligo' value=" . $sirna_obj->pos . "></td>\n" .
		" <td>" . $j . "</td>" .
		" <td align='left'>" . $color_position . "</td>\n" .
		" <td><font face='courier, courier new'>" . $nice_seq_format . "</font></td>\n" .
		" <td>" . $sirna_obj->pattern . "</td>\n" .
		" <td>" . $sirna_obj->gc_percentage . "</td>\n" .
		" <td>" . get_nice_energy_format($sirna_obj->energy) . "</td>\n" . 
		" <td>" . $snp_ids_full . "</td>\n" .
		" <td>" . get_entrez_gene_link($seed_gene_count,$seed_gene_id, $seed_ratio, $seed) .  "</td>\n";
	    
	    
	    if ($j % 2 == 0) {
		$mer_list .= "<tr bgcolor='#CCFFCC' align='center'>" . $web_line . "</tr>\n";
	    }
	    else {
		$mer_list .= "<tr bgcolor='#FFFFFF' align='center'>" . $web_line . "</tr>\n";
	    } 
	    print DOLIGO 
		$sirna_obj->pos, "\t",
		$sirna_obj->candidate, "\t",
		$sirna_obj->pattern, "\t",
		$sirna_obj->gc_percentage, "\t",
		$sirna_obj->energy, "\t",
		$sirna_obj->region, "\t",
		$sirna_obj->snp_id, "\t",
		$seed_gene_count, "\t",
		$seed_gene_id, "\t",
		$seed_ratio, "\t",
		$seed, "\n";
	}
	close DOLIGO;

	# ====================================
	#      write  html on fly
	# ===================================
	
	# 0             1       2       3        4
	# query_pos     mer     type    gc       thermodynamics
	
	
	myinfo ("Writing html to the web browser\n");
	
	print  start_html("siRNA candidates");
	printLogoutBar($UserSessionID);
	print <<EOF;
	<SCRIPT language=JavaScript>

	    var numberOfTotalOligos = $sirna_num;
	
	function sort() {
	    document.oligoForm.action = "";
	    document.oligoForm.submit();
	}
	
	function sortSirna(sortValue) {	    
	    var form = document.oligoForm;
	    form.action = "";
	    form.SORT.value=sortValue;
	    form.submit();
	}

	function validateForm() {
	    return validateNumOligos(getNumberOfOligosChecked());
	}

	function validateNumOligos(numOligos) {
            if (numOligos < 1 ) {
                alert("you must choose at lease one oligo.");
                return false;
            }
            else {
                return true;
            }
	}
	
	function submitForm() {

	    var i = getNumberOfOligosChecked();
//	    alert("calculating checked ones");
	    if (validateNumOligos(i)) {
		var t = Math.round(Math.sqrt(i))*2 + 3;
//		alert("You selected "+i+" out of total "+numberOfTotalOligos+" oligo(s). It may take "+t+" minutes to complete the result, depends on the system load.");
		document.oligoForm.submit();
		return true;
	    }
	    else {
		return false;
	    }
	}
	
	function checkAllOligos() {
	    if (numberOfTotalOligos == 1) {
		document.oligoForm.oligo.checked = true;
	    }
	    else if (numberOfTotalOligos > 1) {
		for (var i = 0; i < document.oligoForm.oligo.length; i++)
		{
		    document.oligoForm.oligo[i].checked = true;
		}
	    }
	}
	
	function unCheckAllOligos() {
	    if (numberOfTotalOligos == 1) {
		document.oligoForm.oligo.checked = false;
	    }
	    else if (numberOfTotalOligos > 1) {
		for (var i = 0; i < document.oligoForm.oligo.length; i++)
		{
		    document.oligoForm.oligo[i].checked = false;
		}
	    }
	}
	
	function getNumberOfOligosChecked() {
	    if (numberOfTotalOligos == 1) {
		if (document.oligoForm.oligo.checked) {
		    return 1;
		}
	    }
	    else if (numberOfTotalOligos > 1) {
		var numChecked = 0;
		for (var i = 0; i < document.oligoForm.oligo.length; i++)
		{
		    if (document.oligoForm.oligo[i].checked) {
			numChecked++;
		    }
		}
		return numChecked;
	    }
	    return 0;
	}

	function updateReceiver () {
	    //alert(document.oligoForm.BLAST.value);
	    if (document.oligoForm.BLAST.value == "WU") {
		//alert("i am wu");
		if (document.oligoForm.VIA[0].checked ) {
		    LastCheckedVIA = 0;
		}
		else {
		    LastCheckedVIA = 1;
		}	
		document.oligoForm.VIA[0].checked = true;
		document.oligoForm.VIA[1].checked = false;
		document.oligoForm.VIA[1].disabled = true;
		
	    }
	    else {
		//alert("i am ncbi");
		document.oligoForm.VIA[1].disabled = false;
		document.oligoForm.VIA[LastCheckedVIA].checked = true;
	    }	
	}	function updateReceiver () {
	    //alert(document.oligoForm.BLAST.value);
	    if (document.oligoForm.BLAST.value == "WU") {
		//alert("i am wu");
		if (document.oligoForm.VIA[0].checked ) {
		    LastCheckedVIA = 0;
		}
		else {
		    LastCheckedVIA = 1;
		}	
		document.oligoForm.VIA[0].checked = true;
		document.oligoForm.VIA[1].checked = false;
		document.oligoForm.VIA[1].disabled = true;
		
	    }
	    else {
		//alert("i am ncbi");
		document.oligoForm.VIA[1].disabled = false;
		document.oligoForm.VIA[LastCheckedVIA].checked = true;
	    }	
	}
	
	
	var LastCheckedVIA = 0;


	    </SCRIPT>
	    <SCRIPT language=JAVASCRIPT src="siRNAhelp.js"></SCRIPT>

	    <script src="https://www.google.com/recaptcha/api.js"></script>
	    
	    
	    <h3 align="center">Choose siRNA Candidate(s) </h3>
	    <ol>
	    <li><b>siRNA candidates after filtering the base_run, gc%, and base_variation:</b>&nbsp(The more oligos you choose, the longer time for you to get results.)<br>
	    &nbsp <font size=2><b>Oligo patterns</b>: &nbsp <b><i>A</b>=AAN19TT; &nbsp <b>B</b>=NAN19NN; &nbsp <b>C</b>=N2[CG]N8[AU]N8[AU]N2; &nbsp <b>F</b>=Custom</i></font>
	    
	    <FORM ACTION=siRNA.cgi METHOD=POST NAME="oligoForm"  ID="oligoForm" ENCTYPE= "multipart/form-data">
	    <input type=hidden name="tasto" value="$UserSessionID"></input>
	    <input type=hidden name="pid" value="$MySessionID"></input>
	    <input type=hidden name="SORT" value="$SORT" />
            <input type=hidden name="ENDING" value="$ending" />
	    <table>
	    <tr><td nowrap>
	    <input type=button name=CheckAll value="check all oligos" $html_button_disabled onclick="checkAllOligos();"></input>  &nbsp;
        <input type=button name=UnCheckAll value="uncheck all oligos" $html_button_disabled onclick="unCheckAllOligos();"></input>  &nbsp; &nbsp;
        <!--<a href='javascript:help("keep/oligo_sort.html")'>Sort the sequences</a> by &nbsp;
        <select name="SORT1" onChange="sort()">
            <option value="Position" $SortHash{"Position"}> Position </option>
            <option value="Patterns" $SortHash{"Patterns"}> Patterns </option>
            <option value="GC" $SortHash{"GC"}> GC percentage </option>
            <option value="Thermodynamic" $SortHash{"Thermodynamic"}>Thermodynamic Values</option>
	    </select>-->
	    </td></tr>
	    </table>\n
	    <p />
	    
	    <!-- table description: -->

	    <table cellpadding=3 cellspacing=2 >
	       <tr bgcolor='#CCCCCC' align='center'> 
	          <th></th>
	          <th></th>
	          <th align='left'><a href='javascript:help("keep/query_position.html")'>Position</a> &nbsp; <a href="javascript:sortSirna('Position')"><img src="$SortImg{'Position'}" alt='sortByPosition' align='middle' /></a></th>
	          <th>Sequence</th>
	          <th><a href='javascript:help("keep/type.html")'>Patterns</a> &nbsp; <a href="javascript:sortSirna('Patterns')"><img src="$SortImg{'Patterns'}" alt="sortByType" align="middle" /></a></th>
	          <th><a href='javascript:help("keep/gc.html")'>GC%</a> &nbsp; <a href="javascript:sortSirna('GC')"><img src="$SortImg{'GC'}" alt="sortByGC" align="middle" /></a></th>
	          <th><a href='javascript:help("keep/thermodynamics.html")'>Thermodynamic Values</a> &nbsp; <a href="javascript:sortSirna('Thermodynamic')"><img src="$SortImg{'Thermodynamic'}" alt="sortByEnergy" align="middle" /></a></th>
	          <th><a href='javascript:help("keep/snp.html")'>SNPs</a></th>
                  <th><a href='javascript:help("keep/miRNA.html")'>miRNA targets</a></th>
	       </tr>

	    $mer_list
	    </table>
	
	    <!-- only NCBI BLAST allowed Jan 2011
	    <p />
	    
	    <LI>Choose the alignment tool:
	    <select name = "BLAST" onchange="updateReceiver()">
	    <option value='WU' $BlastHash{"WU"} > WU BLAST </option>
	    <option value='NCBI' $BlastHash{"NCBI"} > NCBI BLAST </option>
	    </select>
	    <a href='javascript:help("keep/FAQ.html#blast")'><img align="top" src="keep/help.gif" alt="help" /></a>
	    </LI>
	    <p />    
	    -->
	    <input type=hidden name="BLAST" value="NCBI" />
	    
	    <LI>Choose the species:
	    <select name = "SPECIES"> 
	    <option value="HUMAN" $SpeciesHash{"HUMAN"}> human </option>
	    <option value="MOUSE" $SpeciesHash{"MOUSE"}> mouse </option>
	    <option value="RAT"   $SpeciesHash{"RAT"}  > rat </option>
            </select></LI>
	    <p />
	    
	    <LI>Choose the database you would like to BLAST against: &nbsp;
	
	    <select name = "DATABASE"> 
            <option value="REFSEQ" $DatabaseHash{"REFSEQ"}> NCBI RefSeq </option>
            <!-- not allowed Jan 2011 <option value="UNIGENE" $DatabaseHash{"UNIGENE"}> NCBI UniGene </option> -->
            <option value="ENSEMBL" $DatabaseHash{"ENSEMBL"}> Ensembl Transcripts </option>

            </select>
	    <a href='javascript:help("keep/FAQ.html#blast")'><img align="top" src="keep/help.gif" alt="help" /></a>
	    </LI>
	    <p />
	    
	    <li>Receive result 
	    <table>
	    <tr><td></td>
	    <td><input type="radio" name="VIA" value="email" $ViaHash{"email"} />via email: $EMAIL &nbsp; <INPUT TYPE=hidden name="EMAIL" value="$EMAIL"></INPUT></td></tr>
	    <tr><td/><td><input type="radio" name="VIA" value="web" $ViaHash{"web"}/>on web browser.</td></tr>
	    </table>
            <P /> 
	    
	    <!-- <li><input TYPE=button VALUE='search' $html_button_disabled onclick='submitForm();' /> -->

  	    <li><input TYPE=button VALUE='search' $html_button_disabled class="g-recaptcha"
    		data-sitekey="6LcTauYpAAAAAFy1edaHZyHwsHuyIsyp-OTCx1bQ" 
    		data-callback='submitForm' 
    		data-action='submit'  />

	        <input TYPE=button value='reset' onclick='document.oligoForm.reset();updateReceiver();' />
	    </FORM>
	    </ol>
EOF
;
    }
    else {
	print "There is no siRNA met your filter criteria";
	exit;
    }
}

    
# ********************************************************************
#                        subroutines 
# ********************************************************************

sub get_nice_energy_format {

    my $energy = shift;
    
    my @array = split(/\(/, $energy);

    (my $diff = $array[0]) =~ s/\s+//g;
    my $detail = "(" . $array[1];
    
    my $formated_energy = 
	"<table><tr>" . 
	"<td>$diff</td>" . 
	"<td>$detail</td>" . 
	"</tr></table>";

    return $formated_energy;
}



# =====================================================
# Color the position to indicate the utr/coding region
# =====================================================
sub color_position {
    my $sirna_obj = shift;
    my $colored_pos = "";
    
    my $end_pos = $sirna_obj->pos + $LENGTH -1;
    
    # red if coding
    if ( $sirna_obj->region =~ /coding/ ) {
	$colored_pos .= '<font color="red">' .  $sirna_obj->pos . "-" .  $end_pos . '</font>';
    }
    # green if upstream of cds
    elsif ( $sirna_obj->region =~ /utr5/ ) {
	$colored_pos =  '<font color="green">' . $sirna_obj->pos . "-" .  $end_pos . '</font>'; 
    }
    # blue if downstream of cds
    elsif ( $sirna_obj->region =~ /utr3/ ) {
	$colored_pos = '<font color="blue">' . $sirna_obj->pos . "-" .  $end_pos . '</font>';
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
a> <br />';
        }
	
    }

#    $snp_links =~ s/\;\&nbsp$//;
    $snp_links =~ s/\<br \/\>$//;
    return $snp_links;
}
# =============================
#  get mirna seed target link
# =============================
sub get_mirna_target_link {
  my ($count, $gi_list) = @_;
  my $link;

  if ($count) {
    $link = $count;
  }
  else {
    $link = "<a href='http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nuccore&id=" . $gi_list . "'>" .  $count . "</a>";
  }
  return $link;
}


# ==============================
# get gentrez gene link
# ==============================
sub get_entrez_gene_link {
  my ($count, $gene_id, $ratio, $seed) = @_;
  my $link = $count . '[' . $ratio . ']';

  $link = "<a href='seed2gene.cgi?seed=" . $seed . "'>" .  $link . "</a>";

  return $link;

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



1;


