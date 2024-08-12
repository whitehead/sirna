# this module is to do the non_blast filters


package SiRNA;

use strict;
use Pattern;
use FindGC;
use Pyrimidine;
use GCseries;
use BaseVariation;
use SelfComplementary;
use siRNA_log;
use GeneObject;
use SiRNAObject;
use Thermodynamics;
use Seed;


our ($SEQUENCE, $GENE_ID, $PATTERN, $TA_RUN_NUM, $G_RUN_NUM, $BASE_VARIATION, $BASE_VARIATION_NUM, $EMAIL, $CUSTOM_PATTERN, $ENDING, $MIN_GC, $MAX_GC, $SORT, $GC_RUN_MAX, $REAL_PATTERN, $LENGTH);
our ($MyNearestNeighborTable, $MyDanglingTable);


sub pre_blast_filter {
  
  my ($candidate, $gene_object, $pos,  $end_pos) = @_;
  
  my $sense     = find_siRNA_sense($candidate, $ENDING);
  my $antisense = find_siRNA_antisense($candidate, $ENDING);
  # remove 'd' to make it to 23mer
  $sense =~ s/d//g;
  $antisense =~ s/d//g;
  # in the sense direction, w/o 2nt overhang
  my $stem = substr($candidate, 2, $LENGTH-4);
  
  # ===================
  # build siRNA object
  # ===================
  my $sirna = SiRNAObject->new(
			       pos          => $pos,
			       candidate    => $candidate,
			       gc_percentage => get_gc_percentage($stem)
			      );
  
  mydebug("Start check pos=$pos  seq=$candidate" );
  # ================================
  # all nucleotides has to be ACTGU
  # ================================
  
  if ($candidate =~ /[^ACTGU]/i) {
    mydebug("DELETE: not ACTGU", $candidate, "pos=$pos" );
    $gene_object->bad_base_count(1+$gene_object->bad_base_count);
    return 0;
  }
  
  # =======================
  # match pattern
  # =======================
  if ($candidate !~ /$REAL_PATTERN/i) {
    mydebug("DELETE: not pattern", $candidate, "pos=$pos" );
    $gene_object->bad_pattern_count(1+$gene_object->bad_pattern_count);
    return 0;
  }
  else {
    # find other known pattern
    mydebug( "$candidate has the pattern=$REAL_PATTERN" );
    $sirna -> pattern( get_patterns($candidate) );
    mydebug( "done signing pattern" );
  }
  
  # ======
  # G RUN
  # ======
  mydebug( "check G_run" );
  if ( ($sense     =~ /.*G{$G_RUN_NUM,}.*/i) ||
       ($sense     =~ /.*C{$G_RUN_NUM,}.*/i) ||
       ($antisense =~ /.*G{$G_RUN_NUM,}.*/i) ||
       ($antisense =~ /.*C{$G_RUN_NUM,}.*/i) ) {  #g series
    mydebug("DELETE: g_run>=", $G_RUN_NUM, $sense, $antisense, "pos=$pos" );
    $gene_object->bad_g_run_count(1+$gene_object->bad_g_run_count);
    return 0;
  }
  
  # =========
  # A/T rich
  # =========
  mydebug( "check A/T rich sense=", $sense, " antisense=", $antisense) ;
  my $_sense = $sense;
  my $_antisense = $antisense;
  $_sense =~ s/U/T/g;
  $_antisense =~ s/U/T/g;
  
  if ( ($_sense     =~ /.*A{$TA_RUN_NUM,}.*/i) ||
       ($_sense     =~ /.*T{$TA_RUN_NUM,}.*/i) ||
       ($_antisense =~ /.*A{$TA_RUN_NUM,}.*/i) ||
       ($_antisense =~ /.*T{$TA_RUN_NUM,}.*/i) ) {
    
    mydebug("DELETE: ta_run>=", $TA_RUN_NUM, $_sense, $_antisense, "pos=$pos" );
    $gene_object->bad_ta_run_count(1+$gene_object->bad_ta_run_count);
    return 0;
  }
  
  # ============================
  # g/c series: consecutive GC
  # ============================
  mydebug( "check G/C series" );
  if ( ( get_gc_series($sense) >= $GC_RUN_MAX ) ||
       ( get_gc_series($antisense) >= $GC_RUN_MAX ) ) {
    
    mydebug("DELETE: gc_series>", $GC_RUN_MAX, $candidate, "pos=$pos" );
    $gene_object->bad_gc_series_count(1+$gene_object->bad_gc_series_count);
    return 0;
  }
  
  # =========================
  # gc%: only the stem region
  # =========================
  mydebug( "check gc%" );
  if (($sirna->gc_percentage < $MIN_GC) || ( $sirna->gc_percentage > $MAX_GC)) {
    
    mydebug("DELETE: gc%=", $sirna->gc_percentage, $candidate, "pos=$pos" );
    $gene_object->bad_gc_percent_count(1+$gene_object->bad_gc_percent_count);
    return 0;
  }
  
  # =========================
  # base variation: antisense
  # =========================
  mydebug( "check base variation" );
  if ($BASE_VARIATION) {
    my $low = 10000;
    my $high = 0;
    
    ($low, $high) = get_base_variation($antisense);
    my $low_limit = 25 - $BASE_VARIATION_NUM;
    my $high_limit = 25 + $BASE_VARIATION_NUM;
    
    if (($low < $low_limit ) || ($high > $high_limit) || ($low == 0) ) { 
      mydebug("DELETE: base_variation=${low_limit}-${high_limit}", $antisense, "pos=$pos" );
      $gene_object->base_variation_count(1+$gene_object->base_variation_count);
      return 0;
    }
  }
  
  # ====
  # snp
  # ====
  mydebug( "check snp" );
  if ( $gene_object->genbank ) {
    mydebug( "has genbank");
    
    
    my ($snp_count, $snp_id) = get_snp_info($gene_object->snp_info, $pos, $end_pos);
    mydebug( "snp_count=$snp_count, snp_id=$snp_id" );
    $sirna->snp_count($snp_count);
    $sirna->snp_id( $snp_id);
  }
  else {
    $sirna->snp_id('NA');
  }
  
  # ==============
  # miRNA targets
  # ==============
  mydebug( "check miRNA target" );
  $sirna->seed( get_mirna_target($antisense) );
  
  # ===================
  # 5'utr/coding/3'utr
  # ===================
  mydebug( "check 5'utr/coding/3'utr" );
  my $region;
  if ($gene_object->code_region) {
    my ($coding_start, $coding_end) = split_region($gene_object->code_region);
    
    # inside cds #
    if ( ($pos >= $coding_start) && 
	 ($end_pos <= $coding_end) ) {
      $region = "coding";
    }
    # upstream of cds
    elsif ($end_pos < $coding_start) {
      $region = "utr5";
    }
    # downstream of cds
    elsif ($pos > $coding_end) {
      $region = "utr3";
    }
    # utr/coding boundary
    else {
      mydebug("DELETE: utr/coding boundary:", $candidate, "pos=$pos" );
      $gene_object->{boundary_count} ++;
      return 0;
    }
  }
  else {
    $region = 'NA';
  }
  $sirna->region($region);
  
  # ============================================
  # thermodynamic energy: based on Zamore's rule
  # ============================================
  mydebug( "check energy" );
  $sirna->energy( energy_cal($candidate, $sense, $antisense) );
  
  mydebug( "good sirna: pos=$pos" );
  return $sirna;
}	    




