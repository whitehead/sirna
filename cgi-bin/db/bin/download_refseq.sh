#update siRNA databases on server
# Sanjeev Pillai

set echo on

DB="/yourPath/siRNAext/db";
LOG="/yourPath/siRNAext/new_cron/log";
DOWNLOAD="/yourPath/siRNAext/new_cron/download";


cd ${DOWNLOAD}

echo "Current dir = `pwd`";
echo "Getting refseq from ftp.ncbi.nih.gov ..."
date

wget --append-output=refseq-wget-log.txt --passive-ftp -O - 'ftp://ftp.ncbi.nih.gov/refseq/H_sapiens/mRNA_Prot/human.rna.fna.gz' | gzip -cd > hs.fna 
sleep 10
wget --append-output=refseq-wget-log.txt --passive-ftp -O - 'ftp://ftp.ncbi.nih.gov/refseq/M_musculus/mRNA_Prot/mouse.rna.fna.gz' | gzip -cd > mouse.fna
sleep 10
wget --append-output=refseq-wget-log.txt --passive-ftp -O - 'ftp://ftp.ncbi.nih.gov/refseq/R_norvegicus/mRNA_Prot/rat.rna.fna.gz' | gzip -cd > rn.fna

echo "the recent downloaded database: "
ls -ltr |tail

echo "formatting the database for NCBI blast ..."

set today = `date`
/usr/bin/formatdb -p F -t "human refseq.na $today" -o T -i hs.fna    > ${LOG}/refseq.log  2>&1
/usr/bin/formatdb -p F -t "mouse refseq.na $today" -o T -i mouse.fna > ${LOG}/refseq.log 2>&1
/usr/bin/formatdb -p F -t "rat refseq.na $today"   -o T -i rn.fna    > ${LOG}/refseq.log  2>&1

/usr/local/bin/xdformat -n -t "human refseq.na $today" hs.fna   > ${LOG}/refseq.log  2>&1
/usr/local/bin/xdformat -n -t "mouse refseq.na $today" mouse.fna > ${LOG}/refseq.log  2>&1
/usr/local/bin/xdformat -n -t "rat refseq.na $today"   rn.fna   > ${LOG}/refseq.log  2>&1

cat formatdb.log >> ${LOG}/refseq.log
rm -f formatdb.log

test -s hs.fna.nhr && test -s mouse.fna.nhr && test -s rn.fna.nhr 


if [ $? = 0 ]
then
    
    echo "formated databases: "
    ls -ltr

    echo "moving foramted files into place ..."

    mv hs.fna*  $DB  
    mv mouse.fna* $DB
    mv rn.fna*   $DB

    mail -s "refseq blast db has been updated" admin@domain.com < ${LOG}/refseq.log 
    
else
    mail -s "refseq update error" admin@domain.com < ${LOG}/refseq.log

fi
