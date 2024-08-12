#! /usr/local/bin/perl -w

package Check;
use DBI;
use Time::Local;

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { @_ , PID => 0 };
    bless($self, $class);
    return $self;
}

sub redirectToLoginPage {
    my Check $self = shift;
    my $loginUrl = shift;
    print <<EOF;
<html>
<head>
<meta http-equiv="refresh" content="0; URL=$loginUrl">
</head>
<body>
<H2>Redirecting to your page ... Please wait while I am transferring for you...</H2>
<h3>P.S. If you do not see a new page after a few seconds, you can click <a href="$loginUrl">here</a></h3>

<img src="keep/animation.gif" />
</body>
</html>
EOF
}

my $DataBaseName = "sirna";
my $hostname = "mysqlHost";
my $DBUser = "mysqlLogin";
my $DBPassword = "mysqlPassword";

###Check if UserSession is valid, return 0 if invalid, otherwise return 1

sub dbh_connection
{
    my $dbh = DBI->connect("dbi:mysql:$DataBaseName:$hostname", "$DBUser", "$DBPassword",
			   {
			       printError => 0,
			       RaiseError => 0 } )
	or die "Can't connect to database: $DBI::errstr\n";
    
    return $dbh;
}

sub dbh_disconnect
{
    my Check $self = shift;
    my $dbh = shift;
    $dbh->disconnect
	or warn "Error disconnecting: $DBI::errstr\n";
}


sub checkUserSession
{
    my Check $self = shift;
    my $dbh = shift;
    my $user_pid = shift;
    my $user_auth_id = 0;
    my $sEmail = "";
    
    if ( defined $user_pid ) {
	
	my $sth = $dbh->prepare( "SELECT pId from logins where rId=?;" )
	    or die "can't execute SQL statement: $DBI::errstr\n";
	
	$sth->bind_param(1, $user_pid);
	$sth->execute
	    or die "can't execute SQL statment: $DBI::errstr\n";
	
	if ($sth->rows == 0) {
	    #	print "no such pid\n";
	}
	
	else  {
	    if ($sth->rows > 1) {
		# send mail to datbase admin##
		$sEmail = "pid $user_pid is redundent in siRNA database\n";
		$user_auth_id = 100000;
	    }
	    else {
		$self->{PID} = $sth->fetchrow;
		$user_auth_id = $self->{PID};
	    }
	}
	$sth->finish;
    }
    return $user_auth_id;
}


sub get_email {
    
    my Check $self = shift;
    my $dbh = shift;
    my $user_auth_id = shift;
    my $email = "";

    my $sth = $dbh->prepare( "SELECT email from emails where pId=$user_auth_id;" )
	or die "can't execute SQL statement: $DBI::errstr\n";

    $sth->execute
	or die "can't execute SQL statment: $DBI::errstr\n";

    
    if ($sth->rows == 0) {
	$sEmail = "Strange: no email for $user_auth_id in the emails table\n";	
    }
    
    else  {
	if ($sth->rows > 1) {
	    # send mail to datbase admin##
	    $sEmail = "$user_auth_id is duplicated in the emails table\n";
	}
	else {
#	    $self->{EMAIL} = $sth->fetchrow;
#	    $email = $self->{EMAIL};
	    $email = $sth->fetchrow;
	    
	}
    }
    
    return $email;
}


sub deleteRid
{
    my Check $self=shift;
    my $dbh = shift;
    my $user_pid = shift;

    if (defined $user_pid) {
	
	my $sth = $dbh->prepare( "DELETE from logins where rId=?;" )
	    or warn "can't execute SQL statement: $DBI::errstr\n";
	$sth->bind_param(1, $user_pid);
	
	$sth->execute
	    or warn "can't execute SQL statment: $DBI::errstr\n";
	
	$sth->finish;

    }
}

sub updateCount
{
    my Check $self=shift;
    my $dbh = shift;
    my $user_pid = shift;
    my $db_email = shift;
 
    my $sth = $dbh->prepare( "SELECT * from counts where counts.pId=$self->{PID};" )
	or warn "can't execute SQL statement: $DBI::errstr\n";
	
    $sth->execute
	or warn "can't execute SQL statment: $DBI::errstr\n";
    	
    ### get the date ###
    my ($day, $month, $year) = (localtime)[3,4,5];
    my $RealMonth = $month + 1;
    my $RealYear = $year + 1900;
    
    ### insert if no pId in the table ###
    if ($sth->rows == 0) {
	$dbh->prepare( "INSERT INTO counts VALUES($self->{PID}, $day, $RealMonth, $RealYear, 1);" )
	    or warn "can't execute SQL statement: $DBI::errstr\n";
    }
    else {     ### update if pId exist ###
	my @info = $sth->fetchrow_array();

	if ( ($info[1] == $day) && ($info[2] == $RealMonth) && ($info[3] == $RealYear) ) { #same day
	    
	    # max usage=25; # special permission: Need to change yourVIP\.com
	    if ( $info[4] > 25 &&
		 lc($db_email) !~ /yourVIP\.com/) {
		return 0;
	    }
	    else {
		$sth = $dbh->prepare( "UPDATE counts SET count=count+1 where pId=$self->{PID};")
		    or warn "can't execute SQL statement: $DBI::errstr\n";
		$sth->execute
		    or warn "can't execute SQL statment: $DBI::errstr\n";
	    }
	}
	else {
#	    print "PID=$self->{PID} day=$day, month=$RealMonth, year=$RealYear<br>";
	    $sth = $dbh->prepare( "UPDATE counts SET day=$day, month=$RealMonth, year=$RealYear, count=1 where pId=$self->{PID};")
		or warn "can't execute SQL statement: $DBI::errstr\n";
	    $sth->execute
		or warn "can't execute SQL statment: $DBI::errstr\n";
	}
    }
    $sth->finish;

    return 1;
}
    
sub send_mail {
    my $sEmail = shift;
    open MAIL, "| /usr/lib/sendmail -t -i" or warn "cannot open sendmail";

print MAIL <<EOF;
From: admin\@domain.com
To: admin\@domain.com
Reply-To: admin\@domain.com
Subject: pid problem 
$sEmail
EOF

    close MAIL or warn "cannot close sendmail";
}


1;
