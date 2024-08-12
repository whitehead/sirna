#! /usr/bin/perl -w

# this module is for calculating the ct%
# it accepts a seq string
# it reprots the ct% of the seq string


package Pyrimidine;

use Class::Struct;


struct Pyrimidine => {
    mrna => '$',     # mRNA 20mer
    ct => '$',         # ct%
};


sub count_ct {
    my Pyrimidine $self = shift;
    
    my $seq = $self->mrna;

    # total no of bases
    my $total_len = length($seq);

    # calculate the no of uct
    $seq =~ tr/Yy/UU/;                   # Y= T/C;
    my $ct_len = $seq =~ tr/UTCutc/UTCutc/;
    
    # get the ct%
    my $pcCT = int(100*$ct_len/$total_len + 0.5);

    #print "total_length=$total_len ct=$ct_len ratio=$pcCT\n";

    $self->ct($pcCT);

}

1
