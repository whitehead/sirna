#! /usr/bin/perl -w
 
#################################################################
# Copyright(c) 2003 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     4/11/2003
# Modified:    7/16/2004
#
#################################################################
 

# this data object class hold data for each acc_id
 
package SiRNAObject;

use strict;
use Class::Struct;
use siRNA_log;
use Database;
 
struct SiRNAObject => {
    pos                     => '$',           # start pos of the full seq
    full_seq                => '$',
    blast_seq               => '$',           # the part of seq used for blasting
    gc_percentage           => '$',           # gc% of the blast_seq
    type                    => '$',           # AAN19TT, NAN21, or custom
    energy                  => '$',           # thermonynamic value: e.g. -1.14 ( -7.74, -6.60 )
    region                  => '$',           # utr5/coding/utr3
    snp_id                  => '$',
    snp_count               => '$',           # the number of snps
    boundary                => '$',           # exon/intron boundary 0.5 = N/A ; 1=in_junction; 0=not_in_junction
    max_non_target_identity => '$',           # the maximum non_target identity
    failure_reason          => '$',           # 
    hsps                    => '@',           # HSP objects
    hit_head                => '$',           # boulean: 1=unigene uniq seq is one of its blast targets
    fasta                   => '$',           # seq in fasta file
    blastout                => '$',           # original blast output file
    blasthtml               => '$',           # blast result as in html table
    blasttxt                => '$',           # text file for filtering step
    database                => '$',           # database for making the link for result html table
    blast                   => '$',           # NCBI/WU for making the link for result html table
    species                 => '$',           # HUMAN/MOUSE/RAT
    filter                  => '$',           # IDENTITY/POSITION
    
};

sub addHsp {
    my $self = shift;
    my $hsp = shift;
    push @{ $self->hsps }, $hsp;
}

sub addPos {
    my $self = shift;
    my $pos = shift;
    push @{ $self->pos }, $pos;    
}

sub filter_by_identity_refseq {
    my($self, $iden, $locuslink) = @_;
    my $file = $self->blasttxt;

    my $dbh = Database::connect_db("entrez_gene");
    open(FILE, $file) || SiRNA::myfatal( "can not open $file" );
    # NM_183380       17      1;2;4;5;6;7;8;9;10;11;12;13;14;15;18;19;20
    while(<FILE>) {
	my @arr = split(/\t/);
	my ($_acc, $_iden) = ($arr[0], $arr[1]);
	if ($_iden > $iden) {
	    if ($_acc =~ /NM/) {
		my $_locuslink = Database::get_locusid($dbh, $_acc);
		SiRNA::mydebug( "gene pos=", $self->pos, $locuslink, "compare with hit_acc=",  $_acc, $_locuslink );
		if ( $_locuslink &&
		     ! matching_anyId($locuslink,$_locuslink) ) {
		    Database::disconnect_db($dbh);
		      close(FILE);
#		      $self->failure_reason("pos=", $self->pos, $_acc, $_locuslink, "identity=", $_iden, ">", $iden);
		      SiRNA::mydebug( "FAILED on filter: pos=", $self->pos, $_acc, $_locuslink, "identity=", $_iden, ">", $iden );
		      return 1;
		  }
	    }
	}
    }
    Database::disconnect_db($dbh);
    close(FILE);
    SiRNA::mydebug( "PASSED on identity filter: pos=", $self->pos );    
    return 0;
    
}

sub filter_by_identity_ensembl {
    my($self, $iden, $ensembl) = @_;
    my $file = $self->blasttxt;

    my $dbh = Database::connect_db("sirna2");
    open(FILE, $file) || SiRNA::myfatal( "can not open $file" );
    # NENST00000307719 18      1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18
    while(<FILE>) {
	my @arr = split(/\t/);
	my ($_acc, $_iden) = ($arr[0], $arr[1]);
	if ($_iden > $iden) {
	    my $_ensembl = Database::get_ensemblGene($dbh, $self->species, "transcript_stable_id", $_acc);

	    SiRNA::mydebug( "gene pos=", $self->pos, $ensembl, "compare with hit_acc=",  $_acc, $_ensembl );
	    if ( $_ensembl &&
		 ! matching_anyId($ensembl, $_ensembl) ) {
		Database::disconnect_db($dbh);
		  close(FILE);
#		  my $reason = "pos=" . $self->pos . $_acc . " " . $_ensembl . " identity=" . " " . $_iden . ">" . $iden;
#		  $self->failure_reason($reason);
		  SiRNA::mydebug( "FAILED on filter: pos=", $self->pos, $_acc, $_ensembl, "identity=", $_iden, ">", $iden );
		  return 1;
	      }
	}
    }
    Database::disconnect_db($dbh);
    close(FILE);
    SiRNA::mydebug( "PASSED on identity filter: pos=", $self->pos );    
    return 0;
}


sub matching_anyId {
    my ($list, $hit) = @_;
    my @ids = split(';', $list);
    foreach my $_id(@ids) {
	if ($hit eq $_id) {
	    return 1;
	}
	else {
	}
    }
    return 0;
}


