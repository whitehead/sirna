# this module is for getting fasta sequence from entrez website
# it accept one gi


package GenbankGI;

use Class::Struct;
use LWP::Simple qw(get);


struct GenbankGI => {
		     gi => '$',      # genbank gi id
		    };


sub get_fasta
  {
    my $object = shift;
    my $fasta = "";
    (my $gi = $object->gi) =~ s/\s+//g;
    
    # get fasta seq in text from entrez
    $fasta = get
      "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$gi&rettype=fasta&retmode=text&email=admin\@domain.com";
    return $fasta;
  }


1
  
