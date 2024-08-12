#! /usr/bin/perl -w

# this module is searching the known patterns in a seq
# it accepts a seq string
# it reports all the known patterns
# known patterns:
# A: AAN19TT
# B: NAN19NN


package Pattern;

use Class::Struct;


struct Pattern => {
    mrna23    => '$',   # mRNA 20mer
    patterns  => '$',   # all the matched patterns
    stem_size => '$',   # the size of stem region(w/o 2nt overhang on each side)
};


sub find_patterns {
    my Pattern $self = shift;
    my $pattern_type = shift;

    # find the patterns in this 23mer
    my $oligo     = $self -> mrna23;
    my $stem_size = $self -> stem_size;
    my $all_patterns = "";

#    print "oligo=$oligo, stem_size=$stem_size, pattern_type=$pattern_type<br>\n";
    
    # AAN19TT
    if ($oligo =~ /AA[ACTGU]{$stem_size}[TT|UU]{2}/i) {
        $all_patterns .= "A,";
    }

    # NAN19NN
    if ($oligo =~  /[ACTGU]A[ACTGU]{$stem_size}[ACTGU]{2}/i) {
        $all_patterns .= "B,";
    }

    # N2[CG]N8[AU]N8[AU]N2
    if ($oligo =~  /[ACTGU]{2}[CG][ACTGU]{8}[AUT][ACTGU]{8}[AUT][ACTGU]{2}/i) {
        $all_patterns .= "C,";
    }

    # the pattern is "F" if doesn't match to the known pattern
    if ($all_patterns eq "") {
	$all_patterns = "F,";
    }
    # all sequence matched to "F", if custom is selected
    elsif ($pattern_type =~ /CUSTOM/i) {
	$all_patterns .= "F,";
    }

    # remove extra ","
    chop($all_patterns) if ($all_patterns);

    $self->patterns($all_patterns);
}    

1;
