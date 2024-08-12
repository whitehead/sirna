# siRNA selection program from the Whitehead Institute

This repo contains the key files from the siRNA selection program at https://sirna.wi.mit.edu/

 

### The webserver requires

- PHP (and the mysql API)
- JavaScript
- Perl (including BioPerl, log4perl, Email:Valid and the mysql API)
- MySQL
- NCBI BLAST executable 'blastall'
- mysql php API
- mysql perl API

### We adopted this Apache directory structure:

- *www/* as the document root and some executable scripts
- *cgi-bin/* for the main executable scripts

### Note: you need to create a siRNAext directory under www/ and cgi-bin/, and copy the github files under the corresponding siRNAext sub-folder. 

