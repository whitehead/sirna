#! /usr/bin/perl -w

# this module is for calculating the GC%
# it accepts a seq string
# and report the gc% of the seq

package FindGC;

use Class::Struct;


struct FindGC => {
    mrna => '$',     # mRNA 20mer
    gc => '$',         # the gc%
};



#####################
# count GC%
#####################
sub count_gc {
    my FindGC $self = shift;
    
    my $seq = $self->mrna;

    # the total length of the seq
    my $total_len = length($seq);

    # calculate the no of the gc
    $seq =~ tr/Ss/Gg/;                   # S = G or C
    my $gc_len = $seq =~ tr/GCgc/GCgc/;

    # get the percentage
    my $pcGC = 100*$gc_len/$total_len + 0.5;
    my $pcGCrounded = int($pcGC);
    
    $self->gc($pcGCrounded);
}

1
