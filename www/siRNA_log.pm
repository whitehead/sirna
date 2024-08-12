#! /usr/local/bin/perl -w

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

use Log::Log4perl; 
use strict;

Log::Log4perl->init("siRNA_log.conf");
$Log::Log4perl::caller_depth = 1;
my $logger = Log::Log4perl->get_logger("SiRNA");
 
###################################################################### 
# The following subroutines provides 5 levels of logging:
# See: http://log4perl.sourceforge.net/ 
#
#    debug   --   very detail information for debugging
#    info    --   infomational messages
#    warn    --   warning messages, administrator should be alerted
#    error   --   error messages, action demanded.
#    fatal   --   fatal errors, program should exit.
######################################################################  

sub mydebug {
    if ($SiRNA::MySessionID) {
        $logger->debug("[$SiRNA::MySessionID] @_");
    }
    else {
        $logger->debug("[] @_");
    }
}
sub myinfo {
    if ($SiRNA::MySessionID) {
	$logger->info("[$SiRNA::MySessionID] @_");
    }
    else {
	$logger->info("[] @_");
    }
}
sub mywarn {
    if ($SiRNA::MySessionID) {
	$logger->warn("[$SiRNA::MySessionID] @_");
    }
    else {
	$logger->warn("[] @_");
    }
}
sub myerror{
    if ($SiRNA::MySessionID) {
	$logger->error("[$SiRNA::MySessionID] @_");
    }
    else {
	$logger->error("[] @_"); 
    }
    printToWWW(@_);
}
sub myfatal {
    if ($SiRNA::MySessionID) {
	$logger->fatal("[$SiRNA::MySessionID] @_");
    }
    else {
	$logger->fatal("[] @_"); 
    }
    printToWWW(@_);	
    exit 1;
}
sub printToWWW {
    my( $reason, $query ) = @_;
    if (ref $query eq "CGI") {
        print $query->header("text/html");
        print $query->start_html('siRNA Error');
        print
            $query->h1( "Error:" ),
            $query->p( $query->i( $reason ) ),
            $query->end_html();
    }
}

1;
