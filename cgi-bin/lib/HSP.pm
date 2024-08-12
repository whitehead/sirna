# this module is for storing all the blast hit information

package HSP;

use Class::Struct;
use strict;

struct HSP => {
    hit_acc       => '$',  # NM_006270/Hs#S19185843
    hit_name      => '$',
    hit_gi        => '$',
    hit_gb        => '$',
    identity      => '$',
    q_string      => '$',
    homo_string   => '$',
    hit_string    => '$',
    q_start       => '$',
    q_end         => '$',
    hit_start     => '$',
    hit_end       => '$',
    q_strand      => '$',
    hit_strand    => '$',
    hit_desc      => '$',
    query_inds    => '$', # array ref
};


# 1=more_position(filtered out); 
sub more_positions {
    my ($self, $pos_ref, $blast_seq_length) = @_;
    foreach my $i (0 ..$#{$pos_ref} ) {  # $i=selected_position
	if ($pos_ref->[$i]) {
	    my $find = 0;
	    for my $j (0..$#{$self->query_inds}) {
		$find = 1 if ($i eq $self->query_inds->[$j]);
	    }
	    return 0 if (! $find);
	}
    }
    return 1;
}

sub get_alignment {
    
    my $hsp = shift;

    my $alignment = "";
    if ( ($hsp->q_strand == 1) || ($hsp->q_strand == 0) ) {
	$alignment = 
	    sprintf(" %-6d%-20s%6d \n", 
		    $hsp->q_start,
		    $hsp->q_string,
		    $hsp->q_end);
    }
    else {
	$alignment = 
	    sprintf(" %-6d%-20s%6d \n", 
		    $hsp->q_end,
		    $hsp->q_string,
		    $hsp->q_start);
    }

    my $homo = $hsp->homo_string;
    $alignment .=       
        sprintf("%7s$homo\n", ' ');

    if ( ($hsp->hit_strand == 1) || ($hsp->hit_strand == 0) ){
	$alignment .= 
	    sprintf(" %-6d%-20s%6d \n",
		    $hsp->hit_start,
		    $hsp->hit_string,
		    $hsp->hit_end);
    }
    else {
	$alignment .= 
	    sprintf(" %-6d%-20s%6d \n", 
		    $hsp->hit_end,
		    $hsp->hit_string,
		    $hsp->hit_start);
    }
    
    # make alignment looks nice
    $alignment = '<pre><font face="courier, courier new">' . $alignment . '</font></pre>';
    
    return $alignment;

}



1;

	
