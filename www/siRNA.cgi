#!/usr/local/bin/perl

# ###!/usr/local/bin/perl -w -I./

#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Author:      Bingbing Yuan <siRNA-help@wi.mit.edu>
# Created:     09/28/2001
#
#################################################################

package SiRNA;

use strict;
use CGI;

use IO::Handle;
use CGI qw(:standard :html13);
#use CGI qw(param);
use integer;

use siRNA_env;
use siRNA_log;
use siRNA_util;
use siRNA_util_for_step2;
use Check;
use GetSession;
use Time::Local;
use Email::Valid;
use JobStatus;



my $query = new CGI;
my $CMD = "";
#print $query->header("text/html");

our ($UserSessionID, $MyDataTxt, $MySessionIDSub, $MyDataTxt2, $MyDataFasta);
our ($PERL, $MySessionID, $DateDir, $MyHomePage);
our ($MyCheckMySQL, $MySiRNAPid, $MyClusterLib, $MyUserLinkUrl, $MyErrorLog, $MyArgvs, $MyBsubDir);

# =========================
# validate session
# get Email afrom database
# =========================
$UserSessionID = $query->param("tasto");
my $check = Check->new;
if ($MyCheckMySQL) {
    my $dbh = $check->dbh_connection();
    my $user_auth_id = $check->checkUserSession($dbh, $UserSessionID);
    my $login_page = "$SiRNA::MyHomePage";

    if (! $user_auth_id ) {
	print $query->header("text/html");
	$check->redirectToLoginPage("index.php");
	exit;
    }
    $check->dbh_disconnect($dbh);
}

my $general_www_error = "Error: there is a problem processing your request, please contact <a href=\"mailto:admin\@domain.com\">siRNA-help</a> for help.<br /> Detail:message";

### check mysession ###
$MySessionID = getSessionIDFromCGI($query);

### validate mysession and initialize constants ###
validateSession();
initialize();

### get a new sessionID for txt2, html, etc  ###
my $txt2_dir = $DateDir;
mydebug ("txt2_dir=", $txt2_dir, "\n");
$MySessionIDSub = get_session_from_txt2($MySessionID, $txt2_dir);
mydebug ("MySessionIDSub=", $MySessionIDSub, "\n");

### initialize step2 constants ###
initializeStep2();

mydebug("MyDataTxt2=$MyDataTxt2");
mydebug( "argument file=$MyArgvs\n" );

### redirected to user input page if files are moved ###
if ( (! -e $MyDataTxt) || (! -e $MyDataFasta) ) {
    print $query->header("text/html");
    my $usr_input_page = $MyHomePage;
    mydebug (" 1=$MyDataTxt, 2=$MyDataFasta", "\n");
    my $check = Check->new;
    $check->redirectToLoginPage($usr_input_page);
    exit;
}

# save parameters to txt2 file ###
my %vparam = %{ fileToHash($MyDataTxt) };
my @oligos = $query->param("oligo");
$vparam{"oligo"}    = [@oligos];
$vparam{"DATABASE"} = $query->param("DATABASE");
$vparam{"VIA"}      = $query->param("VIA");
$vparam{"BLAST"}    = $query->param("BLAST");

# For WU BLAST, result can only sent through email
if ($query->param("BLAST") =~ /WU/) {
    $vparam{"VIA"} = "email";
}
$vparam{"EMAIL"}    = $query->param("EMAIL") if ($vparam{"VIA"} eq "email");
$vparam{"EMAIL"}    = "" if ( $vparam{"VIA"} ne "email"); 
$vparam{"SPECIES"}  = $query->param("SPECIES");


hashToFile($MyDataTxt2, \%vparam);

