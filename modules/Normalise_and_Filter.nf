process Normalise_and_Filter{
    tag("${sampleid}")
    container 'community.wave.seqera.io/library/bcftools_samtools:1.23.1--79a710bf7bd8ea91'

    input:
    path(ref_genome)
    tuple val(sampleid), path(vcf_file)

    output:
    tuple val (sampleid), path("${sampleid}_norm_variants.vcf"), emit: Normalised_VCF_out, optional: true
    tuple val (sampleid), path("${sampleid}_filtered_norm_variants.vcf"), emit: Filtered_Normalised_VCF_out, optional: true
    script:
    """
    echo "Generating temp index for reheading"
    echo "Normalising vcf ----splitting multiallelic sites"
    samtools faidx -f $ref_genome
    bcftools reheader -f "${ref_genome}.fai" ${vcf_file} | bcftools norm -m -any -f "${ref_genome}" -o "${sampleid}_norm_variants.vcf" 

    FilterSettings='DP>=30 && AF>=0.01 && QUAL>20' #######################FIX THIS LATER IT DOESNT WORK####################

    echo "Filtering using settings: DP>=30 && AF>=0.01 && QUAL>20"
    bcftools view -i 'DP>=30 && AF>=0.01 && QUAL>20' "${sampleid}_norm_variants.vcf" > "${sampleid}_filtered_norm_variants.vcf"
    """

}