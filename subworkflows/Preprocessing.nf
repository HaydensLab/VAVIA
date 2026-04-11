#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { fastqc } from "../modules/fastqc.nf"
include { fastqc as fastqc_trimmed} from "../modules/fastqc.nf" //Alias for reuse

include { multiqc } from "../modules/multiqc.nf"
include { multiqc as multiqc_trimmed} from "../modules/multiqc.nf" //Alias for reuse

include { fastp } from "../modules/fastp.nf"

workflow PREPROCESSING{
    
    main:
    //Input channel inputting a flat array of the ID, Read1 path, Read2 path.
    Raw_Reads_channel = channel.fromFilePairs("${params.read_location}/*_{1,2}.fastq.gz", flat: true)//this specifies group pairs matching the pattern starts with ERR ends with _1 OR _2 it outputs an array with value 0 being ID before _1/2 and the read pair

    //initial raw read QC
    fastqc(Raw_Reads_channel)
    multiqc(params.batch, fastqc.out.qc_path.collect())
    
    //running fastp to remove adapters where possible
    fastp(Raw_Reads_channel)

    //second round of post-trimming QC
    fastqc_trimmed(fastp.out.read_tuple)
    multiqc_trimmed(params.batch, fastqc_trimmed.out.qc_path.collect())


    emit:
    QCresults               = fastqc.out.qc_path
    Multiqc_results         = multiqc.out
    Fastp_trimmed           = fastp.out.read_tuple //trimmed reads to go for later processing (with sample id)
    Fastp_html              = fastp.out.html //report html
    Fastp_json              = fastp.out.json //report json
    Trimmed_QCresults       = fastqc_trimmed.out.qc_path
    Trimmed_multiqc_results = multiqc_trimmed.out

}