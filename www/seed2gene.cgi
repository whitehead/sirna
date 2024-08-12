#!/usr/local/bin/perl


# ###! /usr/bin/perl -I/usr/lib/perl5/site_perl/5.6.1/ -I./

#################################################################
# Copyright(c) 2008 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Author:      Bingbing Yuan <siRNA-help@wi.mit.edu>
# Created:     05/15/2008
#
#################################################################

package SiRNA;


use strict;
use CGI;
use CGI qw(:standard :html13);
use CGI qw(param);
use Database;


use CGI::Carp qw(fatalsToBrowser set_message);
    BEGIN {
        sub handle_errors {
    	my $msg = shift;
    	print "<h1>Oh gosh</h1>";
    	print "Got an error: $msg";
        }
       set_message(\&handle_errors);
}



my $QUERY = new CGI;
print $QUERY->header("text/html");
print $QUERY->start_html("sirna");

my $Seed = $QUERY->param("seed");
#my $Seed = "AAAAUCA";
if (! $Seed)
	{
		$QUERY->p("no seed sequence");
		exit;	
	}	

my $dbh = Database::connect_db("sirna");
my $gene_aref = Database::get7merGenes($dbh,$Seed);
Database::disconnect_db($dbh);

SiRNA::mydebug( "seed=$Seed, number_of_genes=", $#$gene_aref );

print $QUERY->h2("The Genes whose 3'UTR have binding site(s) for seed $Seed");
print '<br /><TABLE cellpadding=3 cellspacing=2 border=1>';
print '<TR><TH>Gene</TH><TH>Symbol</TH><TH>Description</TH></TR>';
foreach my $i(0..$#$gene_aref) {
	my $gene   = $gene_aref->[$i][0];
	my $symbol = $gene_aref->[$i][1];
	my $desc   = $gene_aref->[$i][2];
	
	print "<TR><TD>" . $gene . "</TD><TD>" . $symbol . "</TD><TD>" . $desc . "</TD></TR>\n";
}
print '</TABLE>';

print $QUERY->end_html();
