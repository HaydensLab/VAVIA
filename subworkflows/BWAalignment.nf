#!/usr/bin/env nextflow
nextflow.enable.dsl=2
//==========================================================================Processing modules==========================================================================
include { BWA_Indexing } from "../modules/BWAindexer.nf"
include { Aligner } from "../modules/BWAaligner.nf"  
include { Fixmate } from "../modules/Fixmate.nf"
include { Markdup } from "../modules/Markdup.nf"
include { IndexForIGV } from "../modules/IndexForIGV.nf"


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

    emit:
    Indexes = BWA_Indexing.out.Index_files
    BAM_out = Markdup.out.Markdup_BAM
    BAI_out = IndexForIGV.out.bai

    //test
    // BAM_out = Aligner.out.bam.map{sampleid, rando_bam_path -> rando_bam_path}
    // BAI_out = channel.empty()
    
    
}