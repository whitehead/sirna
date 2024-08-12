#!/usr/local/bin/perl -w -I./ 

package SiRNA;

use strict;
use siRNA_env;
use siRNA_log;
use siRNA_util;
use siRNA_util_for_step2;
use GetSession;
use Check;
use Time::Local;
use CGI;
use JobStatus;

my $query = new CGI;

print $query->header("text/html");
print $query->start_html("result");

### parameters parsed from siRNA.cgi ###
our $UserSessionID =$query->param('tasto');
our $MySessionID = $query->param('my_session_id');
our $MySessionIDSub = $query->param('my_session_id_sub');
my $last_time_to_finish = $query->param('time_to_finish');
my $last_time = $query->param('current_time');

### find the amount of time need to finish the program ###
my $current_time = timelocal(localtime);
my $time_to_finish = int($last_time_to_finish - ($current_time - $last_time)/60);
if ($time_to_finish <= 0) {
    $time_to_finish = 1;
}
### initilize values ###
myinfo( "start show_result.cgi\n" );
validateSession();
initialize();
initializeStep2();

### response to user ###

### show the result page ###
if ( -e $SiRNA::MyUserLink ) {
    Check->new->redirectToLoginPage("$SiRNA::MyUserLinkUrl");
}
### keep updating the website until the MyUserLink file has creasted ###
else {

    # check how many web_jobs are running
#    my $web_jobs = check_webjobs_queue();
    my $web_jobs = server_check();
    
    printLogoutBar($UserSessionID);

    print $query->start_form(-method=>'get',
			    -action=>'show_result.cgi',
			    -name=>'ShowResultForm',
			    -encoding=>'multipart/form-data');


        print <<EOF
<script language="javascript">
window.setTimeout("document.forms[0].submit()", 10000);
</script>
EOF
;

    print $query->p("The following link to your result will be ready in about <font color='red'>$time_to_finish minutes:</font>");
    
    # ======================================================= #
    # check if there is unfinished job for this ID
    # each subID can go only after done with previous subID
    # ======================================================= #
    if (! job_status()) {
	print $query->p("It will take longer time than mentioned because another job of yours is running. This job will start once your previous job has finished\n");
    }
    
    if ($web_jobs) {
	print $query->p("Currently our server is busy. Please expect delays in getting your results");
    }
    
    print $query->hidden('time_to_finish', $time_to_finish);
    print $query->hidden('current_time', $current_time);
    print $query->hidden('tasto', $UserSessionID);
    print $query->hidden('my_session_id', ${MySessionID}); 
    print $query->hidden('my_session_id_sub', ${MySessionIDSub});
    print $query->p("<a href='javascript:document.forms[0].submit()'><img src=\'keep/animation.gif\'></a>");
 
}
myinfo( "ending show_result.cgi\n" );
print $query->end_html();

