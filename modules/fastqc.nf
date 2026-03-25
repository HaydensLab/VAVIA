process fastqc{

    tag("${sampleid}")

    container "biocontainers/fastqc:v0.11.9_cv8"

    input:
    tuple val(sampleid), path(read1), path(read2)

    output:
    path("${sampleid}_QC/"), emit: "qc_path"
    val(sampleid), emit: "sampleid"

    script:
    """
    mkdir -p "${sampleid}_QC"
    fastqc ${read1} ${read2} -o ${sampleid}_QC/
    
    """
}