# this module is for getting fasta sequence from entrez website
# it accepts one accession


package GenbankAcc;

use Class::Struct;
use LWP::Simple qw(get);


struct GenbankAcc => {
    acc => '$',      # genbank acc id
};



sub get_fasta {
    my $object = shift;
    my $fasta = "";

    #(my $acc = $object) =~ s/\s+//g;
    (my $acc = $object->acc) =~ s/\s+//g;


    #    get fasta seq in text from entrez

    my $utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
    # change admin\@domain.com to yours
    my $esearch = "$utils/efetch.fcgi?db=nucleotide&id=$acc&rettype=fasta&email=admin\@domain.com";

    
    $fasta = get($esearch);

#    $fasta_html = get($url);

#    my @lines = split(/\n/, $fasta_html);
#    foreach my $line(@lines) {
#	#if ($line  =~ /\<pre\>(\>gi.*)/) {
#	#if ($line  =~ /\<pre\>.*(\>gi.*)/) {

#	if ($line  =~ /<pre><div class=\'recordbody\'>(>gi.*)/) {

#	    $print_status = 1;
#	    $fasta .= $1 . "\n";
#	}
	
#	elsif ($line  =~ /\<\/pre\>/) {
#	    $print_status = 0;
#	}
	
#	elsif ($print_status) {
#	    $fasta .= $line . "\n";
#	}
#    }
#    print "$fasta_html\n";
    return ($fasta);
}

1



