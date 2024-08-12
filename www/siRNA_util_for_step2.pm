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

our ($MySessionIDSub, $UrlHome, $DateDir, $Today);

#################################################################
# SiRNA->initialize must be called before this method be called
#################################################################

sub initializeStep2 {
    our $MyDataTxt2 = "${DateDir}/${MySessionIDSub}.txt2";
    our $MyDataBlastOut = "${DateDir}/${MySessionIDSub}.blo";

    our $MyDataHtml = "${DateDir}/${MySessionIDSub}.html";
    our $MyDataHtmlUrl = "${UrlHome}/${Today}/${MySessionIDSub}.html";

    our $MyDataPng = "${MySessionIDSub}.png";
    our $MyDataPngFullPath = "${DateDir}/${MyDataPng}";

    our $MyDataAlign = "${DateDir}/${MySessionIDSub}.align.txt";
    our $MyDataAlignUrl = "${UrlHome}/${Today}/${MySessionIDSub}.align.txt";

    our $MyDataTabTxt = "${DateDir}/${MySessionIDSub}.tab.txt";
    our $MyDataTabTxtUrl = "${UrlHome}/${Today}/${MySessionIDSub}.tab.txt";

    our $MyUserLink = "${DateDir}/${MySessionIDSub}_result.html";
    our $MyUserLinkUrl = "${UrlHome}/${Today}/${MySessionIDSub}_result.html";

    our $MyDiffHtml = "${DateDir}/${MySessionIDSub}.diff.html";
    our $MyDiffHtmlUrl = "${UrlHome}/${Today}/${MySessionIDSub}.diff.html";

    our $MyArgvs =  "${DateDir}/${MySessionIDSub}_argvs.txt";

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

    $ENV{'BLASTDIR'} = $SiRNA::MyBlastDir;
    $ENV{'BLASTDATADIR'} = $SiRNA::MyBlastDataDir;

}

1;
