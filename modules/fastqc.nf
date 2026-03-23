process fastqc{

    tag("${sampleid}")

    container "biocontainers/fastqc:v0.11.9_cv8"

    input:
    tuple val(sampleid), path(reads)

    output:
    // path "*.html", emit: "html"
    // path "*.zip", emit: "zip"
    path "${sampleid}_QC/"

    script:
    """
    mkdir -p "${sampleid}_QC"
    fastqc ${reads[0]} ${reads[1]} -o ${sampleid}_QC/
    
    """
}