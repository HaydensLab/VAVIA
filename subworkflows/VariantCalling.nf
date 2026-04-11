#!/usr/bin/env nextflow
nextflow.enable.dsl=2


// process  BaseRecalibrator{


// }

// process BQSR{


// }

// process GATKHaplotypecaller{
//     tag("${sampleid}")

//     container 'broadinstitute/gatk:4.6.2.0'

//     input:
//     path(ref_genome)
//     tuple val(sampleid), path(bam_path)

//     output:
//     tuple val (sampleid), path("${sampleid}.gatkHTC.bam"), emit: GATK_haplotypecaller_BAM

//     script:
//     """
    
//     """
// }



include { LofreqVarCall } from "../modules/LofreqVarCall.nf"
include { LoFreqIndelQual } from "../modules/LoFreqIndelQual.nf"
include { Normalise_and_Filter } from "../modules/Normalise_and_Filter.nf"

workflow VARIANT_CALLING{
    take:
    Aligned_bam_path

    main:

    Reference_channel_VCF = file(params.Ref_genome_path)
    bams_ch = Aligned_bam_path

    
    LoFreqIndelQual(Reference_channel_VCF, bams_ch)
    println("Using VariantCaller lofreq")
    LofreqVarCall(Reference_channel_VCF, LoFreqIndelQual.out.IndelQual_BAM)
    Normalise_and_Filter(Reference_channel_VCF, LofreqVarCall.out.LoFreq_VCF_out)


    emit:
    VCF_out = LofreqVarCall.out.LoFreq_VCF_out
    nVCF_out  = Normalise_and_Filter.out.Normalised_VCF_out
    fnVCF_out = Normalise_and_Filter.out.Filtered_Normalised_VCF_out
}