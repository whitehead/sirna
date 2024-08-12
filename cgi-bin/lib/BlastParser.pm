# this module is for parsing blast result


package BlastParser;

use Class::Struct;
use Bio::SearchIO;
use CGI;
use siRNA_log;
use GeneObject2;
use SiRNAObject;
use HSP;
use strict;
use Database;

struct BlastParser => {
    blast_out_file               => '$',      # blast out file
    sirna_obj                    => '$',      # one siRNA object
    gene_obj                     => '$',      # one gene obj
    blast_seq_start_pos          => '$'       # start position of blast seq 2(guide strand 2-9)
};

sub parse_blast {
    my BlastParser $self = shift;
    my $blast_out_file = $self->blast_out_file;

    open (FILEH, $blast_out_file) || SiRNA::myfatal( "Can't open ", $blast_out_file );

    my $in = new Bio::SearchIO(-format => "blast",
			       -fh     =>\*FILEH
			       );

    # ===============
    # looping SIRNAS
    # ===============

    SiRNA::mydebug( "===============PARSE BLAST Result 0========================================");    

    while( my $result = $in->next_result ) {
	SiRNA::mydebug( "===============PARSE BLAST Result ========================================");
	
    	SiRNA::mydebug( "start blast result", $in);
	my @hsps = ();
	
	# =============
	# looping HITS
	# =============
	while( my $hit = $result->next_hit ) {
	    
	    last if ($self->sirna_obj->failure_reason);
	    
	    # =============
	    # looping HSPs
	    # =============
	    while( my $hsp = $hit->next_hsp ) {
		my ($iden, $hsp_object);
		
		
		# delete the hit with equal or less 12 identity
		if ($hsp->num_identical() <= 12) {
		    next;
		}
#		SiRNA::mydebug("acc=", $hit->accession(), ", name=", $hit->name(), ", desc=", $hit->description, ", locus=", $hit->locus() );

		# Refseq
		# acc= NM_006270 , name= gi|20127497|ref|NM_006270.2| , desc= Homo sapiens related RAS viral (r-ras) oncogene homolog (RRAS), mRNA , locus=
		# UniGene
		# acc= Hs#S19185843 , name= gnl|UG|Hs#S19185843 , desc= Homo sapiens N-acetyltransferase 2 (arylamine N-acetyltransferase), mRNA (cDNA clone MGC:71963 IMAGE:4722596), complete cds /cds=(105,977) /gb=BC067218 /gi=45501306 /ug=Hs.2 /len=1344 , locus= 
		# Ensembl
		# acc= ENST00000337809 , name= gnl|ensembl|ENST00000337809 , desc= Oxysterol binding protein-related protein 9 (OSBP-related protein 9) (ORP-9). [Source:SWISSPROT;Acc:Q96SU4] cdna:known chromosome:NCBI34:1:51452682:51624054:1 gene:ENSG00000117859 , locus=

		my @a = $hsp->seq_inds('query');

		$hsp_object = HSP->new(
				       hit_acc       => $hit->accession(),       # NM_006270/Hs#S19185843/ENST00000337809
				       identity      => $hsp->num_identical(), 
				       q_string      => $hsp->query_string,
				       homo_string   => $hsp->homology_string,
				       hit_string    => $hsp->hit_string,
				       q_start       => $hsp->start('query') -1 + $self->blast_seq_start_pos,
				       q_end         => $hsp->end('query')   -1 + $self->blast_seq_start_pos,
				       hit_start     => $hsp->start('hit'),
				       hit_end       => $hsp->end('hit'),
				       q_strand      => $hsp->strand('query'),
				       hit_strand    => $hsp->strand('hit'),
				       hit_gi        => getGI($hit->name(), $hit->description, $self->sirna_obj->database),
				       hit_desc      => $hit->description(),
				       query_inds    => \@a
				       );
#	      SiRNA::mydebug("*******hit_name=", $hit->name(), "database=", $self->sirna_obj->database); 
#	      SiRNA::mydebug("identical=", $hsp->num_identical(), "conserved=", $hsp->num_conserved(), "seq_str=", $hsp->seq_str('query'),  "seq_inds=", $hsp->seq_inds('query', 'identical'), "gap=", $hsp->gaps('query') );
		push @hsps, $hsp_object;
		
	    }
	}
	
	if ($#hsps < 0 ) {
	    $self->sirna_obj->failure_reason( "all the hits have less than 12 bases in all the alignments." );
	    SiRNA::mydebug( "all the hits have less than 12 bases in the alignment" );
#	   SiRNA::mydebug("hsps<0, so out"); 
	}
	else {
#	    SiRNA::mydebug("hsps>0, so keep it"); 
	    foreach my $hsp_obj (@hsps) {
		$self->sirna_obj->addHsp($hsp_obj);
	    }
	}
	
    }
    close(FILEH);
}

sub getGI {
    my ($id, $desc, $db) = @_;
    if ($db =~ /REFSEQ/i) {
	if ($id =~ /gi\|(\d+)?\|/) {
#	    SiRNA::mydebug( "id=$id, gi=$1");
	    return $1;
	}
    }
    elsif ($db =~ /UNIGENE/i) {
	if ($desc =~ /\/gi\=(\d+?)\s+/) {
#	    SiRNA::mydebug( "id=$id, gi=$1");
	    return $1;
	}
    }
    elsif ($db =~ /ENSEMBL/i) {
	return "";
    }
    else {
	return "";
	}
	# change/remove fatal error becuase header lines in NCBi changes Dec2018
	#SiRNA::myfatal( "can not get gi from $id." );
}


sub getTargetLink {

    my ($blast, $db, $target) = @_;
    my $gi = 0;
    my $acc = "";
    
    
    if ($db =~ /REFSEQ/i) {
	if ( $blast =~ /WU|NCBI/i ) {
	    if ($target =~ /gi\|(\d+)\|ref\|(.*)\|/) {
		($gi, $acc) = ($1, $2);
	    }
	}
    }
    
    elsif ($db =~ /UNIGENE/i) {
	if ( $blast =~ /WU|NCBI/i ) {
	    

	}
    }
}


1;
