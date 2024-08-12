#!/usr/bin/perl -w


# purpose: the script is for adding description line to the Ensembl BLAST databases

use strict;


if (! $ARGV[2] ) {
    print_usage();
    exit;
}

my $BlastFile = $ARGV[0];   # ensembl_human.na/ensembl_mouse.na
my $Species   = $ARGV[1];   # human/mouse
my $Type      = $ARGV[2];   # peptide/transcript
my $EnsemblFile;

if ($Species =~ /human/i) {
    $EnsemblFile = "hsapiens_gene_ensembl__transcript__main.txt.table";
}
elsif ($Species =~ /mouse/i) {
    $EnsemblFile = "mmusculus_gene_ensembl__transcript__main.txt.table";
}
elsif ($Species =~ /rat/i) {
    $EnsemblFile = "rnorvegicus_gene_ensembl__transcript__main.txt.table";
}

# store the geneName and transcriptName in hash
my $EnsHref = matchTranscript2gene($EnsemblFile, $Type);

# insert the description to the header line in BLAST database
open(BLAST, $BlastFile) || die "can not open $BlastFile $! \n";
while(<BLAST>) {
    chomp();
    if (/^\>/) {
	if (/(\>.*\|ensembl\|)(.*?)\s+(.*)$/) {

	    # transcript id not in main file: psuedogene
	    if (! $EnsHref->{$2}) {
		$EnsHref->{$2} = "";
	    }
	    print 
		$1,
		$2,
		" ",
		$EnsHref->{$2},
		" ",
		$3,
		"\n";
	}
	else {
	    print "ERROR: wrong pattern\n";
	    exit;
	}
    }
    else {
	print "$_\n";
    }
}
close(BLAST);







sub matchTranscript2gene {
    my ($file, $type) = @_;
    my %hash = ();

# Ensemble format
# 2       SODIUM/CALCIUM EXCHANGER 1 PRECURSOR (NA(+)/CA(2+)-EXCHANGE PROTEIN 1). [Source:SWISSPROT;Acc:P70414]   ENSMUST00000067792      ENSMUST00000067792.1        2       ENSMUSP00000067975      ENSMUSP00000067975.1    2       ENSMUSG00000054640      ENSMUSG00000054640.1    ensembl     146828  156554  158356  -1      348590  10_random_NT_078639     \N      2       Slc8a1  MarkerSymbol    ENSF00000000421 SODIUM/CALCIUM EXCHANGER PRECURSOR NA + /CA 2+ EXCHANGE     1803    1803    601     1       \N      \N      \N      \N      \N      \N      \N      \N \N       \N      \N      \N      \N      \N      \N      \N      \N      \N      1       1       1       \N      \N      1       1       1  11       1       1       1       1       1       \N      1       1       \N      \N      \N      \N      \N      \N      \N      \N      \N 46       \N      \N      \N      \N      \N      \N      \N      \N

    open(ENS, $file) || die "can not open $file $! \n";
    while(<ENS>) {
	chomp();
	my @arr = split(/\t/);
	my ($desc, $id);
	if ($type =~ /peptide/i) {
	    ($desc, $id) = ($arr[1], $arr[5]);
	}
	elsif ($type =~ /transcript/i) {
	    ($desc, $id) = ($arr[1], $arr[2]);
	}
#	print "desc=$desc, id=$id\n";

	# replace "\N" with "Unknown Function"
	if ($desc eq '\N') {
	    $desc = "";
	}
	$hash{$id} = $desc;
    }
    close(ENS);

    return \%hash;

}


sub print_usage {
    print 
	"\n",
	"addEnsemblDesc.pl blastFile(ensembl_human.na) human/mouse/rat peptide/transcript >file\n",
	"\n";
}
