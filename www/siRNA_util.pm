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

use LWP::Simple qw(get);
use CGI;
use strict;
use GenbankGI;
use GenbankAcc;


our ($SiRNAUrlHome, $UrlHome, $Home, $Today, $DateDir);
our ($MyDataTxt, $MyDataFasta, $MyDataFastaUrl, $MyDataOligo);
our ($MySiRNAPid, $MyErrorLog, $MyBsubDir);

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

sub initialize {
  myinfo("Initializing Constants...");

  ### used for name of directory and file
  $Today = getDateFromSessionID();
  $DateDir = "${SiRNA::MyClusterHome}/${Tmp}/${Today}";

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
# hashToFile -- save hash to file for siRNA.cgi 
###################################################################

sub hashToFile {
    my $file = shift;
    my $paramref = shift;
    open (PF, ">$file") || die "Can not write to $file\n";

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
	    elsif ( ( defined $paramhash{$key} ) ||
		    ($paramhash{$key} eq "") ) {
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

    open (FL, $file) || die "Can not open $file\n";
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

sub printLogoutBar {
    my $pid = shift;
    print <<EOF;
    <h3 align="right"><a href="logout.cgi?tasto=$pid">logout</a> &nbsp;
    <a href="siRNA_search.cgi?tasto=$pid">start over</a></h3>
EOF
;
}

# ======================
# check web_jobs queues
# ======================

sub check_webjobs_queue {
    
    my $web_jobs = 0;
    
    my $cmd = `$MyBsubDir/jinfo`;
    mydebug( "$cmd" );
    
    if (! $cmd) {
	
    }
    
    else {
	my @all_jobs =  split(/\n/, $cmd);
    
	foreach my $line(@all_jobs) {
	    
	    my @items = split(/\s+/, $line);
	    
#	    mydebug( "items[3]=$items[3], items[4]=$items[4]\n" );

	    # all the run/pend jobs because no queue
	    if ( ($items[3] eq "RUN") ||
		 ($items[3] eq "PEND") ) {
		$web_jobs ++;
	    }
	}
    }
    mydebug( "web_jobs_no=$web_jobs\n" );
    return $web_jobs;
}


# =======================
# check if server is busy
# =======================
#/proc/loadavg
#0.20 0.18 0.12 1/80 11206
#The first three columns measure CPU and IO utilization of the last one, five, and 10 minute periods. The fourth column shows the number of currently running processes and the total number of processes. The last column displays the last process ID used.

sub server_check {
  my $busy = 0;
  my $load = `cat /proc/loadavg`;
  if ($load =~ /^(.*?)\s+/) {
    #    print "1=$1\n";
    if ($1 > 10) {
      $busy =1;
    }
  }
  return $busy;
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

# ==================================== #
#      read a tab-delimited file
#     save fields to an 2d array
# ==================================== #

sub file2arrayOFarray {
    my $file = shift;
    
    my @arryOFarray = ();
    
    open (FL, $file) || myfatal ( "Can not open $file $!" );
    while (<FL>) {
	chomp;
	next if ($_ =~ /^\s*$/);

        my @array = split(/\t/, $_);
	push @arryOFarray, [@array];
	
    }
    close (FL);	
    
    return \@arryOFarray;

}

# sort 2d array by its field index
sub sortbynumber {
    my $arrOfSirnaObj = shift;
    my $columnIndex = shift;
    mydebug( "sorted by $columnIndex");
    my @arr = @$arrOfSirnaObj;
    @arr = sort {
	$a->{$columnIndex} <=> $b->{$columnIndex}
    } @arr; 
    return \@arr;
}

# sub sortbyposition {
#     my $arrofarrref = shift;
#     my $columnIndex = shift;
#     my @arr = @$arrofarrref;
#     @arr = sort {
# 	my @aa = split('-', $a->[$columnIndex]);
# 	my @bb = split('-', $b->[$columnIndex]);
#         $aa[0] <=> $bb[0];
#     } @arr;
#     return \@arr;
# }

sub sortbystring {
    my $arrOfSirnaObj = shift;
    my $columnIndex = shift;
    my @arr = @$arrOfSirnaObj;
    @arr = sort {
	$a->{$columnIndex} cmp $b->{$columnIndex} 
    } @arr;
    return \@arr;
}

sub sortbyenergy {

    mydebug("sorted by energy");
    my $arrOfSirnaObj = shift;
    my $columnIndex = shift;
    my @arr = @$arrOfSirnaObj;
    @arr = sort {
	
	my @aa = split(/\(/, $a->{$columnIndex});
	my @bb = split(/\(/, $b->{$columnIndex});
	$aa[0] =~ s/\s+//g;
	$bb[0] =~ s/\s+//g;
	$aa[0] <=> $bb[0];
    } @arr;
    return \@arr;
}

### save sequence in a file with fasta format ###
### @seqInfo = FileName, Header, Sequence ###
### return the filename ###

sub printFastaToFile {
    my ($file, $header, $bases) = @_;
    my $niceSeq = formatSeq($bases);
    open (FH, ">$file") || myfatal "can't write to $file\n";
    print FH "$header\n";
    print FH $niceSeq;
    close (FH) || warn "can't close $file\n";

}           

### divide seq into 50bases/line in txt###
### return the formated seq ###

sub formatSeq {
    my $seq = shift;
    my $format_seq = "";
    my $seq_50 = "";
    my $i;
    if (length($seq) > 50) {
        for ($i = 0; $i <= length($seq)-50; $i += 50) {
            $seq_50 = substr($seq, $i, 50);
            $format_seq .= "$seq_50\n";
        }
        my $tail_length = length($seq) - $i;
        $format_seq .= substr($seq, $i, $tail_length); # last part
    }
    else {   #total length <=50
        $format_seq = $seq;
    }
    return $format_seq;
}


#####################
# get_fasta_remote
#####################
sub get_fasta_remote {
    my $id = shift;
    my $fasta = "";
    # gi
    if ($id =~ /^\d+/) {
	$fasta = get_fasta_from_gi($id);
    }
    # acc
    else {
	$fasta = get_fasta_from_acc($id);
    }

    return $fasta;
}

####################
# get_fasta_from_gi
####################
sub get_fasta_from_gi {
    my $gi = shift;
    my $object = GenbankGI->new (
				 gi =>$gi
				 );
    return $object->get_fasta();
}

#####################
# get_fasta_from_acc
#####################
sub get_fasta_from_acc {
    my $acc = shift;
    my $object = GenbankAcc->new (
				 acc =>$acc
				 );
    return $object->get_fasta();
}


# =========================================
# split region to get the start and end pos
# argument: 110-132
# return start and end postions
# =========================================

sub split_region {
    my $range = shift;
    if ($range =~ /(.*)\-(.*)/) {
	return($1, $2);
    }
}


# =================
# get gi fro acc
# =================

sub acc2gi {
  
  my $acc = shift;
  my $gi = 0;

  my $utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";

  my $url = "$utils/esearch.fcgi?db=nucleotide&term=$acc";
  
  my $web_data = get($url);
  
  if ($web_data =~ /\<Id\>(\d+)\<\/Id\>/ ) {
    $gi=$1;
  }
  
  return $gi;
  
}



1;
