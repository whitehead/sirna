#! /usr/bin/perl -w

package CustomPattern;

use siRNA_log;
use Class::Struct;

struct CustomPattern => {
    custom => '$',      # user input pattern
    seq_pattern =>'$',  # revised_pattern: only bases
    seq_length => '$',  # length of the revised pattern(bases)
};


sub custom_check {
    my CustomPattern $self=shift;

    my $custom  = $self->custom;
    my $custom_length = 0;
    my $custom_revised = "";

    ### use IUB/IUPAC nucleic acid codes ### 
    $custom =~ s/N/\[ACTG\]/g;
    $custom =~ s/n/\[actg\]/g;

    $custom =~ s/R/\[AG\]/g;
    $custom =~ s/r/\[ag\]/g;

    $custom =~ s/Y/\[CT\]/g;
    $custom =~ s/y/\[ct\]/g;

    $custom =~ s/M/\[AC\]/g;
    $custom =~ s/m/\[ac\]/g;

    $custom =~ s/K/\[TG\]/g;
    $custom =~ s/k/\[tg\]/g;
    
    $custom =~ s/S/\[CG\]/g;
    $custom =~ s/s/\[cg\]/g;
    
    $custom =~ s/W/\[AT\]/g;
    $custom =~ s/w/\[at\]/g;
    
    $custom =~ s/H/\[ACT\]/g;
    $custom =~ s/h/\[act\]/g;

    $custom =~ s/B/\[CTG\]/g;
    $custom =~ s/b/\[ctg\]/g;
    
    $custom =~ s/v/\[acg\]/g;
    $custom =~ s/V/\[ACG\]/g;
    
    $custom =~ s/D/\[ATG\]/g;
    $custom =~ s/d/\[atg\]/g;

    ### replace u with t ###
    $custom =~ s/U/T/g;
    $custom =~ s/u/t/g;


    if ($custom =~ /^[ACTGN0-9\[\]]+$/i) {
	my @array = split(//, $custom);
	while(my $token = getToken(\@array)) {

	    my $token_length = 1;
	    if ($token =~ /([0-9]+)/) {
		$token_length = $1;
	    }

	    $custom_length += $token_length;

	    $token =~ s/([0-9]+)/{$1}/g;
	    $custom_revised .= $token;
	}
	if ($#array >= 0) {
	    $self->seq_length(0);
	    $self->seq_pattern($custom);
	}
    }
    $self->seq_length($custom_length);
    $self->seq_pattern($custom_revised);
}

sub getToken {
    my $arrayref = shift;
    my $token = "";
    my $expect = '[N';

    while (($#$arrayref >= 0) && ((my $chr = shift @$arrayref) ne '')) {	

	if ($expect eq '[N') {
	    if ($chr eq "[") {
		$token .= $chr;
		$expect = ']N';
	    }
	    elsif ($chr =~ /^[ACTG]$/i) {
		$token .= $chr;
		$expect = 'D';
	    }
	    else {
		$expect = '';
	    }
	}
	elsif ($expect eq ']N') {
	    if ($chr eq "]") {
		$token .= $chr;
		$expect = 'D';
	    }
	    elsif ($chr =~ /^[ACTG]$/i) {
		$token .= $chr;
	    }
	    else {
		$expect = '';
	    }
	}
	elsif ($expect eq 'D') {
	    if ($chr =~ /^[0-9]$/i) {
		$token .= $chr;
	    }
	    else {
		$expect = '';
	    }
	}
	elsif ($expect ne '') {

	}

	if ($expect eq '') {
#	    print "DEBUG: before unshift: ",@$arrayref,"\n";
	    unshift @$arrayref, $chr;
#	    print "DEBUG: after unshift: ",@$arrayref,"\n";
	    last;
	}

#	print "DEBUG: token: $token\n";
#	print "DEBUG: expect: <$expect>\n";
    }
    return $token;
}

1
