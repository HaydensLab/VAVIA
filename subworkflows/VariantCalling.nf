#!/usr/bin/env nextflow
nextflow.enable.dsl=2


process CliqueSNV{

}

process ShoRAH{


}

process GATKHaplotypecaller{

}

process Lofreq{

}



workflow VARIANT_CALLING{
    take:
    markdup_bam_path


    main:

    emit:
    VCF_out = 
}