# this module is to find the self complementary for a seq
# input: seq, the number of consecutive matches to be considered to be self_complementary
# return: boulean; y/n

package SelfComplementary;

use Class::Struct;

struct SelfComplementary => {
    seq          => '$',            # sequence
    series_match => '$',            # consecutive nt matches to be considered can form self_complementary
};


sub find_self_complementary {
    my SelfComplementary $self = shift;
    my $series_match = $self->series_match;

    # sense seq
    my $sense = $self->seq;
    # antisense from 3'-5'
    my $target = $sense;

    
    # no need to match the later half of the seq: redundency
    for my $i( 0 ..(length($sense)/2) ) {

	# palindrome pattern
	(my $series_nts = substr($sense,$i,$series_match)) =~ tr/AUGCT/TACGA/;
	my $reverse_series_nts = reverse($series_nts);
	
	# move one base forward in the antisense
	#
	$target = substr($sense, $i+$series_match);

#	print "se=$sense length=", length($sense), "\n";
#	print "target=$target, i=$i, series_nts=$reverse_series_nts,\n";

	if ( length($target) > length($series_match) && ($target =~ /$reverse_series_nts/) ){
#	    print "YES\n";
	    return 1;
	}
    }
    return 0;
}

1
