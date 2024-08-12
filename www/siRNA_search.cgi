#!/usr/local/bin/perl

# ###! /usr/bin/perl -w -I/var/www/siRNAext


#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     11/13/2002
#
#################################################################

package SiRNA;


use CGI qw(:standard :html13);
use strict;
use CGI::Carp qw/fatalsToBrowser/;
use Check;
use GetSession;
use siRNA_env;
use siRNA_util;

our ($MyCheckMySQL, $MySessionID, $UserSessionID, $SiRNAUrlHome, $cgiHome);

my $query = new CGI;
print "Content-type: text/html\n\n";

# =========================
# validate session
# get Email afrom database
# =========================
$UserSessionID = $query->param("tasto");
my $check = Check->new;
my $EMAIL = "";

if ($MyCheckMySQL) {
    my $dbh = $check->dbh_connection();
    my $user_auth_id = $check->checkUserSession($dbh, $UserSessionID);
    if (! $user_auth_id ) {
	my $login_page = "home.php";
	$check->redirectToLoginPage($login_page);
	exit;
    }
    $EMAIL = $check->get_email($dbh, $user_auth_id);
    $check->dbh_disconnect($dbh);
#    print "mail=$EMAIL, user_pid=$user_auth_id\n"; 

}


### output the main page ###
print <<EOF
<!--
* File Name:  siRNA.html
*
* Author:  Bingbing Yuan
*
* Initial Version Creation Date: 08/29/01
*
* File Description:
*         Mainpage for search rna oligo
-->
<HTML>
<HEAD>
    <TITLE>siRNA Selection Program</TITLE>

<SCRIPT language=JavaScript>
<!--
var isNS = (document.layers) ? true : false;
var isIE = (document.all) ? true : false;
var isNS4 = (document.layers) ? true : false;
var isIE4 = (document.all && !document.getElementById) ? true : false;
var isIE5 = (document.all && document.getElementById) ? true : false;
var isNS6 = (!document.all && document.getElementById) ? true : false;
var mainForm;

function getMainForm() {
    if (isNS4) {
    mainForm = document.forms["MainRNAiForm"];
    }
    else {
    mainForm = document.forms["MainRNAiForm"];
    }
}

function validateForm() {
    return ( validateSequence() && validatePattern() && validateBases() && validateNavigator());
}

function validateNavigator() {
    
    if (navigator.appName == "Microsoft Internet Explorer") {
	return true;
    }
    else{
	var re = /Safari/i;
	if ( (navigator.appName == "Netscape") &&
	     (navigator.appVersion.match(re) ) ) {
	    //alert(navigator.appVersion);
	    //alert("Sorry, we only support Internet Explorer or Netscape");
	    return true;
	}
	return true;
    }
}

function trim(inputVal)
{
  var re = /\ /gi;
  var retVal = inputVal.replace(re, "");
  return retVal;
}

function validateSequence() {
    var new_gene_id_value = "";
    var new_sequence_value = "";
    // avoid bug in IE5 MAC
    if (mainForm.GENE_ID.value.length > 0) {
        new_gene_id_value = trim(mainForm.GENE_ID.value);
    }
    if (mainForm.SEQUENCE.value.length > 0) {
        new_sequence_value = trim(mainForm.SEQUENCE.value);
    }
    if (((new_sequence_value.length <= 0) && (new_gene_id_value.length <= 0))||
        ((new_sequence_value.length > 0) && (new_gene_id_value.length > 0)))
    {
        alert("you must provide either sequence, GI, accession number");
	return false;
    }
    else 
    {
        return true;
    }
}

function validatePattern() {
    if (mainForm.CUSTOM_PATTERN.value.length > 0)
    {
        if (mainForm.PATTERN[1].checked)
	{
	    return true;
	}
	else 
        {
	    alert("you cannot choose custom and other pattern at the same time");
	    return false;
	}
    }
    else {
        if (mainForm.PATTERN[1].checked)
        {
           alert("you must fill in yor pattern");
           return false;
        }
	else 
	{
	  return true;
	}
    }
}

function validateBases() {
    if ((mainForm.BASE_VARIATION.checked) && (mainForm.BASE_VARIATION_NUM.value.length <= 0))
    {
        alert("you must provide the amount of base variation");
	return false;
    }
    if (mainForm.TA_RUN_NUM.value.length <= 0)
    {
        alert("you must provide the maximum amount of the T/A ran in a row");
	return false;
    }
    return true;
}

function submitForm() {
    getMainForm();
    if (validateForm()) {
    mainForm.submit();
    return true;
    }
    else {
        return false;
    }
}   
//-->
</SCRIPT>
<SCRIPT language=JAVASCRIPT src="siRNAhelp.js"></SCRIPT>

</HEAD>

    <BODY BGCOLOR="#FFFFFF" LINK="#0000FF" VLINK="#660099" ALINK="#660099">

