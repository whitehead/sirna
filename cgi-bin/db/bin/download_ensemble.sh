#!/bin/sh
# ===============================================================
# Sanjeev Pillai
# download and update ensembl blast databases
# ================================================================

# change the path below

set echo on
DOWNLOAD=/pathToDownload
DATA=/pathToData
BIN=/cgi-bin/db/bin
LOG=/pathTolog
LOGFILE=$LOG/ensembl.log
CRONDIR=/pathToCronjobs


rm -f $LOGFILE

cd ${DOWNLOAD}
# rm -rf *      ! DON'T DO THIS!  If $DOWNLOAD doesn't exist, it causes lots of problems!

echo "Getting databases from ftp.ensembl.org ..." > $LOGFILE

# File names changed at ensembl FIL 09/03/09
wget --passive-ftp 'ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/cdna/Homo_sapiens.GRC*.cdna.all.fa.gz' -O Homo_sapiens.Ensembl.cdna.fa.gz -a $LOGFILE 2>&1
if [ "$?" -ne 0 ]
then
        mail -s "human ensembl cdna - error downloading data" yourAssistant@domain.com < $LOGFILE
        exit 1
fi
echo "downloaded human dna" >> $LOGFILE


wget --passive-ftp 'ftp://ftp.ensembl.org/pub/current_fasta/mus_musculus/cdna/Mus_musculus.GRC*.cdna.all.fa.gz' -O Mus_musculus.Ensembl.cdna.fa.gz  >> $LOGFILE 2>&1
if [ "$?" -ne 0 ]
then
        mail -s "mouse ensembl cdna - error downloading data" yourAssistant@domain.com < $LOGFILE
        exit 1
fi
echo "downloaded mouse dna" >> $LOGFILE


wget --passive-ftp 'ftp://ftp.ensembl.org/pub/current_fasta/rattus_norvegicus/cdna/Rattus_norvegicus.*.cdna.all.fa.gz' -O Rattus_norvegicus.Ensembl.cdna.fa.gz >> $LOGFILE 2>&1
if [ "$?" -ne 0 ]
then
        mail -s "rat ensembl cdna - error downloading data" yourAssistant@domain.com < $LOGFILE
        exit 1
fi
echo "downloaded rat dna" >> $LOGFILE



gunzip Homo_sapiens.Ensembl.cdna.fa.gz
gunzip Mus_musculus.Ensembl.cdna.fa.gz
gunzip Rattus_norvegicus.Ensembl.cdna.fa.gz


echo "Recently downloaded databases..." >> $LOGFILE
ls -ltr |tail >> $LOGFILE

if test -s Homo_sapiens.Ensembl.pep.fa -a -s Homo_sapiens.Ensembl.cdna.fa -a -s Mus_musculus.Ensembl.cdna.fa -a -s Mus_musculus.Ensembl.pep.fa -a -s Rattus_norvegicus.Ensembl.cdna.fa -a -s Rattus_norvegicus.Ensembl.pep.fa
then

echo "adding the gnl|ensembl to each description line ..." >> $LOGFILE
${BIN}/change_fasta_header.pl Homo_sapiens.Ensembl.cdna.fa gnl ensembl      >| ensembl_human.na
${BIN}/change_fasta_header.pl Mus_musculus.Ensembl.cdna.fa gnl ensembl      >| ensembl_mouse.na
${BIN}/change_fasta_header.pl Rattus_norvegicus.Ensembl.cdna.fa gnl ensembl  >| ensembl_rat.na


echo "add functional description to each transcript's description" >> $LOGFILE
${BIN}/add_ensembl_desc.pl ensembl_human.na human transcript > human_na.tmp
${BIN}/add_ensembl_desc.pl ensembl_mouse.na mouse transcript > mouse_na.tmp
${BIN}/add_ensembl_desc.pl ensembl_rat.na rat transcript > rat_na.tmp


mv -f human_na.tmp ensembl_human.na
mv -f mouse_na.tmp ensembl_mouse.na
mv -f rat_na.tmp ensembl_rat.na


echo "remove downloaded files in the download directory..." >> $LOGFILE
rm -f Homo_sapiens.Ensembl*.cdna.fa*
rm -f Mus_musculus.Ensembl*.cdna.fa*
rm -f Rattus_norvegicus.Ensembl*.cdna.fa*

echo "formatting the database for blast ..." >> $LOGFILE

set today = `date`
/usr/local/bin/makeblastdb -dbtype 'nucl' -title "human ensembl.na $today" -parse_seqids -in ensembl_human.na -out ensembl_human.na >> $LOGFILE 2>&1
/usr/local/bin/makeblastdb -dbtype 'nucl' -title "mouse ensembl.na $today" -parse_seqids -in ensembl_mouse.na -out ensembl_mouse.na >> $LOGFILE 2>&1
/usr/local/bin/makeblastdb -dbtype 'nucl' -title "rat ensembl.na $today" -parse_seqids -in ensembl_rat.na -out ensembl_rat.na >> $LOGFILE 2>&1


else
mail -s "ensembl file creation update error " yourAssistant@domain.com < /dev/null
exit 1
fi

if test -s ensembl_human.na.nhr  -a -s ensembl_mouse.na.nhr  -a -s ensembl_rat.na.nhr 
then

    echo "formatted databases: " >> $LOGFILE
    ls -ltr

    rsync -avz $DOWNLOAD/* /cgi-bin/siRNAext/db/ >> $LOGFILE

    echo "moving formatted files into the data directory..." >> $LOGFILE

    mv -f ensembl_human.na* ${DATA}/
    mv -f ensembl_mouse.na* ${DATA}/
    mv -f ensembl_rat.na* ${DATA}/

else
mail -s "ensembl update error " yourAssistant@domain.com < /dev/null
fi
