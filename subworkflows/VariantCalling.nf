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

process LoFreqIndelQual{

    tag("${sampleid}")

    container 'nanozoo/lofreq:2.1.5--229539a'

    input:
    path(ref_genome)
    tuple val(sampleid), path(bam_path)

    output:
    tuple val (sampleid), path("${sampleid}.indelqual.bam"), emit: IndelQual_BAM

    script:
    """
    lofreq indelqual --dindel -f ${ref_genome} -o "${sampleid}.indelqual.bam" ${bam_path}
    """
}


process LofreqVarCall{
//ENSURE BED FILE IS PROVIDED IN CASE OF VARIANT CALLING NOT ON ENTIRE GENOME (specify locations in a bed file that are being tested to avoid bonferroni problems)

    tag("${sampleid}")

    container 'nanozoo/lofreq:2.1.5--229539a'

    input:
    path(ref_genome)
    tuple val(sampleid), path(recalibrated_bam)

    output:
    tuple val (sampleid), path("${sampleid}_variants.vcf"), emit: LoFreq_VCF_out, optional: true

    script:
    """
    ##lofreq call-parallel --pp-threads 8 -f ref.fa -o vars.vcf aln.bam
    lofreq call --call-indels -f ${ref_genome} -o "${sampleid}_variants.vcf" ${recalibrated_bam}
    """
}

process Normalise_and_Filter{
    tag("${sampleid}")
    container 'staphb/bcftools:1.23'

    input:
    path(ref_genome)
    tuple val(sampleid), path(vcf_file)

    output:
    tuple val (sampleid), path("${sampleid}_norm_variants.vcf"), emit: Normalised_VCF_out, optional: true
    tuple val (sampleid), path("${sampleid}_filtered_norm_variants.vcf"), emit: Filtered_Normalised_VCF_out, optional: true
    script:
    """
    bcftools norm -D -m -f "${ref_genome}" -o "${sampleid}_norm_variants.vcf" ${vcf_file}
    bcftools view -i 'DP>=30 && AF>=0.01 && QUAL>20' "${sampleid}_norm_variants.vcf" > "${sampleid}_filtered_norm_variants.vcf"
    """

}



workflow VARIANT_CALLING{
    take:
    Aligned_bam_path

    main:

    Reference_channel_VCF = file(params.Ref_genome_path)
    bams_ch = Aligned_bam_path

    
    LoFreqIndelQual(Reference_channel_VCF, bams_ch)
    println("Using VariantCaller lofreq")
    LofreqVarCall(Reference_channel_VCF, LoFreqIndelQual.out.IndelQual_BAM)
    println("Normalising output VCF")
    Normalise_and_Filter(Reference_channel_VCF, LofreqVarCall.out.LoFreq_VCF_out)


    emit:
    VCF_out = LofreqVarCall.out.LoFreq_VCF_out
    nVCF_out  = Normalise_and_Filter.out.Normalised_VCF_out
    fnVCF_out = Normalise_and_Filter.out.Filtered_Normalised_VCF_out
}