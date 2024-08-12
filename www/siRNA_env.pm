#! /usr/bin/perl -w

#################################################################
# Copyright(c) 2001 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Author:      Bingbing Yuan <siRNA-help@wi.mit.edu>
# Created:     12/4/2002
#
# This script contains environment constants.
#################################################################

package SiRNA;

use strict;

# need to be changed on production site:
#our $sirnaEnv = "test";
our $sirnaEnv = "production";

our ($PERL, $Home, $SiRNAUrlHome, $cgiHome, $MyHomePage);
our ($MyClusterLib, $MyClusterHome, $MyCheckMySQL, $MyForkProcess);
our ($MyBlastDir, $MyBlastDataDir, $MyBlatHuman, $MyBlatMouse);
our ($MyClusterLDLib, $MyBsubDir);
our ($MyNearestNeighborTable, $MyDanglingTable);

my ($ApacheHome, $MyFileDir);

$MyFileDir           = "/cgi-bin/siRNAext/db"; 
$MyNearestNeighborTable = "${MyFileDir}/nearest_neighbor_energy.txt";  # enery table
$MyDanglingTable        = "${MyFileDir}/dangling_3_energy.txt";        # energy table

$MyBsubDir       = "/usr/local/bin/";

if ($sirnaEnv =~ /test/) {
    $MyCheckMySQL = 1;
}
else {
    $MyCheckMySQL = 1;
}



if ($sirnaEnv eq "test") {

}    

elsif ($sirnaEnv eq "production") {
    $ApacheHome  = "/var/www"; 
    *PERL           = \"/usr/local/bin/perl";
    *Home           = \"/var/www/siRNAext"; 
    *SiRNAUrlHome   = \"http://yourHost.com/"; # change to your host
    *cgiHome        = \"/siRNAext"; 
    *MyHomePage     = "/siRNAext"; 
    *MyClusterLib   = \"/cgi-bin/siRNAext/lib"; 
    *MyClusterHome  = \"/var/www/siRNAext"; 
}


1;
