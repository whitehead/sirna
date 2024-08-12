#! /usr/bin/perl -w

#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Author:      Bingbing Yuan <siRNA-help@wi.mit.edu>
# Created:     2/7/2003
#
#################################################################

package SiRNA;

use Time::Local;
use CGI;
use siRNA_log;

#######################################################################
# Create an unique session id from the current time and process id
#######################################################################

sub createSessionID {
    my ($sec, $min, $hour, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
    my $RealMonth = $month + 1;
    my $RealYear = $year + 1900;
    my $RealDate = "$RealYear-$RealMonth-$day";
    my $midnight = timelocal(0,0,0,$day,$month,$year);
    my $secondoftheday = timelocal($sec, $min, $hour, $day, $month, $year)-$midnight;  
    return "${RealDate}-${secondoftheday}-$$";
}

sub getSessionIDFromCGI {
    my $query = shift;
    mydebug("Getting SessionID from CGI ...");
    if (ref $query eq "CGI") {
        mydebug("Found from CGI."); 
        return $query->param("pid");
    }
    else {
        mydebug("Not a CGI object.");
        return "";
    }
}

sub getSessionIDSubFromCGI {
    my $query = shift;
    mydebug("Getting SessionID from CGI ...");
    if (ref $query eq "CGI") {
        mydebug("Found from CGI.");
        return $query->param("pid2");
    }
    else {
        mydebug("Not a CGI object.");
        return "";
    }
}


1;
