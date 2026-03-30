process Markdup{
    container "community.wave.seqera.io/library/samtools:1.23.1--d76a06ff3aefee52" //samtools only container
    input:
    tuple val(sampleid), path(fixmate_bam_path) //takes in fixmate path

    output:
    tuple val(sampleid), path("${sampleid}_Markdup.bam"), emit: "Markdup_BAM" //outputs markdup

    script:
    """
    samtools markdup -r ${fixmate_bam_path} "${sampleid}_Markdup.bam"
    """
}