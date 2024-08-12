#!/usr/local/bin/perl -w -I./ 

#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     11/13/2002
#
#################################################################

package SiRNA;
use Check;
use CGI;
use siRNA_env;
use siRNA_util;

our $SiRNAUrlHome;

### remove rid row from logins table ###
my $query = new CGI;
print $query->header("text/html");
print $query->start_html;

our $UserSessionID = $query->param("tasto");
my $check = Check->new;
my $dbh = $check->dbh_connection();
$check->deleteRid($dbh, $UserSessionID);
$check->dbh_disconnect($dbh);

print <<EOF;
<pre>
<p style="FONT-SIZE: 14pt; COLOR: BLACK"><b>
You have successfully logged out. You can now close your window.
To login again, click <a href="$SiRNAUrlHome/home.php">here</a>.
</p>
<p style="FONT-SIZE: 18pt; COLOR: BLUE">
Thank you for using siRNA selection program!
</p>
</pre>
EOF
;

print $query->end_html;
