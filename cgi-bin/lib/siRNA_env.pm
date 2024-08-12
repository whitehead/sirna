#!/usr/local/bin/perl -w

#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Author:      Bingbing Yuan <siRNA-help@wi.mit.edu>
# Created:     12/4/2002
# updated:     6/29/2004
# This script contains environment constants.
#################################################################

package SiRNA;

use strict;

# need to be changed at production
#our $sirnaEnv = "test";
our $sirnaEnv = "production";

our ($PERL, $Home, $SiRNAUrlHome, $cgiHome, $MyHomePage);
our ($MyClusterLib, $MyClusterHome, $MyCheckMySQL, $MyForkProcess);
our ($MyBlastDir, $MyBlastDataDir, $MyBlastDB);
our ($MyClusterLDLib, $LSRUN_DIR);

my $ApacheHome;


if ($sirnaEnv =~ /test/) {
    $MyCheckMySQL = 0;
}
else {
    $MyCheckMySQL = 1;
}


if ($sirnaEnv eq "test") {

}    
elsif ($sirnaEnv eq "production") {
    $MyClusterLDLib = "/cgi-bin/siRNAext/lib"; 
    $MyBlastDataDir = "/cgi-bin/siRNAext/db"; 
    $ApacheHome  = "/var/www"; 
    *PERL           = \"/usr/local/bin/perl";
    *Home           = \"/var/www/siRNAext/tmp"; 
    *SiRNAUrlHome   = \"admin\@domain.com"; # change to yours
    *cgiHome        = \"admin\@domain.com"; # change to yours
    *MyHomePage     = \".";
    *MyClusterLib   = \"/cgi-bin/siRNAext/lib";
    *MyClusterHome  = \"/var/www/siRNAext"; 
}


1;
