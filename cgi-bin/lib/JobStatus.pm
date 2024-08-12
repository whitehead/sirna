# purpose: check the status of job


package SiRNA;

use strict;
use File::Basename;
use siRNA_log;

our ($MySessionID, $MySessionIDSub, $DateDir);


# not done: 0
# finished: 1
sub job_status {

    # extract 6 from 2004-7-19-63401-10758_6
    my $number = get_number($MySessionIDSub);
    
    for ( my $i=0; $i< $number; $i++ ) {
	
	# argv file: 2004-7-19-36254-2606_2_argvs.txt
	my $_argv = $DateDir . "/" . $MySessionID . "_" . $i . "_argvs.txt";
	if (-e $_argv) {
	    # check status by "end" file: 2004-7-19-63401-10758_6.end
	    my $_end = $DateDir . "/" . $MySessionID . "_" . $i . ".end";
	    if (! -e $_end) {
		# not done
		return 0;
	    }
	}
    }
    return 1;
}


sub get_number {
    my $id = shift;
    
    # 2004-7-19-63401-10758_6
    if ($id =~ /\_(\d+)/) {
	return $1;
    }
    else {
	myfatal( "$id is not a subID" );
    }
}

1;
