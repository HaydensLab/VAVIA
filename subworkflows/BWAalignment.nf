#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { BWA_Indexing } from "../modules/BWAindexer.nf"
include { Aligner } from "../modules/BWAaligner.nf"  

workflow BWAALIGNMENT{
    take:
    Fastp_trimmed

    main:
    Reference_channel = channel.fromPath(params.Ref_genome_path)
    BWA_Indexing(Reference_channel)
    Aligner_input_ch = Fastp_trimmed
    Aligner_indexes_ch = BWA_Indexing.out.Index_files.collect().map{ Index_files -> tuple(Index_files)}.view()
    Aligner(Aligner_input_ch, Aligner_indexes_ch)


    emit:
    Indexes = BWA_Indexing.out.Index_files
    BAM_out = Aligner.out.bam
}