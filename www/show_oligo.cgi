#!/usr/local/bin/perl

# ###!/usr/local/bin/perl -w -I/usr/lib/perl5/site_perl/5.26.1/

#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Author:      Bingbing Yuan <siRNA-help@wi.mit.edu>
# Created:     09/28/2001
# Updated:     6/28/2004 
#
#################################################################

package SiRNA;

my $DEBUG = 0;
### all files nobody created is xrwxrwxrw
umask 000;

use strict;
use CGI;
use Email::Valid;
use IO::Handle;
use CGI qw(:standard :html13);
use CGI qw(param);
use Time::Local;
use LWP::Simple qw(get);

use siRNA_env;
use siRNA_log;
use GetSession;
use siRNA_util;
use GenbankGI;
use GenbankAcc;
use Thermodynamics;
use PrimaryWriter;
use Check;
use GCseries;
use GeneObject;
use RegionAcc;
use SiRNAObject;
use PreBlastFilter;
use Seed;
use Database;

use CGI::Carp qw(fatalsToBrowser set_message);
    BEGIN {
        sub handle_errors {
    	my $msg = shift;
    	print "<h1>Oh gosh</h1>";
    	print "Got an error: $msg";
        }
       set_message(\&handle_errors);
}


our ($UserSessionID, $MyDataOligo, $MyDataTxt, $MyDataFasta, $MySessionID, $MyCheckMySQL);
our ($MyNearestNeighborTable, $MyDanglingTable);
our $LENGTH = 23;


our ($DATABASE, $BLAST, $SPECIES, $SEQUENCE, $GENE_ID, $PATTERN, $TA_RUN_NUM, $G_RUN_NUM, $BASE_VARIATION, $BASE_VARIATION_NUM, $EMAIL, $CUSTOM_PATTERN, $ENDING, $MIN_GC, $MAX_GC, $SORT, $GC_RUN_MAX, $VIA, $REAL_PATTERN);

my $QUERY = new CGI;
print $QUERY->header("text/html");
my $GENE_OBJECT;

# ===================================
# talk to database to
# validate PID
# get Email from database if needed
# set $EMAIL
# ==================================
validate_db_info();

# =================================================================
# validate mysession and initialize constants at only the 1st time
# =================================================================
my $PID = $QUERY->param("pid");

if (! $PID ) {
    $MySessionID = createSessionID();
}
else {
   $MySessionID = getSessionIDFromCGI($QUERY);
}

validateSession();
initialize();

myinfo("Entering show_oligo.cgi.\n");