### calculating the when teh siRNA program is going to end ###
my $time_to_finish = int((sqrt($#oligos+1))*2 +0.5) + 3;
my $current_time = timelocal(localtime); 

# ==========================================================================
#                       check the user input error
# ==========================================================================
my $error = 0;
my $htmlError = "";

if ( $#oligos < 0) {
    $htmlError .= "There are no oligos choosed to blast." . $query->br;
    $error = 1;
}

# ===============                                                                                                       
# validate email                                                                                                        
# ===============                                                    
if ($vparam{"VIA"} eq "email") {
    $vparam{"EMAIL"} =~ s/\s+//g; 
    if ( (! $vparam{"EMAIL"} ) || (! Email::Valid->address($vparam{"EMAIL"}))) { 
	$htmlError .= "Please input correct e-mail address." . $query->br; 
	$error = 4; 
    }
} 

# =====================================
# no more than 100 siRNAs for all BLAST
# =====================================
#if ( $vparam{"BLAST"} =~ /WU/ &&
#     $#oligos >100 ) {
if ( $#oligos >100 ) {
    $htmlError .= 'The upper limit for the number of siRNAs candidates per request is 100.<br /> If you want to BLAST more oligos, please contact with admin\@domain.com';
    $error = 5;
}
    
if ($error) {
    myfatal($htmlError, $query);
}

mydebug( "argument file=$MyArgvs\n" );


# ===================================
# save arguments for siRNA_step2.cgi
# ===================================
my %tmp_hash = (
		"MySessionID"    => $MySessionID,
		"MySessionIDSub" => $MySessionIDSub,
		"UserSessionID"  => $UserSessionID
		);
hashToFile($MyArgvs, \%tmp_hash);

#if ( $vparam{"BLAST"} =~ /NCBI/) {
#    $CMD = "${MyBsubDir}/jsub \"$PERL $MyClusterLib/siRNA_step2.cgi $MyArgvs\"";
#}
#else {
#    $CMD = "${MyBsubDir}/jsub \"$PERL $MyClusterLib/siRNA_step2.cgi $MyArgvs\"";
#}

#if ( $vparam{"BLAST"} =~ /NCBI/) {
#    $CMD = "\"$PERL $MyClusterLib/siRNA_step2.cgi $MyArgvs\"";
#}
#else {
#    $CMD = "\"$PERL $MyClusterLib/siRNA_step2.cgi $MyArgvs\"";
#}


# ===========================================================================
#                         dual processes
# ===========================================================================
my $pid;

### fork a child process to run siRNA_step2.cgi
if (!defined($pid = fork))
{
    myfatal( "$general_www_error : can't fork. <br />", $query );
}
elsif ($pid == 0)
### this is the child process
{
    close(STDIN); close(STDOUT); close(STDERR);
    sleep(5); #pause for 5 sec
    myinfo( "Forking child process in the background" );
    $CMD .= "$PERL $MyClusterLib/siRNA_step2.cgi $MyArgvs";
    myinfo( "Start $CMD" );
    chdir ${SiRNA::MyClusterLib};

    my $_dir = `pwd`;
    myinfo( "mydir=$_dir" );
    myinfo( "cmd=$CMD" );
    system($CMD); # || die "can't exec $CMD: $!\n";
    exit;
}
else
{
    ### this is parent process
 
  # check how many web_jobs are running
  #    my $web_jobs = check_webjobs_queue();
  my $web_jobs = server_check();
  
  print $query->header("text/html");
  
  # startform is obsolete replace it with start_form 
  print $query->start_form(-method   => 'post',
			  -action   => 'show_result.cgi',
			  -name     => 'ShowResultForm',
			  -encoding => 'multipart/form-data'
			 );
  
  printLogoutBar($UserSessionID);
  
  print $query->hidden('time_to_finish', $time_to_finish);
  print $query->hidden('current_time', $current_time);
  print $query->hidden('tasto', $UserSessionID); 
  print $query->hidden('my_session_id', $MySessionID); 
  print $query->hidden('my_session_id_sub', $MySessionIDSub);
  myinfo("user's email:", $vparam{"EMAIL"});
  if ($vparam{"EMAIL"}) {
    print $query->p("Thank you for submitting your request.  " .
		    "You will receive an email with a link to your " .
		    "results when the job is complete.\n");
    if ($web_jobs >= 4) {
      print $query->p("Currently our server is busy. Please expect delays in getting your results\n");
    }
    
  }
  else {
print <<EOF
<script language="javascript">
window.setTimeout("document.forms[0].submit()", 10000);
</script>
EOF
;
	
 if ($query->param("BLAST") =~ /NCBI/i) {
   print $query->p("The following link to your result may be ready in about <font color='red'>$time_to_finish minutes</font>:\n");
 }
# ======================================================= #
# check if there is unfinished job for this ID
# each subID can go only after done with previous subID
# ======================================================= #
if (! job_status()) {
   print $query->p("It will take longer time than mentioned because another job of yours is running. This job will start once your previous job has finished\n");
 }
if ($web_jobs) {
  print $query->p("Currently our server is busy. Please expect delays in getting your results\n");
}

print $query->p("<a href='javascript:document.forms[0].submit()'><img src=\'keep/animation.gif\'></img></a>");

    }
  #    `echo $MySessionIDSub $pid >> $MySiRNAPid`;
    
  myinfo( "======= END of siRNA.cgi =============\n");
  exit;   #teminate parent process
}

### ================================= ###
###          subroutines              ###
### ================================= ###

##############################
# get sub sessionId from txt2
##############################

sub get_session_from_txt2 {
    my ($sessionID, $dir) = @_;
    my @txt2_list = ();
    my $new_session = "";
    
    opendir(BIN, $dir) or myfatal( "$general_www_error : Can't open $dir.<br />", $query );
      while(defined (my $file = readdir BIN) ) {
	  push(@txt2_list, $1) if ($file =~ /^$sessionID\_(\d+)\.txt2$/);
      }
    closedir(BIN);
    
    ### if no txt2 exist ###
    if ($#txt2_list <0 ) {
  	$new_session = $sessionID . '_0';
    }
    ### if several txt2 files, most recent one +1 ###
    else {
  	my @sorted_txt2_list = sort { $a <=> $b } @txt2_list;
  	$new_session = $sessionID . "_" . ($sorted_txt2_list[-1]+1);
    }
    #    print $new_session, "\n";
    return $new_session;
}
