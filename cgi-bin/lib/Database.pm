# talk to mysql server



package Database;


use DBI;
use strict;
use siRNA_log;
use Sys::Hostname;


my ($host, $DBUser, $DBPassword);
my $hostname = hostname();
$host = 'mysqlHost'; 
$DBUser = "mysqlLogin";
$DBPassword = "mysqlPassword";



sub connect_db {
    
    my $DataBaseName = shift;
    my $dbh = DBI->connect("dbi:mysql:$DataBaseName:$host", "$DBUser", "$DBPassword", {
        printError => 0,
        RaiseError =>0
        }) or SiRNA::myfatal("$DBUser can't connect to database $DataBaseName on $host from $hostname");
    
    return $dbh;
    
}


sub get_locusid {
    my ($dbh, $acc) = @_;
    my ($acc2, $query, $sth, $locuslink);
    
    $acc2 = rm_version($acc);
   
	my $tbls = "gene2refseq gene2accession";

	my @tables = split / /, $tbls; 
    # ===================================================== #
    # 3 tables needed for acc: evid_set, refseq_set, accnum
    # ===================================================== #
    #my @tables = ( [ "gene2refseq" ],	[ "gene2accession"],);
    
    for my $i ( 0..$#tables) { 
	$query = qq ( select distinct gene_id from $tables[$i] where RNA_nuc_access_version like ?);
	SiRNA::mydebug( $query );

	
	$sth = $dbh -> prepare($query) || SiRNA::myfatal( "can't prepare select locusid for $acc2" );

	$sth -> bind_param(1, "$acc%");
	
	$sth->execute() || SiRNA::myfatal( "can't execute select locusid for $acc2" );

	$locuslink = $sth->fetchrow_array();
	
	if ($locuslink) {
	    $sth->finish() || SiRNA::myfatal( "can't finish select locusid for $acc2" );
 	    SiRNA::mydebug("%%%%%%%%%% acc=$acc, locuslink=$locuslink");
	    return $locuslink;
	}
    }
    
    $sth->finish() || SiRNA::myfatal( "can't finish select locusid for $acc2" );
    SiRNA::mydebug("%%%%%%%%%% acc=$acc, locuslink=$locuslink");
    return $locuslink;
    
}



sub get_unigeneCluster {
    my ($dbh, $species, $field, $id) = @_;
    my ($query, $sth, $table, $cluster);
    
    if ($species =~ /HUMAN/i) {
	$table = "hsUnigene";
    }
    elsif ($species =~ /MOUSE/i) {
	$table = "mmUnigene";
    }
    elsif ($species =~ /RAT/i) {
	$table = "rnUnigene";
    }
    
    $query = qq (
	select cluster from $table where $field like "$id"
	);
    
#    SiRNA::mydebug( $query );
    
    $sth = $dbh -> prepare ($query) || SiRNA::myfatal( "can't prepare select unigene cluster $id" );
    
    $sth->execute() || SiRNA::myfatal( "can't execute select unigene cluster $id" );
    
    $cluster = $sth->fetchrow_array();

    $sth->finish() || SiRNA::myfatal( "can't finish select unigene cluster $id" );

    return  $cluster;
    
}


sub get_ensemblGene {

    my ($dbh, $species, $field, $id) = @_;
    my ($query, $sth, $table);
    my @array = ();
    my $ensembl = "";
    my $id2 = rm_version($id);


    
    if ($species =~ /HUMAN/i) {
	$table = "ensembl_hs";
    }
    elsif ($species =~ /MOUSE/i) {
	$table = "ensembl_mm";
    }
    elsif ($species =~ /RAT/i) {
	$table = "ensembl_rat";
    }
    

    $query = qq (
	select distinct gene_stable_id from $table where ? like ?;
	);
    
    SiRNA::mydebug( $query );
    
    $sth = $dbh -> prepare ($query) || SiRNA::myfatal( "can't prepare select ensembl $id2" );
	
	$sth -> bind_param (1, $field);
	$sth -> bind_param (2, $id2);
    
    $sth->execute() || SiRNA::myfatal( "can't execute select ensembl $id2" );
    
    while ( my $_ensembl = $sth->fetchrow_array() ) {
	$ensembl .= "$_ensembl;";
    }
    $sth->finish() || SiRNA::myfatal( "can't finish select ensembl $id2" );
    
    # remove the last ";"
    chop($ensembl) if ($ensembl);

    return  $ensembl;
}

