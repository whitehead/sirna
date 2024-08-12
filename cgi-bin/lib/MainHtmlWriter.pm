#################################################################
# Copyright(c) 2003 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     4/11/2003
# updated:     6/29/2004
# author:      Bingbing Yuan
#################################################################
 
# ================================================== #
# purpose: write general frame, top and left frames
# called by siRNA_step2.cgi
# ================================================== #

package SiRNA;


use strict;
use siRNA_log;
use siRNA_util;
use siRNA_util_for_step2;

our ($MyUserLink, $MyTopHtml, $MyTopHtmlUrl, $MyCenterHtml, $MyCenterHtmlUrl, $MyLeftHtml, $MyLeftHtmlUrl, $MyDataFastaUrl, $MyDataTabTxtUrl, $cgiHome, $MyFAQHtmlUrl,  $MyGetsiRNABottonUrl, $MyContactUrl, $MyResultNoteUrl, $EMAIL, $UserSessionID, $MySessionIDSub, $MyDataTxt3);

sub MainOutHtml {
 
    my ($sirna_count) = shift;
    
    # write main html page
    write_general_frame();

    # write top html
    write_top_frame();


    # write left html
    write_left_frame($sirna_count);

}


# =====================
# write main html page
# =====================

sub write_general_frame {
    
    open (MAIN, ">$MyUserLink") || SiRNA::myfatal( "can't write to >$MyUserLink" );
    print MAIN <<EOF
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
	<html>
	<head>
	<title>siRNA result</title>
	<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
	</head>
	
	<frameset rows="52,*" cols="*" frameborder="NO" border="0" framespacing="0">
	   <frame src="$MyTopHtmlUrl" name="topFrame" scrolling="NO" noresize >
	   <frameset rows="*" cols="150,*" framespacing="0" frameborder="NO" border="0">
	      <frame src="$MyLeftHtmlUrl" name="leftFrame" noresize marginwidth="0">
	      <frame src="$MyCenterHtmlUrl" name="centerFrame">
	   </frameset>
	</frameset>
	<noframes><body>
	
	</body></noframes>
	</html>
EOF
;

    close(MAIN);

}

# =====================
# write top frame
# =====================

sub write_top_frame {

    open(TOP, ">$MyTopHtml") || SiRNA::myfatal( "can't write to $MyTopHtml" );
    
    print TOP <<EOF
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
	<html>
	<head>
	<title>welcome</title>
	<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
	<style type="text/css">
	<!--
	    body { background-color: #CCCCFF }
        -->
	</style>
	<script lanaguage="javascript">
        <!--
	function logout() {
		parent.location = "../../logout.cgi?tasto=$UserSessionID";
	}
	function startover() {
		parent.location = "../../siRNA_search.cgi?tasto=$UserSessionID";
	}
	// -->
        </script>
	
	</head>
	
	<body>
	<table width="100%">
	<tr>
	<td align='center' nowrap>
	<h3><a href="$MyResultNoteUrl" target="new">Welcome to siRNA results </a></h3>
	</td>
EOF
;

	# logout and start over bottons
	if (! $EMAIL) {
	    print TOP <<EOF
	<td nowrap valign="top" width="20%"><a href="javascript:logout()"><b>Log Out</b></a>&nbsp;&nbsp;&nbsp;&nbsp;<a href="javascript:startover()"><b>Start Over</b></a></td>
EOF
;
	}

	print TOP <<EOF
	</tr></table>
	</body>
	</html>
EOF
;
    close(TOP);
}


sub write_left_frame {

    my $sirna_count = shift;
    
    open(LEFT, ">$MyLeftHtml") || SiRNA::myfatal( "can't write to $MyLeftHtml" );
    
    print LEFT <<EOF
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
	<html>
	<head>
	<title>manu</title>
	<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
	<style type="text/css">
	<!--
	    body { background-color: #CCCCFF }
        -->
	</style>
	<SCRIPT language=JAVASCRIPT src="../../siRNAhelp.js"></SCRIPT>
EOF
;
    # javascript
    if ($sirna_count) {
	write_js_function(*LEFT);
    }

    print LEFT <<EOF
	</head>
	
	<body>

	<center>
	<br /><b>
	<p><a href="$MyDataFastaUrl" target="new">Query Seq </a></p>
EOF
;
    # forms
    if ($sirna_count) {

	print LEFT <<EOF

	<br>Download\:<br>
	<nobr> &nbsp; &nbsp; <a href="$MyDataTabTxtUrl" target="new">all tables</a></nobr>
	<nobr> &nbsp; &nbsp; <a href="javascript:getSirna()">selected siRNAs</a></nobr>

EOF
;	
    }
	else {
	    print LEFT <<EOF
		<p>&nbsp; </p>
		<p>&nbsp;</p>
		<p>&nbsp;</p>
EOF
;
	}
	
	
	print LEFT <<EOF
	<p><a href='javascript:help("../../keep/FAQ.html")'>FAQ</a></p>
	<p><a href='javascript:help("../../keep/contact.html")'>Contact</a></p>
	</b>
	<br />
        <hr />
        <br />

        </center>

        </body>
        </html>
EOF
;

	close(LEFT);
}


1;


