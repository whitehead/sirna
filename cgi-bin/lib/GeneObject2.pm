 
#################################################################
# Copyright(c) 2003 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     4/11/2003
# updated:     7/18/2004
#################################################################
 
package GeneObject2;


# this data object class hold data for each acc_id
 
use strict;
use Class::Struct;
use Database;
 
struct GeneObject2 => {
    seq                       => '$',
    acc                       => '$',           # acc only if user input seq in acc/gi format
    gi                        => '$',           # gi only if user input seq in acc/gi format
    locuslink                 => '$',           # 32163
    unigene_cluster           => '$',           # Unigene Cluster
    ensembl                   => '$',           # Ensembl ID
    seq_file                  => '$',           # original seq file path
    alignment_file            => '$',           # the alignment between this gene and representative unigene_seq
    alignment_warning         => '$',           # 1: if the query sequences is not 100% aligned with database seq
    no_sirna_reason           => '$',           # why there is no sirna candidate for the gene
    blastn_id                 => '$',           # blastn file id: digits
    sirnas                    => '@',           # sirna objects
};


sub addSiRNA {
    my $self = shift;
    my $sirna = shift;
    push @{ $self->sirnas }, $sirna;
}

sub deleteSiRNA {
    my $self = shift;
    my $sirna = shift;
    for my $i(0..$#{ $self->sirnas } ) {
	if ($self->sirnas->[$i] eq $sirna) {
	    splice(@{ $self->sirnas }, $i, 1);
	}
    }
}

sub getLocuslink {
    my $self = shift;
    my $acc  = shift;
    
    my $dbh = Database::connect_db("entrez_gene");
    my $locuslink = Database::get_locusid($dbh, $acc);
#    SiRNA::mydebug( "%%%%%%%%%%% acc=", $acc, "locuslink=", $locuslink );
    Database::disconnect_db($dbh);
   
    return $locuslink;
}

sub get_unigeneCluster {
    my ($self, $species, $acc) = @_;
    
    my $dbh = Database::connect_db("sirna2");
    my $unigeneCluster = Database::get_unigeneCluster($dbh, $species, "acc", $acc);
    Database::disconnect_db($dbh);
    
    return $unigeneCluster;
}

sub getEnsemblGene {
    my ($self, $species, $acc) = @_;
    
    # only map RefSeq with NM_
    if ($acc =~ /^NM\_/i) {
	my $dbh = Database::connect_db("sirna2");
	my $_ensembl = Database::get_ensemblGene($dbh, $species, "dbprimary_id", $acc);
	Database::disconnect_db($dbh);
	
	return $_ensembl;  # ENSG00000187981;ENSG00000187908
    }
    else {
	return "";
    }
}

sub numOfSiRNAs {
    my $self = shift;
    my $count = 0;
    foreach my $sirna ( @{ $self->sirnas } ) {
	if ( (! defined $sirna->failure_reason) ||
	     (! $sirna->failure_reason) ) {
	    $count ++;
	}
    }
    return $count;
}

1;
