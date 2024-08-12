#! /usr/bin/perl -w

#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Author:      Bingbing Yuan <siRNA-help@wi.mit.edu>
# Created:     07/20/2001
#
#################################################################

package SiRNA;

umask 000;

use siRNA_env;
use siRNA_log; 

use CGI;
use strict;

our ($SiRNAUrlHome, $UrlHome, $Home, $Today, $DateDir, $DataDirUrl);
our ($MyDataTxt, $MyDataFasta, $MyDataFastaUrl, $MyDataOligo);
our ($MySiRNAPid, $MyErrorLog, $MyBlastDir, $MyBlastDB, $MyBlastDataDir);

my $Tmp = "tmp";
$UrlHome="$SiRNAUrlHome/$Tmp";

###main program has defined $MySessionID as the first thing entered###

sub validateSession {
  if ((! defined $SiRNA::MySessionID)  || ($SiRNA::MySessionID eq "")){
    $SiRNA::MySessionID = "Unknown";
  }
  myinfo("Validating MySessionId.");
  if ($SiRNA::MySessionID eq "Unknown") {
    #Fatal error, session lost
    myfatal("While processing the form: MySessionID is not defined, please contact <a href=\"mailto:admin\@domain.com\">siRNA-help</a> for help.");
    exit(1);
  }
}
sub getBlastDir {
    my $blast = shift;
    if ($blast =~ /NCBI/i) {
	$MyBlastDir = "/usr/local/bin";
    }
    elsif ($blast =~ /WU/i) {
	$MyBlastDir = "/usr/local/bin";
    }
    return $MyBlastDir;
}

sub getBlastDB {
    my ($species, $database) = @_;
    mydebug( "species=$species, database=$database" );
    if ($species =~ /HUMAN/i) {
	if ($database =~ /REFSEQ/i) {
	    $MyBlastDB = $MyBlastDataDir . "/" . "hs.fna";
	}
	elsif ($database =~ /UNIGENE/i) {
	    $MyBlastDB = $MyBlastDataDir . "/" . "Hs.seq.uniq";
	}
	
	elsif ($database =~ /ENSEMBL/i) {
	    $MyBlastDB = $MyBlastDataDir . "/" . "ensembl_human.na";
	}
    }
    elsif ($species =~ /MOUSE/i) {
	if ($database =~ /REFSEQ/i) {
	    $MyBlastDB = $MyBlastDataDir . "/" . "mm.fna";
	}
	elsif ($database =~ /UNIGENE/i) {
	    $MyBlastDB = $MyBlastDataDir . "/" . "Mm.seq.uniq";
	}
	elsif ($database =~ /ENSEMBL/i) {
	    $MyBlastDB = $MyBlastDataDir . "/" . "ensembl_mouse.na";
	}
    }
    elsif ($species =~ /RAT/i) {
	if ($database =~ /REFSEQ/i) {
	    $MyBlastDB = $MyBlastDataDir . "/" . "rn.fna";
	}
	elsif ($database =~ /UNIGENE/i) {
	    $MyBlastDB = $MyBlastDataDir . "/" . "Rn.seq.uniq";
	}
	elsif ($database =~ /ENSEMBL/i) {
	    $MyBlastDB = $MyBlastDataDir . "/" . "ensembl_rat.na";
	}
    }
    return $MyBlastDB;
}

sub initialize {
  myinfo("Initializing Constants...");

  ### used for name of directory and file
  $Today = getDateFromSessionID();
  $DateDir = "${SiRNA::MyClusterHome}/${Tmp}/${Today}";
  $DataDirUrl = "${UrlHome}/${Today}";

  if (! -e $DateDir) {
    mkdir $DateDir;
  }

  #######################################################################
  # Temporary files and result files
  #######################################################################

  $MyDataTxt = "${DateDir}/${SiRNA::MySessionID}.txt";
  $MyDataFasta = "${DateDir}/${SiRNA::MySessionID}.fasta";
  $MyDataFastaUrl = "${UrlHome}/${Today}/${SiRNA::MySessionID}.fasta";
  $MyDataOligo = "${DateDir}/${SiRNA::MySessionID}.oligo";
  $MySiRNAPid = "$Home/$Tmp/siRNA.pid";
  $MyErrorLog = "$Home/$Tmp/siRNA.errorlog";
  
  myinfo("Done initializing Constants.");
}

