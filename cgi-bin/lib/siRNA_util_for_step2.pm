#! /usr/local/bin/perl

#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Author:      Bingbing Yuan <siRNA-help@wi.mit.edu>
# Created:     12/4/2002
#
#################################################################

package SiRNA;

use strict;

our ($MySessionID, $MySessionIDSub, $UrlHome, $DateDir, $Today, $cgiHome);

#################################################################
# SiRNA->initialize must be called before this method be called
#################################################################

sub initializeStep2 {
    our $MyDataTxt2 = "${DateDir}/${MySessionIDSub}.txt2";
    our $MyDataBlast = "${DateDir}/${MySessionID}_bl";

    our $MyDataHtml = "${DateDir}/${MySessionIDSub}.html";
    our $MyDataHtmlUrl = "${UrlHome}/${Today}/${MySessionIDSub}.html";

    our $MyDataPng = "${MySessionIDSub}.png";
    our $MyDataPngFullPath = "${DateDir}/${MyDataPng}";

    our $MyDataAlign = "${DateDir}/${MySessionIDSub}.align.txt";
    our $MyDataAlignUrl = "${MySessionIDSub}.align.txt";

    our $MyDataTabTxt = "${DateDir}/${MySessionIDSub}.tab.txt";
    our $MyDataTabTxtUrl = "${MySessionIDSub}.tab.txt";

    our $MyDataTxt3 = "${DateDir}/${MySessionIDSub}.txt3";
    our $MyDataTxt3Url = "${MySessionIDSub}.txt3";

    our $MyLeftHtml = "${DateDir}/${MySessionIDSub}_left.html";
    our $MyLeftHtmlUrl = "${MySessionIDSub}_left.html";
    
    our $MyTopHtml = "${DateDir}/${MySessionIDSub}_top.html";
    our $MyTopHtmlUrl = "${MySessionIDSub}_top.html";

    our $MyCenterHtml = "${DateDir}/${MySessionIDSub}_center.html";
    our $MyCenterHtmlUrl = "${MySessionIDSub}_center.html";

    our $OrgCenterHtml = "${DateDir}/${MySessionIDSub}_org_center.html";
    our $OrgCenterHtmlUrl = "${MySessionIDSub}_org_center.html";

    our $MyUserLink = "${DateDir}/${MySessionIDSub}_result.html";
    our $MyUserLinkUrl = "${UrlHome}/${Today}/${MySessionIDSub}_result.html";

    our $MyFAQHtmlUrl = "${cgiHome}/keep/FAQ.html";
    
    our $MyGetsiRNABottonUrl = "${cgiHome}/keep/get_sirnas.gif";
 
    our $MyContactUrl = "${cgiHome}/keep/contact.html";

    our $MyResultNoteUrl = "${cgiHome}/keep/result_note.html";

    our $MyDiffHtml = "${DateDir}/${MySessionIDSub}.diff.html";
    our $MyDiffHtmlUrl = "${UrlHome}/${Today}/${MySessionIDSub}.diff.html";

    our $MyLastFile = "${DateDir}/${MySessionIDSub}.end";

    if ($ENV{'LD_LIBRARY_PATH'}) {
        $ENV{'LD_LIBRARY_PATH'} = "${SiRNA::MyClusterLDLib}:$ENV{'LD_LIBRARY_PATH'}" if (${SiRNA::MyClusterLDLib});
    }
    else {
        $ENV{'LD_LIBRARY_PATH'} = "${SiRNA::MyClusterLDLib}"  if (${SiRNA::MyClusterLDLib});
    }
    if ($ENV{'PATH'}) {
        $ENV{'PATH'} = "/cluster/lsfpool/ncbiblast/:$ENV{'PATH'}";
    }
    else {
        $ENV{'PATH'} = "/cluster/lsfpool/ncbiblast/";
    } 

#    $ENV{'BLASTDIR'} = $SiRNA::MyBlastDir;
#    $ENV{'BLASTDATADIR'} = $SiRNA::MyBlastDataDir;

}

sub write_js_function {
    my $handle = shift;
    print $handle <<EOF
    <script language="javascript">
    <!--
    function sortSirna(sortValue) {
	var form = parent.frames["centerFrame"].document.forms["mainForm"];
	form.action.value="SORT";
	form.sort.value=sortValue;
	form.submit();
    }
    function getSirna() {
	var form = parent.frames["centerFrame"].document.forms["mainForm"];
	form.action.value="GET";
	form.submit();
    }
    function filterSirna() {
	var form = parent.frames["centerFrame"].document.forms["mainForm"];
	form.action.value="FILTER";
	form.submit();
    }
    //-->
    </script>
EOF
;
}
   
1;