$SORT = $QUERY->param("SORT");
if (! $SORT) {
    
    $SORT = "Thermodynamic";    # default for sort oligo: sirna by energy

    # ===============================================
    #                 parameters
    # ===============================================

    $SEQUENCE           = $QUERY->param("SEQUENCE");   # input sequence in fasta format
    $GENE_ID            = $QUERY->param("GENE_ID");    # input sequence id
    $PATTERN            = $QUERY->param("PATTERN");
    $TA_RUN_NUM         = $QUERY->param("TA_RUN_NUM");
    $G_RUN_NUM          = $QUERY->param("G_RUN_NUM");
    $BASE_VARIATION     = $QUERY->param("BASE_VARIATION");
    $BASE_VARIATION_NUM = $QUERY->param("BASE_VARIATION_NUM");
    $EMAIL              = $QUERY->param("EMAIL");        # email address
    $CUSTOM_PATTERN     = $QUERY->param("CUSTOM_PATTERN");
    $ENDING             = $QUERY->param("ENDING");       # TT or UU
    $MIN_GC             = $QUERY->param("GC_MIN");       # lowerest gc%
    $MAX_GC             = $QUERY->param("GC_MAX");       # highest gc%
    $GC_RUN_MAX         = $QUERY->param("GC_RUN_MAX"); 
    $DATABASE = "REFSEQ";
    $SPECIES  = "HUMAN";
    $BLAST    = "NCBI";
    
    # *************************************************************
    #                     ====  VALIDATION ====
    # *************************************************************
    my $error = 0;
    my $htmlError = "";
    my $seq = "";
    my $type = "";
    my $header = "";
    
    # --------------------------------------------
    # validating PATTERN, email, GC% and sequence
    # --------------------------------------------
    ($error, $htmlError, $seq, $header, $type, $REAL_PATTERN) =  validation();
    myinfo( "Form validated.REAL_PATTERN=$REAL_PATTERN" );

    # ==========================
    # web display error message
    # ==========================
    if ($error) {
	myfatal($htmlError, $QUERY);
    }
    
    # build GeneObject
    $GENE_OBJECT = GeneObject->new(
				   seq                       => $seq,
				   gi                        => 0, 
				   acc                       => "",,
				   genbank                   => "",
				   code_region               => "",
				   total_mers                => 0,
				   bad_base_count            => 0,
				   bad_pattern_count         => 0,
				   bad_g_run_count           => 0,
				   bad_ta_run_count          => 0,
				   bad_gc_percent_count      => 0,
				   bad_gc_series_count       => 0,
				   base_variation_count      => 0,
				   boundary_count            => 0,
				   snp_info                  => "",
				   );

    # get more information(coding, snp) if GENE_ID as input seq format
    if ($GENE_ID) {
	
	# get gi and ACC(with version)
	my ($gi, $acc) = get_id_from_header($header);
	
	# =========================================
	# get the URT/CODING region for the refseq
	# =========================================
	
	# with RegionAcc.pm
	my $pos_obj = get_seq_regions($gi);
	if ($pos_obj->coding) {
	    # 201-223
	    $GENE_OBJECT->code_region($pos_obj->coding);
	}
	$GENE_OBJECT->genbank($pos_obj->genBank);
	$GENE_OBJECT->gi($gi);
	$GENE_OBJECT->acc($acc);
	
	# snp info
	my $snp_aref = get_all_snp($acc);
	  
	$GENE_OBJECT->snp_info($snp_aref);

	mydebug($GENE_OBJECT->snp_info);
	
    }
    
    # ======================================
    # loop for each oligos within the gene
    # ======================================
    myinfo("== starting looping each oligo in $header" );
    
    my $real_length = length($seq) - $LENGTH;
    
    for my $j (0 .. $real_length) {
	
	my $candidate = substr($seq, $j, $LENGTH);
	$GENE_OBJECT->total_mers(1+$GENE_OBJECT->total_mers);
	
	my $pos = $j + 1;
	my $end_pos = $pos + length($candidate);
	
	# convert RNA to DNA
	$candidate =~ s/Uu/Tt/;

	# =====================================================================
	# filter sirna with all filters: 
	# base_run, gc%, snp. utr/coding, energy 
	# only GENE_ID as input seq format has snp info
	# only GENE_ID as input seq format & has coding_range has utr/coding
	# build siRNA object in this subroutine
	# =====================================================================
	my $sirna_obj = pre_blast_filter($candidate, $GENE_OBJECT, $pos, $end_pos);
	
	if ($sirna_obj) {
	    $GENE_OBJECT->addSiRNA($sirna_obj);
	}

    }
    
    # ================================
    # save parameters for next script
    # ================================
    my %param = ();
    $param{EMAIL}          = $EMAIL;     # email address
    $param{BLAST}          = $BLAST;     # NCBI/WU
    $param{SPECIES}        = $SPECIES;   # HUMAN/MOUSE/RAT
    $param{DATABASE}       = $DATABASE;  # refseq/unigene
    $param{TA_RUN_NUM}     = $TA_RUN_NUM;
    $param{G_RUN_NUM}      = $G_RUN_NUM;
    $param{BASE_VARIATION} = $BASE_VARIATION;
    $param{BASE_VARIATION} = $BASE_VARIATION_NUM;
    $param{CUSTOM_PATTERN} = $CUSTOM_PATTERN;
    $param{PATTERN}        = $PATTERN;
    $param{ENDING}         = $ENDING;
    $param{MIN_GC}         = $MIN_GC;
    $param{MAX_GC}         = $MAX_GC;
    $param{GC_RUN_MAX}     = $GC_RUN_MAX;
    $param{GENE_ID}        = "Y" if ($GENE_ID);
    $param{LENGTH}         = $LENGTH;
    $param{ACC}            = $GENE_OBJECT->acc;
    $param{GI}             = $GENE_OBJECT->gi;
    
    hashToFile($MyDataTxt, \%param);
    myinfo ("Saved parameters to $MyDataTxt\n");
    
}