###################################################################
# hashToFile -- save hash to file for siRNA.pl 
###################################################################

sub hashToFile {
    my $file = shift;
    my $paramref = shift;
    open (PF, ">$file") || myfatal ( "Can not write to $file\n" );

    if (! defined $paramref) {
	#use CGI param
	foreach my $key (param()) {
#	print "save $key<br>";
	    if (ref param($key) eq "ARRAY") {
#	    print "$key is an array<br>";
		my @paramarr = param($key);
		foreach my $val ( @paramarr ) {
#		print "value is $val<br>";
		    print PF "$key\t$val\n";
		}
	    }
	    else {
		print PF "$key\t", param($key), "\n";
	    }
	}
    }
    else {
	my %paramhash = %$paramref;
	foreach my $key (keys %paramhash) {
#	print "save $key<br>";
	    if (ref $paramhash{$key} eq "ARRAY") {
#	    print "$key is an array<br>";
		foreach my $val ( @{$paramhash{$key}} ) {
#		print "value is $val<br>";
		    print PF "$key\t$val\n";
		}
	    }
	    elsif ( defined $paramhash{$key} ) {
		print PF "$key\t$paramhash{$key}\n";
	    }
	}
    }
    close (PF);
}

##################################################################
# load the parameters from a file into hash table
##################################################################

sub fileToHash {
    my $file = shift;
    my %hash = ();

    open (FL, $file) || myfatal ( "Can not open $file\n" );
    while (<FL>) {
        $_ =~ /(\w+)\t(.*)/;
        if (! defined $hash{$1}) {
            $hash{$1} = $2;
#           print "==$1\t$hash{$1}<br>\n";
        }
        else {
            my $val0 = $hash{$1};
            if (ref $val0 ne "ARRAY") {
                my @arr = ( $val0 );
                $hash{$1} = [@arr];
            }
            push @{$hash{$1}}, $2;
#	    print "**$1\t$2\t@{$hash{$1}}<br>\n";
        }
    }
    close (FL) || die "Can not close $file\n";
    return \%hash;
}

#######################################################################
# Get date information from the session id, used as directory to hold
# temporary files and result files.
#######################################################################

sub getDateFromSessionID {
    my @sessionidarray = split('-', $SiRNA::MySessionID);
    if ($#sessionidarray != 4) {
	myerror ("Invalid SessionID: \"$SiRNA::MySessionID\".\n");
    }
    return "${sessionidarray[0]}-${sessionidarray[1]}-${sessionidarray[2]}";
}

sub toArray {
    my $someref = shift; #could be array reference or scalar reference
    my @array = ();
    if (ref $someref eq "ARRAY") {
        @array = @{ $someref };
    }
    else {
        @array = ( $someref );
    }
    return @array;
}

# sort 2d array by its field index
sub sortbynumber {
    mydebug("in nfs sortbynumber");
    my $arrOfSirnaObj = shift;
    my $columnIndex = shift;
    my @arr = @$arrOfSirnaObj;
    
    mydebug("beforeSort: ", @arr);
    if (ref $arr[0] eq "ARRAY") {
	@arr = sort {
	    $a->[$columnIndex] <=> $b->[$columnIndex]
	} @arr; 
    }
    else {
	@arr = sort {
# 	print "<font color='red'>$columnIndex a=",  $a, "</font><br>";
# 	print "<font color='red'>$columnIndex b=",  $b, "</font><br>";
# 	print "<font color='red'>$columnIndex a=",  $a->{$columnIndex}, "</font><br>";
# 	print "<font color='red'>$columnIndex b=",  $b->{$columnIndex}, "</font><br>";
	    $a->{$columnIndex} <=> $b->{$columnIndex}
	} @arr; 
    }
    mydebug("afterSort: ", @arr);
    return \@arr;
}

