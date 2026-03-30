process IndexForIGV{
    container "community.wave.seqera.io/library/samtools:1.23.1--d76a06ff3aefee52" //samtools only container
    input:
    tuple val(sampleid), path(Markdup_bam_path)

    output:
    path("${sampleid}_Markdup.bam.bai"), emit: "bai"

    script:
    """
    samtools index -b ${Markdup_bam_path} -o "${sampleid}_Markdup.bam.bai"
    """
}