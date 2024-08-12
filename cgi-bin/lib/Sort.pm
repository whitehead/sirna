#! /usr/bin/perl -w 
 
#################################################################
# Copyright(c) 2003 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     12/18/2003
# updated:     6/29/2004
# author:      Bingbing Yuan
#################################################################

# ====================================================== #
# purpose: write center html and download pages
#          
# need:    read txt3 file, and sort_name        
# called by sort_sirnas.cgi or by siRNA_step2.cgi(default)
# ====================================================== #

package SiRNA;
 
use strict;
use Class::Struct;
use siRNA_log;
use siRNA_util;


sub sort_sirna {
    my ($sirnaObjects, $sort) = @_;
    mydebug("in Sort.pm: sortby=$sort"); 
    my @SIRNAS = @$sirnaObjects;
    
    if ($sort =~ /pos/i )
    {
	@SIRNAS = @{sortbynumber(\@SIRNAS, "SiRNAObject::pos")};
    }
    elsif ($sort =~ /type/i) {
	@SIRNAS = @{SiRNA::sortbystring(\@SIRNAS, "SiRNAObject::type")};
    }
    elsif ( $sort =~ /pattern/i ) {
	@SIRNAS = @{SiRNA::sortbystring(\@SIRNAS, "SiRNAObject::pattern")};
    }
    if ($sort =~ /gc/i ) 
    {
	@SIRNAS = @{SiRNA::sortbynumber(\@SIRNAS, "SiRNAObject::gc_percentage")};
    }
    elsif ($sort =~ /energy/i || 
	   $sort =~ /thermodynamic/i )
    {
	@SIRNAS = @{SiRNA::sortbyenergy(\@SIRNAS, "SiRNAObject::energy")};
    }
    elsif ($sort =~ /snp/i )
    {
	@SIRNAS = @{sortbysnp(\@SIRNAS, "SiRNAObject::snp_id")};
    }
    elsif ($sort =~ /blast/i )
    {
	@SIRNAS = @{sortbyblast(\@SIRNAS, "SiRNAObject::max_non_target_identity")};
    }
    
    return \@SIRNAS;

}


1;