<H2 style="position: relative; left:150px;">
<FONT color="0000FF"><a href="javascript:help('./keep/help.html')">siRNA Selection Program</a></FONT> 
<!-- <a href="javascript:help('./keep/news.html')"><img src="keep/news.jpg" border=0 ></img><a> -->
</H2>

<!-- ENCTYPE= "multipart/form-data" -->
    <FORM ACTION="show_oligo.cgi" METHOD=POST NAME="MainRNAiForm" ENCTYPE="application/x-www-form-urlencoded">

    <input type=hidden name="tasto" value="$UserSessionID">
    <input type=hidden name="pid" value="$MySessionID">
	    <br>

	    <LI><font color=red>*</font> Enter your sequence in <a href="javascript:help('./keep/fasta.html')"> <b>Raw</b> or <b>FASTA</b> format</a> below,
	    <UL><textarea name="SEQUENCE" rows=6 cols=70></textarea></UL>
	    <!-- <font color=red>OR</font>&nbsp; 
	    enter <a href="javascript:help('./keep/gi_acc.html')">Accession number</a>--> <INPUT TYPE="hidden" name="GENE_ID" size=1 maxlength=15>
	    <p />
	    <LI><font color=red>*</font><a href="javascript:help('./keep/FAQ.html#pattern')">Choose the siRNA pattern</a>:
            <p />
	    <UL>
	    <table border=1 cellspacing=1>

	    <tr>
	    <th>Recommended patterns</th>
	    <th><a href="javascript:help('./keep/custom.html')">custom</a></th>
	    </tr>

	    <tr>
	    <td><input type="radio" checked name="PATTERN" value="PEI">&nbsp;N2[CG]N8[AUT]N8[AUT]N2</td>
	    <td rowspan=3><input type="radio" name="PATTERN" value="custom">&nbsp;<INPUT TYPE=text name="CUSTOM_PATTERN" value="" size=45 maxlength=50 ><br><center><a href="javascript:help('./keep/ending.html')">Enter pattern with 23 bases</a></center></td>
	    </tr>

	    
            <tr>
            <td><input type="radio" name="PATTERN" value="AA">&nbsp;AAN19TT</td>
            <td></td>
            </tr>

            <tr>
            <td><input type="radio" name="PATTERN" value="NA">&nbsp;NAN21</td>
            <td></td>
            </tr>

            </table>
	    </UL>
            
            <p />

	    <LI>Filter criteria:
	    <UL>
	    <LI><font color=red>*</font>GC percentage: from <INPUT TYPE="text" name="GC_MIN" size=2 maxlength=2 value=30>  to <INPUT TYPE="text" name="GC_MAX" size=2 maxlength=2 value=52>
	    <LI><font color=red>*</font><a href="javascript:help('./keep/ta_run.html')">exclude a run of</a> &nbsp; <INPUT TYPE="text" name="TA_RUN_NUM" size=1 value=4 maxlength=1>&nbsp; <a href="javascript:help('./keep/ta_run.html')">or more T or A in a row</a></td>
	    <LI><font color=red>*</font><a href="javascript:help('./keep/g_run.html')">exclude a run of</a> &nbsp;<INPUT TYPE="text" name="G_RUN_NUM" size=1 maxlength=1 value=4> <a href="javascript:help('./keep/g_run.html')">or more Gs in a row</a></td>
            <LI><font color=red>*</font>include less than <input TYPE="text" name="GC_RUN_MAX" size=2 value="7" maxlength=1> consecutive GC in a row. </input>
	    <LI><input type="checkbox"  name="BASE_VARIATION" value="base_variation">&nbsp; equal %(+/-<input type="text" name="BASE_VARIATION_NUM" size=4 maxlength=4 value=10>&nbsp%) for all 4 bases.</td>

	    </UL><p>

	    <LI><font color=red>*</font><a href="javascript:help('./keep/ending.html')">End your siRNAs with</a>
	    <select name ="ENDING">
	    <option>UU
	    <option>TT
	    <option>dNdN
	    <option>NN
	    </select>
	    <p />
	    <LI>
	    <INPUT TYPE=button VALUE="Search" onclick="submitForm();">
	    <INPUT TYPE="reset" VALUE="reset">
	    <P />

	    </UL>
  Note:&nbsp;
    <font color=red>*</font>: &nbsp; required parameters.
    </FORM>
    <p />
<HR>
Copyright 2004 Whitehead Institute for Biomedical Research. All rights reserved.<p />

<p />	<ADDRESS>
	Comments and suggestions to: <img src="keep/contact.jpg" align="center"></img></a>
	</ADDRESS>
	<BR />
<!--
	  Last modified: 
	  <SCRIPT LANGUAGE="JavaScript">
	  document.write(document.lastModified);
	  </SCRIPT>
	  EST 
-->

    </BODY>
</HTML>
EOF
