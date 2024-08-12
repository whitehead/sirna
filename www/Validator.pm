# *************************************************************
# purpose: check user input informations
# *************************************************************


package Validator;

use strict;
use Class::Struct;
use Email::Valid;
use CustomPattern;
use siRNA_util;

struct Validator => map { $_ => '$' } qw(
					 sequence 
					 gene_id 
					 pattern 
					 custom_pattern 
					 ta_run_num 
					 g_run_num
					 base_variation_num 
					 polymorphism
					 boundary
					 ending
					 min_gc 
					 max_gc
					 sort
					 gc_run_max
					 emailstatus
					 emailaddress
					 custom_size
					 custom_seq
					 error
					 seq_file
					 );


sub validate_all {

    my Validator $self = shift;
    
    if (check_pattern() ) {
	if ( check_gc() ) {
	    
	}
    }


}

# ===========================
# check the user PATTERN
# ==========================
sub check_pattern {
    
    my Validator $self = shift;
    
    if ( ($self->pattern ne "AA") &&
	 ($self->pattern ne "NA") &&
	 ($self->pattern ne "PEI") &&
	 ($self->pattern ne "custom") ) {
	$self->error( "Please choose your pattern." );
	return 0;
    }
    elsif ($self->pattern eq "custom") {
	
	if ( (! $self->custom_pattern ) ||
	     ($self->custom_pattern =~ /^\s*//g) ) {
	    $self->error( "Please fill in your custom pattern." );
	    return 0;
	}
	else {
	    # ===================================== #
	    # change users pattern to perl language
	    # ===================================== #
	    my $custom_obj = CustomPattern->new(
						custom => $self->custom_pattern;
						);
	    $custom_obj->custom_check();
	    $self->custom_size($custom_obj->seq_length);
	    $self->custom_seq($custom_obj->seq_pattern);
	    
	    # only 23 bases
	    if ($self->custom_size != 23) {
		$self->error( "The length of the siRNA is between 19 to 29 bases.");
		return 0;
	    }
	}
    }
    return 1;
}

# =======================
# GC% and consecutive GC
# =======================
sub check_gc {
    my Validator $self = shift;
    
    # check GC percentage
    if ( (! check_digits($self->min_gc)) ||
	  (! check_digits($self->max_gc)) ) {
	$self->error( "Please input correct gc percentage." );
	return 0;
    }
    elsif ($self->min_gc >= $self->max_gc) {
	$self->error( "Please input correct gc percentage." );
	return 0;
    }
    # check consecutive GC
    if (! check_digits($self->gc_run_max)) {
	$self->error( "Please input correct consecutive gc number." );
	return 0;
    }
    return 1;

}

sub check_digits {

    my $num = shift;
    $num =~ s/\s+//g;
    if ($num !~ /^\d+$/) {
	return 0;
    }
    return 1;
}

# ===============
# validate email
# ===============
sub check_email {
    my Validator $self = shift;
    if ($self->emailstatus eq "Y") {
	if ( (! $self->emailaddress) || 
	     (! Email::Valid->address($self->emailaddress)) )  {
	    $self->error( "Please input correct e-mail address." );
	    return 0;
	}
    }
    return 1;
}
    
     
# =====================
# SEQUENCE information
# =====================
sub check_seq {
    my Validator $self = shift;
    my $sequence = $self->sequence;
    my $gene_id = $self->gene_id;

    if ($sequence =~ /^\s+$/) {
	$sequence = "";
    }
    if ($gene_id =~ /^\s+$/) {
	$gene_id = "";
    }
    
    if ($sequence eq "" ) {
	if ($gene_id eq "") {
	    $self->error( "Please input your sequence information." );
	    return 0;
	}
	else {
	    my $fasta = SiRNA::get_fasta_remote($gene_id);
	    (my $fasta_test, $seq) = check_fasta($fasta);
	    if ( $fasta_test == 0 ) {
		$self->error( "Your gene_id is not recognizable." );
		return 0;
	    }
	}
    }
    
    if ($sequence ne "") {
	if ($gene_id ne "") { # sequence > gene_id
	    $sequence = $sequence;
	    $gene_id = "";
	}
	(my $fasta_test, $seq) = check_fasta($sequence);
	if ( $fasta_test == 0 ) {
	    $self->error( "Please input your sequence in right format.");
	    return 0;
	}
	if (length($seq) > 150000) {
	    $self->error( "Your sequence size length($sequence) is too large.");
	    return 0;
	}
    }
    return 1;
}


# ===========================================
# save sequence in a file with fasta format
# @info = Sequence, fileName
# accept: bare sequence, and fasta sequence
# ===========================================

sub check_fasta {
    my $sequence = shift;
    my $head = "";
    my $base = "";
    my $head_line = -1;

    my @array = split(/\n/, $sequence);
    for (my $i = 0; $i <= $#array; $i++) {
        ### ignore empty line ###
        if ($array[$i] =~ /^\s*$/) {
            next;
        }
        ### ">" is consider defline ###
	if ($array[$i] =~ /^\s*(\>.*)/) {
	    $head = $1;
            $head_line = $i;
	}
        ### the bases: for fasta format, only include the line after ">" ###
	if ($i > $head_line) {
            $array[$i] =~ s/\s+//g;

	    # only certain letters allowed
	    if ($array[$i] =~ /[^atcgnukmrswybdhvACTGNUKMRSWYBDHV]/) {
		return (0, $base);
	    }
	    else {
		$base .= $array[$i];
	    }
	}
    }
    if ($base ne "") {
	$base =~ s/\s+//g;

        ### bare sequence defline is ">Unknown" ###
        $head = '>Unknown' if ($head_line == -1);

	### write sequence to $MyDataFasta ###
	printFastaToFile($MyDataFasta, $head, $base);

        ### RNA to DNA ###
	$base =~ s/U/T/g;
	$base =~ s/u/t/g;
	return (1, $base);
    }
    else {
	return (0, $base);
    }
}
