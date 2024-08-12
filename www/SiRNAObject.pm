#! /usr/bin/perl -w
 
#################################################################
# Copyright(c) 2003 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     4/11/2003
# revised:     6/26/2004
#################################################################
 
use strict;
use siRNA_log;

# this data object class hold data for each acc_id
 
package SiRNAObject;
 
use Class::Struct;
 
struct SiRNAObject => {
    pos                     => '$',   # 211
    region                  => '$',   # utr5/coding/utr3
    candidate               => '$',   # sequence: 23mer
    gc_percentage           => '$',   # gc%
    snp_id                  => '$',
    snp_count               => '$',
    pattern                 => '$',   # A/B/C/F
    energy                  => '$',   # thermodynamic value
    seed                    => '$',   # reference to seed obj
		       
};

sub addHsp {
    my $self = shift;
    my $hsp = shift;
    push @{ $self->hsps }, $hsp;
}

sub write_blast_html {
    my $self = shift;
    my $file = shift;
    
    open(BLAST, ">$file") || die "can't write to $file\n"; 

    print BLAST <<EOF
	<!DOCTYPE html
	PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
	"http://www.w3.org/TR/html4/loose.dtd">
	<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
	<head>
	<title>blast</title>
	<body>
EOF
;

    # print table header line:
    print BLAST
	"<table cellpadding='2' cellspacing='2' border='1'>",
	"<tr bgcolor='CCCCCC' align='center'>",
	"<th>Target_Unigen</th>",
	"<th>Description</th>",
	"<th>Genbank</th>",
	"<th>Identity</th>",
	"<th>Alignment</th>",
	"</tr>";
    
    foreach my $hsp (sort {$b->identity <=> $a->identity} @{ $self->hsps } ) {
	
	my ($ug_link, $gb_link, $alignment);
	$alignment = $hsp->get_alignment();
	
	if ($hsp->hit_id =~ /([a-z]+)\#S([\d]+)$/i) {
            $ug_link = '<a href=http://www.ncbi.nlm.nih.gov/UniGene/seq.cgi?ORG=' . $1 . '&SID=' . $2 . '>' . $hsp->hit_id . '</a>';
        }
	
	$gb_link = '<a href=http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=retrieve&db=Nucleotide&dopt=GenBank&dispmax=20&uid=' . $hsp->hit_gi . '>' . $hsp->hit_gb . '</a>';
	
	
	# print to file
	print BLAST
	    "<tr>",
	    "<td>$ug_link</td>",
	    "<td>",$hsp->hit_name,"</td>",
	    "<td>$gb_link</td>",
	    "<td>",$hsp->identity,"</td>",
	    "<td>$alignment</td>",
	    "</tr>";
    }

    print BLAST <<EOF
	</table>
	</body>
	</html>
EOF
;	

    close(BLAST);
}


1;