# convert $MyDataOligo data to arrayOfarray 
else {

    $DATABASE = $QUERY->param("DATABASE"); # refseq/unigene
    $SPECIES  = $QUERY->param("SPECIES");  # human/mouse/rat
    $BLAST    = $QUERY->param("BLAST");    # NCBI/WU
    $VIA      = $QUERY->param("VIA");      # way to receive result
    $ENDING   = $QUERY->param("ENDING");   # over hang seq UU/TT 

    my @blast_candidates = @{file2arrayOFarray($MyDataOligo)};
    
    # change 2D_array to siRNA objects
    
    $GENE_OBJECT = GeneObject -> new();

    for my $i( 0..$#blast_candidates ) {
	
	# 147-169 AACTCTAGGAACAAATTGGACTT A,B     40      2.8 ( -8.4, -11.2 )
        my $seed_obj = Seed->new (
				  gene_count   => $blast_candidates[$i][7],
				  gene_id      => $blast_candidates[$i][8],
				  ratio        => $blast_candidates[$i][9],
				  seed         => $blast_candidates[$i][10]
				 );
	
	my $sirna_object = SiRNAObject->new(
					    pos           => $blast_candidates[$i][0],
					    candidate     => $blast_candidates[$i][1],
					    pattern       => $blast_candidates[$i][2],
					    gc_percentage => $blast_candidates[$i][3],
					    energy        => $blast_candidates[$i][4],
					    region        => $blast_candidates[$i][5],
					    snp_id        => $blast_candidates[$i][6],
					    seed          => $seed_obj
					    );
	
	$GENE_OBJECT->addSiRNA($sirna_object);
	
    }

}


# ===================================
# sort the sirnas
# write text file for next script
#      write danamic html
#    use PrimaryWriter.pm
# ==================================
write_oligo_html($GENE_OBJECT, $QUERY, $ENDING);

myinfo(	" === end of show_oligo.cgi ===");




 


# ******************************************************
#              *** SUBROUTINES ***
# ******************************************************


   
# ===========
# count GC%
# ===========
sub count_gc {
    my $seq = shift;
    my $total_len = length($seq);

    $seq =~ tr/Ss/Gg/;                   # S = G or C
    my $gc_len = $seq =~ tr/GCgc/GCgc/;
    my $pcGC = 100*$gc_len/$total_len + 0.5;
    mydebug("+++GC=", $pcGC, "\n");
    
    my $pcGCrounded = int($pcGC);
    return $pcGCrounded;
}


# ===========
# count_base
# ===========
sub count_base {
    my $seq = shift;
    my $low_rounded;
    my $high_rounded;
    my $total_len = length($seq);
    my $g_len = $seq =~ tr/Gg/Gg/;
    my $c_len = $seq =~ tr/Cc/Cc/;
    my $a_len = $seq =~ tr/Aa/Aa/;
    my $t_len = $seq =~ tr/TtUu/TtTt/;
    my $g_ratio = 100*$g_len/$total_len;
    my $c_ratio = 100*$c_len/$total_len;
    my $t_ratio = 100*$t_len/$total_len;
    my $a_ratio = 100*$a_len/$total_len;
    my @array = ($g_ratio, $c_ratio, $t_ratio, $a_ratio);
    mydebug("g:c:t:a=", $g_len, ":", $c_len, ":", $t_len, ":", $a_len, "\n");
#    mydebug("g:c:t:a=", $g_ratio, ":", $c_ratio, ":", $t_ratio, ":", $a_ratio, "\n");
    my @sorted_array = sort { $a <=> $b } @array;
    $low_rounded = int($sorted_array[0]);
    $high_rounded = int($sorted_array[-1]);
    return ($low_rounded, $high_rounded);
}

### save sequence in a file with fasta format ###
###################
# check_fasta
# accept: bare sequence, and fasta sequence
###################

