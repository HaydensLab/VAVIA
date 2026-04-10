//Take input BAM and run through the following 2 programs: CliqueSNV (generating local haplotypes) and HaploClique

process SAVAGE{
    container "fabiomarcelo/savage:latest"
    tag("${sampleid}")

    input:
    tuple val(sampleid), path(read1), path(read2)

    output:
    tuple val(sampleid), path("${sampleid}_SAVAGEoutput/*"), emit: "SAVAGE_out", optional: true
    script:
    """
    savage --split  --revcomp \
    -p1 "${read1}" -p2 ${read2} -o "${sampleid}_SAVAGEoutput/"
    """
}

process HaploClique{
    container "community.wave.seqera.io/library/haploclique:1.3.1--5baeef280bc3b4ba"
    tag("${sampleid}")

    input:
    tuple val(sampleid), path(bam_path)

    output:
    tuple val(sampleid), path("*"), emit: "haploclique_out", optional: true

    script:
    """
    haploclique "${bam_path}"
    """
}



process cliqueSNV{
    tag("${sampleid}")
    container "community.wave.seqera.io/library/cliquesnv_samtools:25cd3de642f742dc"

    input:
    val(platform)
    tuple val(sampleid), path(bam_path) //input the metadata and path to the bam file which will be converted back to the sam as an intermediate step.

    output:
    tuple val(sampleid), path("snv_output/*"), emit: "CliqueSNV_out", optional: true //tuple for sampleid specific folder output with all contents

    script:
    //first generate a method variable to specify either pacbio or illumina 
    method = "snv-${platform}"
    """
    samtools view -h -o "${sampleid}.sam" ${bam_path}
    cliquesnv -m ${method} -rn -in "${sampleid}.sam" #use clique-snv.jar for local use but this container has it in conda
    """
}


workflow HAPLOTYPE_RECONSTRUCTION{
    take:
    Markdup_BAM
    raw_reads
    main:
    //Haplotype SNV calls
         cliqueSNV(params.platform.toLowerCase(), Markdup_BAM)
            cliqueSNV.out.CliqueSNV_out.view()
    //Global haplotypes
            //HaploClique(Markdup_BAM)
        SAVAGE(raw_reads)

    emit:
    Haplotype_out = cliqueSNV.out.CliqueSNV_out
            //Global_Haplotype_out = HaploClique.out.haploclique_out
    Global_Haplotype_out = SAVAGE.out.SAVAGE_out

}