sub get_snp {
  my ($dbh, $acc, $start, $end) = @_;
  my ($query, $sth);
  my @snp = ();
  
  $query = qq (
	       SELECT distinct refsnp from snp where mRNA like "$acc" and pos >= $start and pos <= $end
		 );
  SiRNA::mydebug( $query );
  $sth = $dbh -> prepare ($query) || SiRNA::myfatal( "can't prepare $query"); 
  $sth->execute() || SiRNA::myfatal( "can't execute $query" );
  
  while ( my $_snp = $sth->fetchrow_array() ) {
    if ($_snp) {
      push @snp, $_snp;
    }
  }
  $sth->finish() || SiRNA::myfatal( "can't finish  $query" );

  return \@snp;

}

sub get_snp_all {
  my ($dbh, $acc, $version) = @_;
  my ($query, $sth);
  my @snp = ();
  
  if ($version) {

    $query = qq (
	       SELECT refsnp, pos from snp where mRNA like "$acc" and version=$version
		 );
  }
  else {
    $query = qq (
	       SELECT refsnp, pos from snp where mRNA like "$acc"
		 );
  }
  
  SiRNA::mydebug( $query );
  $sth = $dbh -> prepare ($query) || SiRNA::myfatal( "can't prepare $query"); 
  $sth->execute() || SiRNA::myfatal( "can't execute $query" );
  
  while ( my ($_snp, $_pos) = $sth->fetchrow_array() ) {
    if ($_snp) {
      push @snp, [ $_snp, $_pos ];
      SiRNA::mydebug("$_snp, $_pos");
    }
  }
  $sth->finish() || SiRNA::myfatal( "can't finish  $query" );

  return \@snp;

}

sub disconnect_db {

    my $dbh = shift;

    $dbh->disconnect()
        or SiRNA::myfatal( "can't disconnect to database" );

}


sub rm_version {
    my $acc = shift;
    if ($acc =~ /(.*)\.(\d+)/) {
	return $1;
    }
    else {
	return $acc;
    }
}

sub get7merTarget {
  
  my ($dbh, $mer7) = @_;

  #my @target = ();
  my ($query, $sth);

  $query = qq (
		  SELECT gene_id, mir2geneID, ratio FROM conserved_7mer_targets where mir_family_id like "$mer7" limit 1
		 );

  SiRNA::mydebug( $query );
  $sth = $dbh -> prepare ($query) || SiRNA::myfatal( "can't prepare $query"); 
  $sth->execute() || SiRNA::myfatal( "can't execute $query" );

  my ($gene_id, $gene_count, $ratio) = $sth->fetchrow_array();
  SiRNA::mydebug( "seed=$mer7, gene_id=$gene_id, gene_count=$gene_count, ratio=$ratio");


   $sth->finish() || SiRNA::myfatal( "can't finish  $query" );
  

  # set to 0 if not exist in database
  if (! $gene_count) {
    $gene_count = 0;
    $gene_id = 0;
    $ratio = 0;
  }
  return ($gene_id, $gene_count, $ratio);
}


sub get7merGenes {
  
  my ($dbh, $mer7) = @_;

  my @genes = ();
  my ($query, $sth);
  
  $query = qq (
		  SELECT distinct c.gene_id, e.symbol, e.description FROM conserved_7mer_targets c, entrez_gene.gene_info as e where mir_family_id like "$mer7" and c.gene_id=e.gene_id
		 );
  
  SiRNA::mydebug( $query );
  $sth = $dbh -> prepare ($query) || SiRNA::myfatal( "can't prepare $query"); 
  $sth->execute() || SiRNA::myfatal( "can't execute $query" );
  
  SiRNA::mydebug( "seed=$mer7, retrieve all target gene id");

  while ( my ($gene, $symbol, $desc) = $sth->fetchrow_array() ) {
    if ($gene) {
      push @genes, [ $gene, $symbol, $desc ];
    }
  }
  $sth->finish() || SiRNA::myfatal( "can't finish  $query" );
  
  return (\@genes);
  
}


1;
