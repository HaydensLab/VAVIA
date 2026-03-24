#! /bin/bash
##mkdir -p /Raw_data
#######Specify download FTPs below
Patient1 = "ERR3163055"
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR316/005/ERR3163055/ERR3163055_1.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR316/005/ERR3163055/ERR3163055_2.fastq.gz

##Patient2 = "ERR3163059"
##wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR316/009/ERR3163059/ERR3163059_1.fastq.gz
##wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR316/009/ERR3163059/ERR3163059_2.fastq.gz

Patient3 = "ERR3163159"
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR316/009/ERR3163159/ERR3163159_1.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR316/009/ERR3163159/ERR3163159_2.fastq.gz

Patient4 = "ERR3163168"
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR316/008/ERR3163168/ERR3163168_2.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR316/008/ERR3163168/ERR3163168_1.fastq.gz

Patient5 = "SRR9225743"
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR922/003/SRR9225743/SRR9225743_2.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR922/003/SRR9225743/SRR9225743_1.fastq.gz
