#!/usr/bin/env nextflow
nextflow.enable.dsl=2


params{
    read_location: String
    batch: String = "batch_default"
    Ref_genome_path: Path
    Ref_Accession: String
    platform: String
    insert_size: String
    Variant_Caller: String = "lofreq"
    min_overlap_length: String
    //Filtering_Cutoffs: String = "DP>=30 && AF>=0.01 && QUAL>20" //not yet implemented



    //subworkflow selection - used for deciding how you want the pipeline to run
    Run_QC: Boolean = true
    Run_HaplotypeReconstruction: Boolean = true
    Input_format: String = "fastq"
    Index_for_IGV: Boolean = true
}
//==========================================================================Help section==========================================================================




// process CleanUp{
//     input:
//     output:
//     script:
// }

// process MinimapAlign{

// }


//each channel displays as a symlink to the previous work directory of the previous process, hence the loss of absolute file path
include { PREPROCESSING } from './subworkflows/Preprocessing.nf'
include { BWAALIGNMENT } from './subworkflows/BWAalignment.nf'
include { VARIANT_CALLING } from './subworkflows/VariantCalling.nf'
include { HAPLOTYPE_RECONSTRUCTION } from './subworkflows/HaplotypeReconstruction.nf'

workflow{

    main:
    println("============================================PARAMETERS============================================")
    println("batch: ${params.batch}")
    //println("Reference accession: ${params.Ref_accession}")
    println("Mode options selected: \n\t\t\tQC: ${params.Run_QC} \n\t\t\tHaplotypeReconstruction: ${params.Run_HaplotypeReconstruction} \n\t\t\tInput: ${params.Input_format} \n\t\t\tIndexing: ${params.Index_for_IGV} ")
    println("\t\t\tVariant caller: LoFreq")
    println("\t\t\tPlatform: ${params.platform}")
    println("\t\t\tDrawing from: ${params.read_location}")
    println("\t\t\tProvided insert size: ${params.insert_size}")
    println("\t\t\tCurrent filtering parameters: DP>=30 && AF>=0.01 && QUAL>20 - defaults")
    println("==================================================================================================")
    println("To edit any parameters that are program specific and not in RunConfig.yaml please modify in the /modules directory to fit your needs")

    //PRE-PROCESSING
    PREPROCESSING() //runs fastqc, multiqc and fastp #######add option for trimmotatic

    //ALIGNMENT AND POST-PROCESSING
    BWAALIGNMENT(PREPROCESSING.out.Fastp_trimmed) //runs BWA-MEM and removes duplicate reads whilst generating a .bai for IGV viewing
    
    //Variant calling
    VARIANT_CALLING(BWAALIGNMENT.out.BAM_out)

    //HaplotypeReconstruction for generation of varied neoantigen calls
    HAPLOTYPE_RECONSTRUCTION(BWAALIGNMENT.out.BAM_out, PREPROCESSING.out.Fastp_trimmed, BWAALIGNMENT.out.Savage_splitting)    //cliqueSNV, haploclique and SAVAGE

    //CONSENSUS GENOME GENERATION
    //PHYLOGENETIC ANALYSIS
    //construct for args to be added later: Variable ? Iftrue : Else


























    publish:
    QCresults               = PREPROCESSING.out.QCresults
    Multiqc_results         = PREPROCESSING.out.Multiqc_results
    Fastp_trimmed           = PREPROCESSING.out.Fastp_trimmed
    Fastp_html              = PREPROCESSING.out.Fastp_html
    Fastp_json              = PREPROCESSING.out.Fastp_json
    Trimmed_QCresults       = PREPROCESSING.out.Trimmed_QCresults
    Trimmed_multiqc_results = PREPROCESSING.out.Trimmed_multiqc_results
    //Index and align
    Indexes                 = BWAALIGNMENT.out.Indexes
    BAM_out                 = BWAALIGNMENT.out.BAM_out.map{sampleid, markdup_bam_path -> markdup_bam_path} //taking only the second argument of the tuple by overwriting with only second argument
    BAI_out                 = BWAALIGNMENT.out.BAI_out
    BAM_stats_out           = BWAALIGNMENT.out.BAM_Stats_out
    //variant calling
    VCF_out                 = VARIANT_CALLING.out.VCF_out
    nVCF_out                = VARIANT_CALLING.out.nVCF_out
    fnVCF_out               = VARIANT_CALLING.out.fnVCF_out
    //haplotype reconstruction
    Haplotype_out           = HAPLOTYPE_RECONSTRUCTION.out.Haplotype_out //output the pan haplotype output - currently testing
    Global_Haplotype_out    = HAPLOTYPE_RECONSTRUCTION.out.Global_Haplotype_out

}

output{
    //=================================raw QC outputs=================================
    QCresults{
        path "./${params.batch}/raw_QC"
        mode "copy"
    }
    Multiqc_results{
        path "./${params.batch}/raw_multiqc"
        mode "copy"
    }

    //=================================fastp outputs=================================
    Fastp_trimmed{
        path "./${params.batch}/fastp/"
        mode "copy"
    }
    Fastp_html{
        path "./${params.batch}/fastp/"
        mode "copy"
    }
    Fastp_json{
        path "./${params.batch}/fastp/"
        mode "copy"
    }
    //=================================fastp trimmed QC outputs=================================
    Trimmed_QCresults{
        path "./${params.batch}/Trimmed_QC"
        mode "copy"
    }
    Trimmed_multiqc_results{
        path "./${params.batch}/Trimmed_multiqc"
        mode "copy"
    }
    //=================================BAM + Indexes + BAM stats =================================
    Indexes{
        path "./${params.batch}/Aligned_and_Indexes"
    }
    BAM_out{
        path "./${params.batch}/Aligned_and_Indexes"
    }
    BAI_out{
        path "./${params.batch}/Aligned_and_Indexes"
    }
    BAM_stats_out{
        path "./${params.batch}/Aligned_and_Indexes"
    }
    //=================================Variant calling =================================
    VCF_out{
        path "./${params.batch}/Variant_Calls"
    }
    nVCF_out{
        path "./${params.batch}/Variant_Calls"
    }
    fnVCF_out{
        path "./${params.batch}/Variant_Calls"
    }
    //=================================Haplotypes =================================
    Haplotype_out{
        path "./${params.batch}/Haplotypes"
    }
    Global_Haplotype_out{
        path "./${params.batch}/Haplotypes"
    }
}