sub filter_by_identity_unigene {
    my($self, $iden, $unigene_cluster) = @_;
    my $file = $self->blasttxt;
    
    my $dbh = Database::connect_db("sirna2");
    open(FILE, $file) || SiRNA::myfatal( "can not open $file" );
    # NM_183380       17      1;2;4;5;6;7;8;9;10;11;12;13;14;15;18;19;20
    while(<FILE>) {
	my @arr = split(/\t/);
	my ($_acc, $_iden) = ($arr[0], $arr[1]);
	if ($_iden > $iden) {
	    my $_unigene_cluster = Database::get_unigeneCluster($dbh, $self->species, "uniq_unigene", $_acc);
	    SiRNA::mydebug( "gene pos=", $self->pos, $unigene_cluster, "compare with hit_acc=",  $_acc, $_unigene_cluster ); 
	    if ( $_unigene_cluster &&
		 ! matching_anyId($unigene_cluster,$_unigene_cluster) ) { 
		Database::disconnect_db($dbh);
		  close(FILE);
#		  $self->failure_reason("pos=", $self->pos, $_acc, $_unigene_cluster, "identity=", $_iden, ">", $iden);
		  SiRNA::mydebug( "FAILED on filter: pos=", $self->pos, $_acc, $_unigene_cluster, "identity=", $_iden, ">", $iden  );  
		  return 1;
	      }
	}
    }
    Database::disconnect_db($dbh);
    close(FILE);
    SiRNA::mydebug( "PASSED on filter: pos=", $self->pos );
    return 0;
}


sub filter_by_position_refseq {
    my ($self, $pos_ref, $blast_seq_length, $locuslink) = @_;
    
    my $file = $self->blasttxt;

    my $dbh = Database::connect_db("entrez_gene");
    open(FILE, $file) || SiRNA::myfatal( "can not open $file" );
    # NM_183380       17      1;2;4;5;6;7;8;9;10;11;12;13;14;15;18;19;20
    while(<FILE>) {
        chomp();
	my @arr = split(/\t/);
	my ($_acc, $_pos) = ($arr[0], $arr[2]);

	if ( has_more_position($pos_ref, $blast_seq_length, $_pos) ) { 
	      
	      if ($_acc =~ /NM/) {
		my $_locuslink = Database::get_locusid($dbh, $_acc);
		SiRNA::mydebug( "gene pos=", $self->pos, $locuslink, "compare with hit_acc=",  $_acc, $_locuslink );
		
		if ( $_locuslink &&
		     ! matching_anyId($locuslink,$_locuslink) ) {
		    Database::disconnect_db($dbh);
		      close(FILE);
		      
		      SiRNA::mydebug( "FAILED on filter: pos=", $self->pos, $_acc, "locuslink=", $_locuslink, $_pos );
		      return 1;
		  }
	    }
	}
    }
    Database::disconnect_db($dbh);
    close(FILE);
    SiRNA::mydebug( "PASSED on position filter: pos=", $self->pos );    
    return 0;	
}


sub filter_by_position_unigene {
    my ($self, $pos_ref, $blast_seq_length, $unigene_cluster) = @_;    
    my $file = $self->blasttxt;

    my $dbh = Database::connect_db("sirna2");
    open(FILE, $file) || SiRNA::myfatal( "can not open $file" );
    # NM_183380       17      1;2;4;5;6;7;8;9;10;11;12;13;14;15;18;19;20
    while(<FILE>) {
	my @arr = split(/\t/);
	my ($_acc, $_pos) = ($arr[0], $arr[2]);
	if ( has_more_position($pos_ref, $blast_seq_length, $_pos) ) {

	    my $_unigene_cluster = Database::get_unigeneCluster($dbh, $self->species, "uniq_unigene", $_acc);
	    SiRNA::mydebug( "gene pos=", $self->pos, $unigene_cluster, "compare with hit_acc=",  $_acc, $_unigene_cluster ); 
	    if ( $_unigene_cluster &&
		 ! matching_anyId($unigene_cluster,$_unigene_cluster) ) { 
		Database::disconnect_db($dbh);
		  close(FILE);
		  
		  SiRNA::mydebug( "FAILED on filter: pos=", $self->pos, $_acc, $_unigene_cluster, $_pos);  
		  return 1;
	      }
	}
    }
    Database::disconnect_db($dbh);
    close(FILE);
    SiRNA::mydebug( "PASSED on position filter: pos=", $self->pos );
    return 0;
}
	    
