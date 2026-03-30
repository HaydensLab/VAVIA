#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { BWA_Indexing } from "../modules/BWAindexer.nf"
include { Aligner } from "../modules/BWAaligner.nf"  

process Fixmate{
    container "community.wave.seqera.io/library/samtools:1.23.1--d76a06ff3aefee52"
    input:
    tuple val(sampleid), path(bam_path)

    output:
    tuple val(sampleid), path("${sampleid}_sorted_fixmate.bam"), emit: "Sorted_Fixmate_BAM"

    script:
    """
    samtools fixmate -m ${bam_path} ${sampleid}_fixmate.bam
    samtools sort "${sampleid}_fixmate.bam" -o "${sampleid}_sorted_fixmate.bam"
    """
}

process Markdup{
    container "community.wave.seqera.io/library/samtools:1.23.1--d76a06ff3aefee52"
    input:
    tuple val(sampleid), path(fixmate_bam_path)

    output:
    tuple val(sampleid), path("${sampleid}_Markdup.bam"), emit: "Markdup_BAM"

    script:
    """
    samtools markdup -r ${fixmate_bam_path} "${sampleid}_Markdup.bam"
    """
}

process IndexForIGV{
    container "community.wave.seqera.io/library/samtools:1.23.1--d76a06ff3aefee52"
    input:
    tuple val(sampleid), path(Markdup_bam_path)

    output:
    path("${sampleid}_Markdup.bam.bai"), emit: "bai"

    script:
    """
    samtools index -b ${Markdup_bam_path} -o "${sampleid}_Markdup.bam.bai"
    """
}

workflow BWAALIGNMENT{
    take:
    Fastp_trimmed

    main:
    Reference_channel = channel.fromPath(params.Ref_genome_path)
    BWA_Indexing(Reference_channel)
    Aligner_input_ch = Fastp_trimmed
    Aligner_indexes_ch = BWA_Indexing.out.Index_files.collect().map{ Index_files -> tuple(Index_files)}.view()
    Aligner(Aligner_input_ch, Aligner_indexes_ch)

    Fixmate(Aligner.out.bam) //takes name sorted raw bam
    Markdup(Fixmate.out.Sorted_Fixmate_BAM) //takes coordinate sorted Fixmate -m bam
    IndexForIGV(Markdup.out.Markdup_BAM) //outputs bam with duplicates removed

    emit:
    Indexes = BWA_Indexing.out.Index_files
    BAM_out = Markdup.out.Markdup_BAM.view().map{sampleid, markdup_bam_path -> markdup_bam_path}.view()
    BAI_out = IndexForIGV.out.bai

    //test
    //BAM_out = Aligner.out.bam.map{sampleid, rando_bam_path -> rando_bam_path}
    //BAI_out = channel.empty()
    
}