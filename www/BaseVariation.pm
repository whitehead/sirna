#! /usr/bin/perl -w

# this module is for calculating the base variation for a seq
# it accepts a seq string
# it reports the base counts of the seq string


package BaseVariation;

use Class::Struct;


struct BaseVariation => {
    mrna => '$',       # mRNA oligo
    base_var => '$',   # base variation
    low => '$',        # lowest end of the variation
    high => '$',       # highest end of variation
};


#####################
# count_base
#####################
sub count_base {
    my BaseVariation $self = shift;

    my $seq = $self->mrna;

    # the total seq length
    my $total_len = length($seq);

    # base counts
    my $g_len = $seq =~ tr/Gg/Gg/;
    my $c_len = $seq =~ tr/Cc/Cc/;
    my $a_len = $seq =~ tr/Aa/Aa/;
    my $t_len = $seq =~ tr/UuTt/UuTt/;

    # ranking the bases
    my @array_bases = ($g_len, $c_len, $t_len, $a_len);
    my @sorted_array_bases = sort { $a <=> $b } @array_bases;

    # base variation ratio
    my $ratio = "";
    for my $i(0 ..$#sorted_array_bases-1) {
	$ratio .= "$sorted_array_bases[$i]:";
    }
    $ratio .=$sorted_array_bases[-1];
    
    #
    $self->base_var($ratio);

    my $g_ratio = 100*$g_len/$total_len;
    my $c_ratio = 100*$c_len/$total_len;
    my $t_ratio = 100*$t_len/$total_len;
    my $a_ratio = 100*$a_len/$total_len;
    
    # ranking the bases percentage
    my @array = ($g_ratio, $c_ratio, $t_ratio, $a_ratio);
    my @sorted_array = sort { $a <=> $b } @array;

    $low_rounded = int($sorted_array[0]);
    $high_rounded = int($sorted_array[-1]);
    
    #
    $self->low($low_rounded);
    $self->high($high_rounded);
}

1
