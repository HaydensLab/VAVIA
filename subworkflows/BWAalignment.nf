#!/usr/bin/env nextflow
nextflow.enable.dsl=2
//==========================================================================Processing modules==========================================================================
include { BWA_Indexing } from "../modules/BWAindexer.nf"
include { Aligner } from "../modules/BWAaligner.nf"  
include { Fixmate } from "../modules/Fixmate.nf"
include { Markdup } from "../modules/Markdup.nf"
include { IndexForIGV } from "../modules/IndexForIGV.nf"

process Stats_and_Coverage{
    tag("${sampleid}")
    container "community.wave.seqera.io/library/samtools:1.23.1--d76a06ff3aefee52"

    input:
    tuple val(sampleid), path(bam_path)

    output:
    env('patch_num'), emit: "BAM_splitting", optional: true
    path("${sampleid}.stats"), emit: "BAM_stats", optional: true

    script:
    //takes sum of depth divide by number of lines (average depth)
    //then divides by 750 to calculate the total number of splits the data requires for savage
    //then generates a stats output for the bam file
    """
    AVERAGE_COVERAGE=\$(samtools idxstats ${bam_path} | awk '{sum+=\$3} END {print (sum/NR)}') ###################CURRENTLY BROKEN
    patch_num=\$(awk -v x="\$AVERAGE_COVERAGE" 'BEGIN {print int((x+749)/750)}')
    samtools stats ${bam_path} > "${sampleid}.stats"
    echo "${sampleid} has an average coverage of \$AVERAGE_COVERAGE \n\n Savage splitting: \$patch_num"
    """
}


workflow BWAALIGNMENT{
    take:
    Fastp_trimmed
    
    main:
    Reference_channel = file(params.Ref_genome_path) //channel takes input from global parameter specified in the RunConfig.yaml file
    BWA_Indexing(Reference_channel)

    Aligner_input_ch = Fastp_trimmed
    Aligner_indexes_ch = BWA_Indexing.out.Index_files.collect().map{ Index_files -> tuple(Index_files)} //collecting all the index files and then generating a map from them

    Aligner(Aligner_input_ch, Aligner_indexes_ch) //Running aligner using 2 generated input channels in this case Aligner_indexes_ch is a value 'channel' that is providing a val

    Fixmate(Aligner.out.bam) //takes name sorted raw bam
    Markdup(Fixmate.out.Sorted_Fixmate_BAM) //takes coordinate sorted Fixmate -m bam
    IndexForIGV(Markdup.out.Markdup_BAM) //outputs bai
    
    //Running coverage and other stats calculations - taking the markdup as input
    Stats_and_Coverage(Markdup.out.Markdup_BAM)
    Stats_and_Coverage.out.BAM_splitting.view()

    emit:
    Indexes = BWA_Indexing.out.Index_files
    BAM_out = Markdup.out.Markdup_BAM
    BAI_out = IndexForIGV.out.bai
    BAM_Stats_out = Stats_and_Coverage.out.BAM_stats
    Savage_splitting = Stats_and_Coverage.out.BAM_splitting

    //test
    // BAM_out = Aligner.out.bam.map{sampleid, rando_bam_path -> rando_bam_path}
    // BAI_out = channel.empty()
    
    
}