sub check_fasta {
    my $sequence = shift;
    my $head = "";
    my $base = "";
    my $head_line = -1;

    my @array = split(/\n/, $sequence);
    for (my $i = 0; $i <= $#array; $i++) {
        ### ignore empty line ###
        if ($array[$i] =~ /^\s*$/) {
            next;
        }
        ### ">" is consider defline ###
	if ($array[$i] =~ /^\s*(\>.*)/) {
	    $head = $1;
            $head_line = $i;
	}
        ### the bases: for fasta format, only include the line after ">" ###
	if ($i > $head_line) {
            $array[$i] =~ s/\s+//g;

	    # only certain letters allowed
	    if ($array[$i] =~ /[^atcgnukmrswybdhvACTGNUKMRSWYBDHV]/) {
		return (0, $base, $head);
	    }
	    else {
		$base .= $array[$i];
	    }
	}
    }
    if ($base ne "") {
	$base =~ s/\s+//g;

        ### bare sequence defline is ">Unknown" ###
        $head = '>Unknown' if ($head_line == -1);

	### write sequence to $MyDataFasta ###
	printFastaToFile($MyDataFasta, $head, $base);

        ### RNA to DNA ###
	$base =~ s/U/T/g;
	$base =~ s/u/t/g;
	return (1, $base, $head);
    }
    else {
	return (0, $base, $head);
    }
}