sub filter_by_position_ensembl {
    my ($self, $pos_ref, $blast_seq_length, $ensembl) = @_;    
    my $file = $self->blasttxt;

    my $dbh = Database::connect_db("sirna2");
    open(FILE, $file) || SiRNA::myfatal( "can not open $file" );
    # NM_183380       17      1;2;4;5;6;7;8;9;10;11;12;13;14;15;18;19;20
    while(<FILE>) {
	my @arr = split(/\t/);
	my ($_acc, $_pos) = ($arr[0], $arr[2]);
	if ( has_more_position($pos_ref, $blast_seq_length, $_pos) ) {
	    my $_ensembl = Database::get_ensemblGene($dbh, $self->species, "transcript_stable_id", $_acc);

	    SiRNA::mydebug( "gene pos=", $self->pos, $ensembl, "compare with hit_acc=",  $_acc, $_ensembl ); 
	    if ( $_ensembl &&
		 ! matching_anyId($ensembl,$_ensembl) ) { 
		Database::disconnect_db($dbh);
		  close(FILE);
		  
		  SiRNA::mydebug( "FAILED on filter: pos=", $self->pos, $_acc, $_ensembl, $_pos);  
		  return 1;
	      }
	}
    }
    Database::disconnect_db($dbh);
    close(FILE);
    SiRNA::mydebug( "PASSED on position filter: pos=", $self->pos );
    return 0;
    
}


# 1=more_position(filtered out); 
sub has_more_position {
    my ($pos_ref, $blast_seq_length, $_pos) = @_;
    my @position = split(/\;/, $_pos);

#SiRNA::mydebug( "pos_ref=", join';', @$pos_ref );
#SiRNA::mydebug( "this_pos=$_pos" );
    
    
#    foreach my $i (0 ..$#{$pos_ref} ) {  # $i=selected_position
    foreach my $i (1 ..$#{$pos_ref} ) {  # $i=selected_position
	if ($pos_ref->[$i]) {
#	  SiRNA::mydebug( "i=$i" );
	    my $find = 0;
	    for my $j (0..$#position) {
		$find = 1 if ($i eq $position[$j]);
#		SiRNA::mydebug( "i=$i, j=$j, pos=$position[$j], find=$find" );
		last if ($find);
	    }
#	    SiRNA::mydebug( "find=$find" );
	    return 0 if (! $find);
	}
    }
#    SiRNA::mydebug( "out=1" );
    return 1;
}


sub write_blast_html_txt {
    my $self = shift;
    my $html = $self->blasthtml;
    my $txt  = $self->blasttxt;
    
    open(BLAST, ">$html") || SiRNA::myfatal( "can't write to $html" );
    open(TXT, ">$txt") || SiRNA::myfatal( "can't write to $txt" );

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
	"<th>Target</th>",
	"<th>Description</th>",
	"<th>Identity</th>",
	"<th>Alignment(antisense:5'->3')</th>",
	"</tr>\n";
    
    foreach my $hsp (sort {$b->identity <=> $a->identity} @{ $self->hsps } ) {
	
	my ($link, $alignment);
	$alignment = $hsp->get_alignment();
	
	if ($self->database =~ /UNIGENE/i) {
	    if ($hsp->hit_acc =~ /([a-z]+)\#S([\d]+)$/i) {
		$link = '<a href=http://www.ncbi.nlm.nih.gov/UniGene/seq.cgi?ORG=' . $1 . '&SID=' . $2 . '>' . $hsp->hit_acc . '</a>';
	    }
	}
	# link in NCBI changed: Dec 2017, updated accordingly 
	#elsif ($self->database =~ /REFSEQ/i) {
	#    $link =  '<a href=http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=retrieve&db=Nucleotide&dopt=GenBank&dispmax=20&uid=' . $hsp->hit_gi . '>' . $hsp->hit_acc . '</a>';
	    
	#}
 	elsif ($self->database =~ /REFSEQ/i) {
            $link =  '<a href=http://www.ncbi.nlm.nih.gov/nuccore/' . $hsp->hit_acc . '>' . $hsp->hit_acc . '</a>';

        }

	elsif ($self->database =~ /ENSEMBL/i) {
	    if ($self->species =~ /HUMAN/i) {
		$link =  '<a href=http://www.ensembl.org/Homo_sapiens/transview?transcript=' . $hsp->hit_acc . '>' . $hsp->hit_acc . '</a>';
	    }
	    elsif ($self->species =~ /MOUSE/i) {
		$link =  '<a href=http://www.ensembl.org/Mus_musculus/transview?transcript=' . $hsp->hit_acc . '>' . $hsp->hit_acc . '</a>';
	    }
	    elsif ($self->species =~ /RAT/i) {
		$link =  '<a href=http://www.ensembl.org/Rattus_norvegicus/transview?transcript=' . $hsp->hit_acc . '>' . $hsp->hit_acc . '</a>';
	    }
	}
	
	# print to file
	print BLAST
	    "<tr>",
	    "<td>$link</td>",
	    "<td>",$hsp->hit_desc,"</td>",
	    "<td>",$hsp->identity,"</td>",
	    "<td>$alignment</td>",
	    "</tr>";
	print TXT
	    $hsp->hit_acc, "\t",
	    $hsp->identity, "\t",
	    matched_pos($hsp->query_inds, ";"), "\n";
    }

    print BLAST <<EOF
	</table>
	</body>
	</html>
EOF
;	

    close(BLAST);
    close(TXT);
}



sub matched_pos {
    my ($aref, $separator) = @_;
    my $string = join($separator, @$aref);
    return $string;
}



1;

