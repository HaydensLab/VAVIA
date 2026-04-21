//Take input BAM and run through the following 2 programs: CliqueSNV (generating local haplotypes) and HaploClique

// process MEGAHIT{
//     container "vout/megahit:release-v1.2.9"
//     tag("${sampleid}")

//     input:
//     tuple val(sampleid), path(read1), path(read2)

//     output:
//     script:
//     """
  
//     """
// }


process SAVAGE{
    container "haydenslab/vavia-savage:1.0.1"
    tag("${sampleid}")

    input:
    tuple val(sampleid), path(read1), path(read2)
    val(split_num)

    output:
    tuple val(sampleid), path("${sampleid}_SAVAGEoutput/*"), emit: "SAVAGE_out", optional: true
    script:
    """ 
    gunzip -c ${read1} > "${sampleid}_1.fastq"
    gunzip -c ${read2} > "${sampleid}_2.fastq"

    raw="${params.min_overlap_length}"

    clean_len=\$(echo \$raw | xargs)

    if [[ \$clean_len =~ ^[0-9]+\$ ]]; then
        min_overlap="-m \$clean_len"
        echo "Minimum overlap set to: \$min_overlap"
    else
        min_overlap=""
        echo "Minimum overlap set to SAVAGE default (60%)"
    fi

    bash_split=$split_num

    if [ \$bash_split -lt 2 ]; then
        savage --split 2 --revcomp -t 4 \
        -p1 ${sampleid}_1.fastq -p2 "${sampleid}_2.fastq" -o "${sampleid}_SAVAGEoutput/"
    elif ! [[ \$bash_split =~ ^[0-9]+\$ ]]; then
        echo "ERROR: calculated split_num for SAVAGE -splits was not a valid integer"
        exit 1
    else
        savage --split \$bash_split --revcomp -t 4 \$min_overlap \
        -p1 ${sampleid}_1.fastq -p2 "${sampleid}_2.fastq" -o "${sampleid}_SAVAGEoutput/"
    fi
    """
}

process HaploClique{ //currently unused
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
    //Input also takes patch_num (Coverage_and_stats environment variable) but does not use it in order to minimise channels used

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
    Savage_splitting
    main:
    //Haplotype SNV calls
         cliqueSNV(params.platform.toLowerCase(), Markdup_BAM) //does not take splits as input
            cliqueSNV.out.CliqueSNV_out.view()
    //Global haplotypes
            //HaploClique(Markdup_BAM)
        SAVAGE(raw_reads, Savage_splitting)

    emit:
    Haplotype_out = cliqueSNV.out.CliqueSNV_out
            //Global_Haplotype_out = HaploClique.out.haploclique_out
    Global_Haplotype_out = SAVAGE.out.SAVAGE_out

}