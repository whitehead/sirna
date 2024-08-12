
# this module is for finding all refseq with the conserved 7mer
# it accepts a seq string
# and report the array of the target refseqs

package Seed;

use Class::Struct;
use Database;
use siRNA_log;

struct Seed => {
    seed       => '$',         # position 2-8 of guide strand(antisense strand)
    gene_id    => '$',         # one of target gene_id
    gene_count => '$',         # number of target genes
    ratio      => '$'          # the number of seed that gene_count is less than it /total number of seeds
	      
};



###################################
# get all the refseq with the seed
###################################
sub get_target {
  
  my Seed $self = shift;
  
  my $seed= $self->seed;
  
  my $dbh = Database::connect_db("sirna");
  my ($gene_id, $gene_count, $ratio) = Database::get7merTarget($dbh,$seed);
  Database::disconnect_db($dbh);
  
  SiRNA::mydebug( "seed=$seed, gene_id=$gene_id, gene_count=$gene_count, ratio=$ratio"); 
  
  $self->gene_id($gene_id);
  $self->gene_count($gene_count);
  $self->ratio($ratio);
  

}
  

1
  
