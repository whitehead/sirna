# cgi-bin directory from siRNA selection program (Whitehead Institute)

#### Make /cgi-bin/siRNAext directory, and copy all files below it. 

#### Selected contents that may need configuration, by directory:

### /cgi-bin/lib/ - location of scripts to run analyses (which can be changed to match your path)


Database.pm:

	$host = 'mysqlHost';
	
	$DBUser = 'mysqlLogin';
	
	$DBPassword = 'mysqlPassword';

siRNA_env.pm
	

siRNA_log.conf:

	log4j.appender.FILE.filename=/www/siRNAext/tmp/siRNA.log

siRNA_step2.cgi:

	! /usr/bin/perl -w -I/cgi-bin/siRNAext/lib/

	chdir "yourPath/siRNAext/lib";
	
	# replace admin\@domain.com

	From: admin\@domain.com
	
	Reply-To: admin\@domain.com
	
siRNA_util.pm:

	mailto:admin\@domain.com\
	
	
### /cgi-bin/db  - BLAST formatted sequence databases plus files for calculating thermodynamic values


Due to the size limitation, only the top 10 lines of fasta sequences are stored in the files.

You can download full sets from the public databases with the scripts under bin folder:

  REFSEQ,  ENSEMBL for human, mouse and rat sequence data

  Modify for your environment the following scripts to generate blastable files:

  download_refseq.sh: download RefSeq sequences

  download_ensembl.sh: download and format Ensembl sequences
  


### /cgi-bin/mysqldb -files for mysql databases

xrefs for databases and put them into a mysql database named sirna2:

entrez_gene.sql: can be downloaded from ftp://ftp.ncbi.nlm.nih.gov/gene

sirna.sql: mysql defs for user database

sirna2.sql: mysql defs for xref databases: link geneId with isoforms
