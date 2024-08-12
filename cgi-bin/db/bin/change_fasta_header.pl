#! /usr/bin/perl -w


#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     12/10/2002
# Author:      Bingbing Yuan
#
#################################################################

### this script is to add lcl|IDENTIFIER or gnl|DATABASE|IDENTIFIER to the header line of fasta sequences in a database
### so, fastacmd could be used or XML or ASN.1 output can be produces

if (! $ARGV[1] ) {
    usage();
    exit;
}

my $fasta_file = $ARGV[0];
my $database_type = $ARGV[1];
my $database_name;


if (! $ARGV[2]) {
    if ($database_type ne 'lcl') {
	usage();
	exit;
    }
}
if ( $ARGV[2] ) {
    if ($database_type ne 'gnl') {
	usage();
	exit;
    }
    else {
	$database_name = $ARGV[2];
    }
}

open (FH, $fasta_file) || die "can't open $fasta_file\n";
while (<FH>) {

    chomp;

    if ($_ =~ /^\>(.*?)\s+(.*)/)
    {
	my ($id_tmp, $desc);
	$id_tmp = $1;
	$desc = $2;
	$id_tmp =~ s/\|/' 'x 1/e;

	# fastacmd doesn't accept Acc as pure digits
	signal() if ($id_tmp =~/^\d+$/);

	print_header($id_tmp, $desc);
    }
    
    elsif ($_ =~ /^\>(.*)/)
    {
	my ($id_tmp, $desc);
    	$id_tmp = $1;
	$desc = "";
	
	# fastacmd doesn't accept Acc as pure digits
	signal() if ($id_tmp =~/^\d+$/);
	
	print_header($id_tmp, $desc);
    }
    
    else {
	print "$_\n";
    }
}
close (FH);



sub print_header {

    my ($id_tmp, $desc) = @_;
    my $orginal_header;

    # reconstruct original header line
    if ($desc) {
	$orginal_header = "$id_tmp $desc";
    }
    else {
	$orginal_header = $id_tmp;
    }
    
    # print out the new header line
    if ($database_type eq "lcl") {
	print ">$database_type|$orginal_header\n";
    }
    elsif ($database_type eq "gnl") {
	print ">$database_type|$database_name|$orginal_header\n";
    }
}


sub signal {

    print 
	"\n",
	"Warning: fastacmd doesn't like the accession numbers with pure digits.\n",
	"\n";
}

sub usage {
    print "\n",
    "This script is to add lcl|IDENTIFIER or gnl|DATABASE|IDENTIFIER\n",
    "to the header line of fasta sequences in a non_genebank database,\n",
    "so the fastacmd could be used to retrieved sequences\n\n",
    "Usage: file_name lcl > new_file_name   OR   file_name gnl database_symbol > new_file_name\n\n";
}


