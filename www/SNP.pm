# this package is for search SNP for a gene
# it accepts genBank_flat_file_content, start and end positions of its subseq
# it searches the snps in genbank flat file
# it reports the number of snps along with ncbi snp links
# if no snp found snp_id is empty

package SNP;

use Class::Struct;

struct SNP => {
    genbank_flat => '$',           # genBank flate file content
    start        => '$',           # the start position of the seq
    end          => '$',           # the end position of the seq
    count        => '$',           # the number of snps
    id           => '$'            # the snp id(s) in ncbi 
    
};




sub get_snp_remote {
    my SNP $self = shift;
    my $genbank  = $self->genbank_flat;
    my $start    = $self->start;
    my $end      = $self->end;

    my $snp_pos   = 0;
    my $snp       = "";
    my $snp_id    = "";
    my $snp_count = 0;
    
    if (defined $genbank ) {
#	print $genbank, "\n";
        my @lists = split("\n", $genbank);
        for my $i (0 ..$#lists) {
            if (($lists[$i] =~ /^\s+variation\s+(\d+)/)||
                ($lists[$i] =~ /^\s+variation\s+complement\((\d+)\)/)) {
                $snp_pos = $1;
#                print $lists[$i], "\n";
            }
            if (($snp_pos != 0) && 
                ($lists[$i] =~ /^\s+\/db\_xref\=\"dbSNP\:(\d+)\"/)) {

#                print $lists[$i], "\tsnp_pos=", $snp_pos, "\tsnp_id=", $1, "\n";

                if (($snp_pos >= $start) && ($snp_pos <= $end)) {
                    $snp_id .= $1 . ";";
                    $snp_count ++;
                    $snp_pos = 0;
                }
            }
        }
    }
    else {
	$snp_id = "";
    }
	
    # delete the last ';'
    if ($snp_id ne "") {
        chop($snp_id);
    }
    
    $self->count($snp_count);
    $self->id($snp_id);
    
}

1
