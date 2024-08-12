#! /usr/bin/perl -w

# this module is find the max_length of consecutive GC in a sequence
# it accepts a sequence string
# it reports a number


package GCseries;

use Class::Struct;


struct GCseries => {
    seq => '$',        # sequence string
    gc_series => '$',  # the max number of series GC
};



###############################
# find the max no. of series GC
###############################

sub find_gc_series {
    my GCseries $self = shift;
    my $seq = $self->seq;
    
    # make a array for the seq
    my @bases = split(//, $seq);

    # loop through all the bases
    #
    my $count = 0;
    my $max_count = 0;
    for my $i(0 .. $#bases) {
	if ($bases[$i] =~ /G|C/i) {
	    $count++;
	}
	else {

	    if ($max_count < $count) {
		$max_count = $count;
	    }
	    $count =0;
	}
#	print "==count=$count, max=$max_count\n";
    }
#    print "count=$count, max=$max_count\n";
    # last letter is G/C
    if ($max_count < $count) {
	$max_count = $count;
    }
   $self->gc_series($max_count);
}


1
