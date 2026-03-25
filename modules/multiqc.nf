process multiqc{
    container "multiqc/multiqc:latest"
   
    tag("${sampleid}")

    input:
    val sampleid
    path qc_results_path

    output:
    path("*")

    script:
    """
    multiqc ${qc_results_path} --fullnames
    """
}