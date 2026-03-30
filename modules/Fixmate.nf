process Fixmate{
    container "community.wave.seqera.io/library/samtools:1.23.1--d76a06ff3aefee52" //samtools only container
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