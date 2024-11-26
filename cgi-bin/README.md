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

You can create databases by loading .sql files using the following command:

	mysql -u username -p < /path/to/your_file.sql
 
**.sql Files:**

entrez_gene.sql: Creates the entrez_gene database. This file can be downloaded from NCBI's FTP site: ftp://ftp.ncbi.nlm.nih.gov/gene

sirna.sql: Defines MySQL structure for the sirna user database, which you can create by loading this file.

sirna2.sql: Provides MySQL definitions for the xref database, linking geneId with isoforms. This file is used to create the sirna2 database.
