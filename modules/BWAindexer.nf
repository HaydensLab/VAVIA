process BWA_Indexing{
    tag("indexing reference genome")

    container "biocontainers/bwa:v0.7.17_cv1" //pure bwa docker image

    input:
    path(reference_genome) //importing the reference genome

    output:
    path("*.{amb,ann,bwt,pac,sa}"), emit: "Index_files" //output all files

    script:
    """
    bwa index ${reference_genome}
    """

    stub:
    """
    touch "${params.Ref_Accession}.amb"
    touch "${params.Ref_Accession}.ann"
    touch "${params.Ref_Accession}.bwt"
    touch "${params.Ref_Accession}.pac"
    touch "${params.Ref_Accession}.sa"
    """
}