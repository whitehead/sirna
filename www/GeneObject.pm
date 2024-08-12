 
#################################################################
# Copyright(c) 2003 Whitehead Institute for Biomedical Research.
#              All Right Reserve
#
# Created:     4/11/2003
# revised:     6/28/2004
#################################################################
 
use strict;

# this data object class hold data for each acc_id
 
package GeneObject;
 
use Class::Struct;

struct GeneObject => {
    genbank                   => '$',           # genbank flat file content
    gi                        => '$',
    acc                       => '$',           # used for getting locuslink number
    seq                       => '$',
    code_region               => '$',
    gene_id                   => '$',           # locuslink number or ensembl genename
    no_sirna_reason           => '$',           # why there is no sirna candidate for the gene
    sirnas                    => '%',           # sirna objects key=pos
    total_mers                => '$',           # total number of candidates before any filter
    bad_base_count            => '$',
    bad_pattern_count         => '$',
    bad_g_run_count           => '$',           # count bad g_run count
    bad_ta_run_count          => '$',           # count bad t_run or a_run 
    bad_gc_percent_count      => '$',
    bad_gc_series_count       => '$',
    base_variation_count      => '$',
    snp_count                 => '$',
    palindrome_count          => '$',
    boundary_count            => '$',
    snp_info                  => '$',           # reference to all snp: each record: snp_id pos 
};

sub addSiRNA {
    my $self = shift;
    my $sirna = shift;
    my $key = $sirna->pos;
    $self->sirnas->{$key} = $sirna;
}

sub deleteSiRNA {
    my $self = shift;
    my $sirna = shift;
    my $key = $sirna->pos;
    delete($self->sirnas->{$key});
}

sub getSiRNA {
    my $self = shift;
    my $pos = shift;
    my $key = $pos;
    return $self->sirnas->{$key};
}

sub getSiRNA2 {
    my $self = shift;
    my $key = shift;
    return $self->sirnas->{$key};
}

sub numOfSiRNAs {
    my $self = shift;
    my @ks = keys %{$self->sirnas};
    return $#ks + 1;
}

1;