sub sortbystring {
    my $arrOfSirnaObj = shift;
    my $columnIndex = shift;
    my @arr = @$arrOfSirnaObj;
    if (ref $arr[0] eq "ARRAY") {
	@arr = sort {
	    $a->{$columnIndex} cmp $b->{$columnIndex} 
	} @arr;
    }
    else {
	@arr = sort {
	    $a->{$columnIndex} cmp $b->{$columnIndex} 
	} @arr;
    }
    return \@arr;
}

sub sortbyenergy {

    my $arrOfSirnaObj = shift;
    my $columnIndex = shift;
    my @arr = @$arrOfSirnaObj;
    if (ref $arr[0] eq "ARRAY") {
	@arr = sort {
	    my @aa = split(/\(/, $a->[$columnIndex]);
	    my @bb = split(/\(/, $b->[$columnIndex]);
	    $aa[0] =~ s/\s+//g;
	    $bb[0] =~ s/\s+//g;
	    $aa[0] <=> $bb[0];
	} @arr;
    }
    else {
	@arr = sort {
	    my @aa = split(/\(/, $a->{$columnIndex});
	    my @bb = split(/\(/, $b->{$columnIndex});
	    $aa[0] =~ s/\s+//g;
	    $bb[0] =~ s/\s+//g;
	    $aa[0] <=> $bb[0];
	} @arr;
    }
    return \@arr;
}


sub save_seq_in_fasta_file {
    my ($defline, $seq, $file) = @_;
    open(FILE, ">$file") || SiRNA::myfatal( "can not write to $file $!" );
    print FILE ">$defline\n";
    print FILE "$seq\n";
    close(FILE);
}

# ================================== #
# get sense(3-23 pos) from a 23 mer
#     ended by user's request
#         orientation: 5'-3'
# ================================== #
sub find_siRNA_sense {
    my ($oligo, $ending) = @_;
    my $rna = "";

    if ( ($ending eq "NN") || ($ending eq "dNdN") ) {
	$rna = $oligo;
    }
    else {
	$rna = substr($oligo, 2, 19);
    }

    $rna =~ tr/a-z/A-Z/;
    $rna =~ s/t/U/g;
    $rna =~ s/T/U/g;
    
    if ($ending eq "UU") {
	$rna = $rna . "UU";
    }
    elsif ($ending eq "TT") {
	$rna = $rna . "dTdT";
    }
    elsif ($ending eq "dNdN") {
	$rna = substr($rna, 2, 19) . 'd' . substr($rna, 21, 1) . 'd' . substr($rna, 22, 1);
    }
    else {
	$rna = substr($rna, 2, 21);
    }

    return $rna;
}

# ====================================== #
# get antisense(1-21 pos) from a 23 mer
#        ended by user's request
#           orientation: 5'-3'
# ====================================== #
sub find_siRNA_antisense {
    my ($oligo, $ending) = @_;
    my $rna = "";
    
    if ( ($ending eq "NN") || ($ending eq "dNdN") ) {
	$rna = $oligo;
    }
    else {
	$rna = substr($oligo, 2, 19);
    }
    $rna = reverse($rna);
    $rna =~ tr/ACTGactg/TGACTGAC/;
    $rna =~ s/t/U/g;
    $rna =~ s/T/U/g;
    
    if ($ending eq "UU") {
	$rna = $rna . "UU";
    }
    elsif ($ending eq "TT") {
	$rna = $rna . "dTdT";
    }
    elsif ($ending eq "dNdN") {
	$rna = substr($rna, 2, 19) . 'd' . substr($rna, 21, 1) . 'd' . substr($rna, 22, 1);
    }
    else {
	$rna = substr($rna, 2, 21);
    }
    return $rna;
}


1;