sub custom_check {
    my $custom  = shift;
    my $custom_length = 0;
    my $custom_revised = "";

    ### use IUB/IUPAC nucleic acid codes ### 
    $custom =~ s/N/\[ACTG\]/g;
    $custom =~ s/n/\[actg\]/g;

    $custom =~ s/R/\[AG\]/g;
    $custom =~ s/r/\[ag\]/g;

    $custom =~ s/Y/\[CT\]/g;
    $custom =~ s/y/\[ct\]/g;

    $custom =~ s/M/\[AC\]/g;
    $custom =~ s/m/\[ac\]/g;

    $custom =~ s/K/\[TG\]/g;
    $custom =~ s/k/\[tg\]/g;
    
    $custom =~ s/S/\[CG\]/g;
    $custom =~ s/s/\[cg\]/g;
    
    $custom =~ s/W/\[AT\]/g;
    $custom =~ s/w/\[at\]/g;
    
    $custom =~ s/H/\[ACT\]/g;
    $custom =~ s/h/\[act\]/g;

    $custom =~ s/B/\[CTG\]/g;
    $custom =~ s/b/\[ctg\]/g;
    
    $custom =~ s/v/\[acg\]/g;
    $custom =~ s/V/\[ACG\]/g;
    
    $custom =~ s/D/\[ATG\]/g;
    $custom =~ s/d/\[atg\]/g;

    ### replace u with t ###
    $custom =~ s/U/T/g;
    $custom =~ s/u/t/g;


    if ($custom =~ /^[ACTGN0-9\[\]]+$/i) {
	my @array = split(//, $custom);
	while(my $token = getToken(\@array)) {
#	    print "TOKEN=$token\n";
	    my $token_length = 1;
	    if ($token =~ /([0-9]+)/) {
		$token_length = $1;
	    }
#	    print "token length = $token_length \n";

	    $custom_length += $token_length;

	    $token =~ s/([0-9]+)/{$1}/g;
	    $custom_revised .= $token;
	}
	if ($#array >= 0) {
	    return (0, $custom);
	}
    }
    return ($custom_length, $custom_revised);
}

sub getToken {
    my $arrayref = shift;
    my $token = "";
    my $expect = '[N';
#    print "DEBUG: ",@$arrayref,"\n";
    while (($#$arrayref >= 0) && ((my $chr = shift @$arrayref) ne '')) {	
#	print "DEBUG: char: $chr\n";
	if ($expect eq '[N') {
	    if ($chr eq "[") {
		$token .= $chr;
		$expect = ']N';
	    }
	    elsif ($chr =~ /^[ACTG]$/i) {
		$token .= $chr;
		$expect = 'D';
	    }
	    else {
		$expect = '';
	    }
	}
	elsif ($expect eq ']N') {
	    if ($chr eq "]") {
		$token .= $chr;
		$expect = 'D';
	    }
	    elsif ($chr =~ /^[ACTG]$/i) {
		$token .= $chr;
	    }
	    else {
		$expect = '';
	    }
	}
	elsif ($expect eq 'D') {
	    if ($chr =~ /^[0-9]$/i) {
		$token .= $chr;
	    }
	    else {
		$expect = '';
	    }
	}
	elsif ($expect ne '') {
	    #error - unknow state
	}

	if ($expect eq '') {
#	    print "DEBUG: before unshift: ",@$arrayref,"\n";
	    unshift @$arrayref, $chr;
#	    print "DEBUG: after unshift: ",@$arrayref,"\n";
	    last;
	}

#	print "DEBUG: token: $token\n";
#	print "DEBUG: expect: <$expect>\n";
    }
    return $token;
}

sub validate_db_info {
    
    $UserSessionID = $QUERY->param("tasto");

    $VIA = $QUERY->param("VIA");
    if (!$VIA) {
	$VIA = "email";
	$QUERY->param("VIA",$VIA) ;
    } 
    $EMAIL = $QUERY->param("EMAIL");

    if ($MyCheckMySQL) {
	my $check = Check->new;
	my $dbh = $check->dbh_connection();
	my $user_auth_id = $check->checkUserSession($dbh, $UserSessionID);
	my $login_page = "home.php";

	my $db_email = $check->get_email($dbh, $user_auth_id);
	if (! $user_auth_id ) {
	    $check->redirectToLoginPage($login_page);
	    exit;
	}
	
	if (! $check->updateCount($dbh, $UserSessionID, $db_email)) {
	    $check->redirectToLoginPage($login_page);
	    exit;
	}
	if (($VIA eq "email") && (!$EMAIL)) {
	    $EMAIL = $db_email;
	    $QUERY->param("EMAIL",$EMAIL) ;
	}
	$check->dbh_disconnect($dbh);
    }
}

sub validation {
    
    my ($error, $htmlError);
    my $seq = "";
    my $header = "";
    my $type = "";
    my $pattern = "";

    # ===========================
    # check the user PATTERN
    # ==========================
    
    if (($PATTERN ne "AA") &&
	($PATTERN ne "NA") &&
	($PATTERN ne "PEI") &&
	($PATTERN ne "custom") ) {
	$htmlError .= "Please choose your pattern." . $QUERY->br;
	$error = 1;
    }
    
    if ($PATTERN eq "custom") {
	$CUSTOM_PATTERN =~ s/\s+//g;
	if ($CUSTOM_PATTERN eq "") {
	    $htmlError .= "Please fill in your custom pattern." . $QUERY->br;
	    $error = 7;
	}
    }
    
    # ===============
    # validate email
    # ===============
    $EMAIL =~ s/\s+//g;
    if ( (defined $EMAIL) && ($EMAIL ne "") ) {
	if (! Email::Valid->address($EMAIL)) {
	    $htmlError .= "Please input correct e-mail address." . $QUERY->br;
	    $error = 4;
	}
    }
    
    # ==============
    # GC_Validation
    # ==============
    $MIN_GC =~ s/\s+//g;
    $MAX_GC =~ s/\s+//g;
    $GC_RUN_MAX =~ s/\s+//g;
    if (($MIN_GC > $MAX_GC) || ($MIN_GC !~ /^\d+$/) || ($MAX_GC !~ /^\d+$/) || ($GC_RUN_MAX !~ /^\d+$/ )) {
	$htmlError .= "Please input correct gc values." . $QUERY->br;
	$error = 10;
    }
     
    # =====================
    # SEQUENCE information
    # =====================

    if ( (! $SEQUENCE) || ($SEQUENCE =~ /^\s+$/) ) {
	$SEQUENCE = "";
    }
    if ( (! $GENE_ID) || ($GENE_ID =~ /^\s+$/) ) {
	$GENE_ID = "";
    }
    # no seq infor
    if ( ($SEQUENCE eq "" ) && ($GENE_ID eq "") ) {
	$htmlError .= "Please input your sequence information." . $QUERY->br;
	$error = 2;
    }
    # GENE_ID
    if ($GENE_ID ne "") { # gene_id > sequence
	my $fasta = get_fasta_remote($GENE_ID);
    	(my $fasta_test, $seq, $header) = check_fasta($fasta);
	if ( $fasta_test == 0 ) {
	    $htmlError .= "Your gene_id is not recognizable:$GENE_ID " . $QUERY->br;
	    $error = 5;
	}
    }
    # input sequence
    if ($SEQUENCE ne "") {
	(my $fasta_test, $seq, $header) = check_fasta($SEQUENCE);
	if ( $fasta_test == 0 ) {
	    $htmlError .= "Please input your sequence in right format." . $QUERY->br;
	    $error = 6;
	}
    }
    # size should be less than 150,000
    if (length($seq) > 150000) {
	$htmlError .= "Your sequence size length($SEQUENCE) is too large." . $QUERY->br;
	$error = 9;
    }

    # ============
    # get pattern
    # ============
    if ($PATTERN eq "AA") { #AAN(19)TT
	$type = "A";
	$pattern = "AA[ACTG]{19}TT";
    }
    
    elsif ($PATTERN eq "NA") { #NAN19NN
	mydebug( "pattern=$PATTERN\n" );
	$type = "B";
	$pattern = "[ACTG]A[ACTG]{21}";
    }
    elsif ($PATTERN eq "PEI") { #N2[CG]N8[AU]N8[AU]N2
	mydebug( "pattern=$PATTERN\n" );
	$type = "C";
	$pattern = "[ACTGU]{2}[CG][ACTGU]{8}[AUT][ACTGU]{8}[AUT][ACTGU]{2}";
    }
    elsif ($PATTERN eq "custom") { #custom pattern
	$type = "F";
	(my $custom_length, $pattern) = custom_check($CUSTOM_PATTERN);
	if ($custom_length != $LENGTH) {
	    $htmlError .= 
		"Your pattern $CUSTOM_PATTERN is not in right format.<br>" . 
		"Your pattern should has 23 bases.<br>" .
		"Please refer to 'FAQ' for detail information.<br>";
	    $error = 8;   
	}
	else {
	    mydebug( "custom_length=", $custom_length, "custom_revised=", $pattern, "type=", $type, "\n");
	}
    }
    mydebug( "$error, $htmlError, $seq, $header, $type, $pattern" );
    return($error, $htmlError, $seq, $header, $type, $pattern);
}


# 10/31/2016: NCBI changed the header line of fasta format: no gi
# no gi from header line, only ACC in header line
#
#sub get_id_from_header {
#   my $defline = shift;
#    my $gi = 0;
#    my $acc = "";
#    mydebug( "defline=$defline" );
#    if ($defline =~ /^>gi\|(\d+?)\|.*?\|(.*?)\|/) {
#        $gi = $1;
#        $acc= $2;
#    }
#    else {
#	myfatal ( "Could not get gi and acc from $defline" );
#    }
#    return ($gi, $acc);
#}

sub get_id_from_header {
    my $defline = shift;
    my $gi = "";
    my $acc = "";
    mydebug( "defline=$defline" );
    if ($defline =~ /^>(.*?)\s+/) {
        $acc= $1;
	mydebug( "acc=$acc" );
    }
    else {
	myfatal ( "Could not get gi and acc from $defline" );
    }
    return ($gi, $acc);
}


sub get_seq_regions {
    my $gi = shift;
    
    # New RegionAcc obj
    #
    my $seq = RegionAcc ->new(
			      gi => $gi
			      );
    $seq->get_regions();
    
    return $seq;
}

sub get_all_snp {
  my $acc = shift;
  my $version;
  # remove version
  if ($acc =~ /(.*)\.(\d+)/) {
    $acc = $1;
    $version = $2;
  }
  my $dbh = Database::connect_db("sirna2");
  my $snp_aref = Database::get_snp_all($dbh, $acc, $version);
  Database::disconnect_db($dbh);

  return $snp_aref;
}