# ***************************************************************************
#                                 subroutines
# ***************************************************************************


# ==================================
# calculate the thermodynamic energy
# ================================== 
sub energy_cal {
    my ($seq, $sense, $antisense) = @_;
    my @strand_energy = ();
    
    # beware of extra 'd'
    my @seq_array = ($sense, $antisense);
    foreach my $strand(@seq_array) {
	$strand =~ s/T/U/g;      # T->U
	my $strand_no_dT = $strand;
	my $dangling_start = length($strand_no_dT) -7;
	my $base = substr($strand_no_dT,length($strand_no_dT)-3,1);
	$base =~ tr/ACUG/UGAC/;
	
	mydebug( "strand=$strand_no_dT dangling_start=$dangling_start dangling_seq=", substr($strand_no_dT,$dangling_start,7), " base=$base<br>" );
	my $energe_cal = Thermodynamics->new(
					     seq                   => substr($strand_no_dT,$dangling_start,7),
					     base                  => $base,
					     nearest_neighbor_file => $MyNearestNeighborTable,
					     dangling_file         => $MyDanglingTable
					     );
	my $energy = $energe_cal->cal_energy();
	
	push @strand_energy, $energy;
	
    }
    
    my $sense_energy  = sprintf("%.1f", $strand_energy[0]);
    my $as_energe     = sprintf("%.1f", $strand_energy[1]);
    my $as_sense_diff = $as_energe  - $sense_energy;

    # ======================== #
    # format: diff (as, sense)
    # ======================== #
    my $energy_string = sprintf("%2.1f %-1s %-2.1f%-1s %-2.1f %1s", $as_sense_diff, '(', $as_energe, ',', $sense_energy, ')' );
    
    return $energy_string;
   
}

sub get_patterns {
    my $mrna23 = shift;

    # New Pattern object: find patterns
    # A: AAN19TT
    # B: NAN19NN
    #
    my $patterns_guy = Pattern->new(
				    mrna23    => $mrna23,
				    stem_size => $LENGTH -4
				    );

    $patterns_guy -> find_patterns($PATTERN);
    
    return $patterns_guy->patterns;
}


sub get_gc_percentage {
    my $mrna = shift;

    # New FindGC object: get GC%
    #
    my $find_gc = FindGC->new;
    $find_gc -> mrna($mrna);
    $find_gc -> count_gc();
    
    return $find_gc->gc;
}
	
sub get_gc_series {
    my $seq = shift;

    # New GCseries obj
    #
    my $GC_candidate =  GCseries->new;
    $GC_candidate->seq($seq);
    $GC_candidate->find_gc_series();

    return $GC_candidate->gc_series;
}

sub get_base_variation {
    my $mrna = shift;
    
    # New BaseVariation object: get base_variation
    #
    my $base_ratio = BaseVariation->new;
    $base_ratio -> mrna($mrna);
    $base_ratio -> count_base();

    return ($base_ratio->low, $base_ratio->high);
}


sub get_snp_info {

    my ($snp_aref, $start, $end) = @_;
    
    my @snp   = ();
    my $count = 0;
    my $id    = "";
    
    for my $i(0..$#$snp_aref) {
      my ($_snp, $_pos) = @{ $snp_aref->[$i] };
      if ($_pos >= $start && $_pos <= $end) {
	mydebug( "start=$start, end=$end, snp=$_snp, pos=$_pos" ); 
	push @snp, $_snp;
      }
    }
    if ($#snp >=0 ) {
      $count = $#snp +1;
      $id = join(";", @snp);
    }
    return ($count, $id);

}

sub get_mirna_target {

  my $antisense = shift;
  
  mydebug("For seed antisense=$antisense");
  # New Seed obj
  #
  mydebug("miRNA connect to db");
  my $seed_obj = Seed->new(
			   seed => substr($antisense, 1, 7),
			  );
  $seed_obj->get_target();
  mydebug("miRNA disconnect to db");

  return($seed_obj);

}


1;
