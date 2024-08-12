# www directory from siRNA selection program (Whitehead Institute)

#### Make /www/siRNAext directory, and copy all files below it.

### Selected contents that may need configuration:

siRNA_env.pm:

siRNA_log.conf:

	log4j.appender.FILE.filename=/var/www/siRNAext/tmp/siRNA.log

post_sirna.cgi:

	#!/usr/local/bin/perl -w -I./  -I/cgi-bin/siRNAext/lib/

   
**Change mysql login (mysqlHost, mysqlLogin, mysqlPassword) in**

  authenticate.php
  
  home.php
  
  register.php
  
  Check.pm
  
  Database.pm
  
  
### Change admin email in these files: ###
 
Check.pm

	From: admin\@domain.com
	
	To: admin\@domain.com
	
	Reply-To: admin\@domain.com
	

siRNA.cgi: 

	admin\@domain.com
	
GenbankAcc.pm:

    my $esearch = "$utils/efetch.fcgi?db=nucleotide&id=$acc&rettype=fasta&email=admin\@domain.com";
    
GenbankGI.pm:

      "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$gi&rettype=fasta&retmode=text&email=admin\@domain.com";
      
siRNA_util.pm:

	please contact <a href=\"mailto:admin\@domain.com\">siRNA-help</a> for help

register.php

	please contact admin@domain.com

	Reply-To: admin@domain.com


### Make symbolic links:


**Link to /cgi-bin/ folders:**

    ln -s /cgi-bin/siRNAext/lib/Attribute

    ln -s /cgi-bin/siRNAext/lib/Email/

    ln -s /cgi-bin/siRNAext/lib/Database.pm

    ln -s /cgi-bin/siRNAext/lib/File

    ln -s /cgi-bin/siRNAext/lib/JobStatus.pm

    ln -s /cgi-bin/siRNAext/lib/Log

    ln -s /cgi-bin/siRNAext/lib/Mail

    ln -s /cgi-bin/siRNAext/lib/Params

    ln -s /cgi-bin/siRNAext/lib/Sort.pm

**Link home.php with index.php**

    ln -s  home.php index.php


### Create tmp directory to store files for each search

    mkdir tmp

