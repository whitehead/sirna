#################################################################
# Copyright(c) 2003 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     09/28/2001
# author:      Bingbing Yuan
#################################################################

# this module is for finding the positions of the 5'-utr, coding region and 3'-utr
# it accepts a genbank id

package RegionAcc;

use Class::Struct;
use LWP::Simple qw(get);

struct RegionAcc => {
    gi      => '$',    # genbank id: digits
    genBank => '$',    # genbank flat file content
    utr_5   => '$',    # 5'utr region: 1-12
    coding  => '$',    # coding region 13-1000
    utr_3   => '$',    # 3'utr region  1001-20
};



##################
# find regions
##################

sub get_regions {
    my RegionAcc $self = shift;
    my $gi = $self->gi;
    
     my $genbank = get
#        "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Text&db=Nucleotide&dopt=GenBank&dispmax=20&uid=$gi";
 	"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=$gi&retmode=text&rettype=gb";   
#    	print "*****$genbank*****\n";
	if (defined $genbank) { 
	 $self -> genBank($genbank); 
	 my @lists = split("\n", $genbank);
	 my $status = 0;  # CDS should be in FEATURE
	 my $length = 0;  # the length of the mRNA sequence
	
	 for my $i (0 ..$#lists) {
	     
	     # input sequence has to be mRNA
	     if ($lists[$i] =~ /^\s*LOCUS.*\s(\d+)\s+bp.* mRNA/) {
#		print $lists[$i], "\n";
		 $length = $1;
	    }
	     
	     elsif ($lists[$i] =~ /^\s*FEATURES\s+/) {
		 $status = 1;
	     }
	    
	     elsif ( ($status == 1) && ($length >0) &&
		     ($lists[$i] =~ /^\s+CDS\s+(\d+)\.\.(\d+)/) ) {
		 my $utr_5_end = $1 -1;
		 my $utr_5_region = "1" . "-" . $utr_5_end;
		 $self->utr_5($utr_5_region);
		 
		 my $coding_region = $1 . "-" . $2;
		 $self->coding($coding_region);
		
		 my $utr_3_start = $2 + 1;
		 my $utr_3_region = $utr_3_start . "-" . $length;
		 $self->utr_3($utr_3_region);
	     }
	}
     }
}

1

			
