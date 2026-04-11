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
    //Filtering_Cutoffs: String = "DP>=30 && AF>=0.01 && QUAL>20" //not yet implemented
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
    println("Variant caller: LoFreq")
    println("Platform: ${params.platform}")
    println("Drawing from read location: ${params.read_location}")
    println("Provided insert size: ${params.insert_size}")
    println("=============================================Overview=============================================")
    println("This workflow will draw reads, align to a provided reference genome\nit will then call variants\nin this future this workflow will generate antigen prediction")
    println("Current processes: raw fastqc, raw multiqc, fastp (later trimmomatic option), repeat QC for trimmed, BWA-MEM aligment, Fixmate + Markdup, Indexing for IGV viewing, LoFreq indelqual+Calling, VCF normalisation and filtering")
    println("Current filtering parameters: DP>=30 && AF>=0.01 && QUAL>20 - defaults")
    println("!!!!!!!!!!!!!!!! To edit these please modify the Normalise_and_Filter module ----- a config parameter will be added at a later date")

    //PRE-PROCESSING
    PREPROCESSING() //runs fastqc, multiqc and fastp #######add option for trimmotatic

    //ALIGNMENT AND POST-PROCESSING
    BWAALIGNMENT(PREPROCESSING.out.Fastp_trimmed) //runs BWA-MEM and removes duplicate reads whilst generating a .bai for IGV viewing
    
    //Variant calling
    VARIANT_CALLING(BWAALIGNMENT.out.BAM_out)

    //HaplotypeReconstruction for generation of varied neoantigen calls
    HAPLOTYPE_RECONSTRUCTION(BWAALIGNMENT.out.BAM_out, PREPROCESSING.out.Fastp_trimmed)    //cliqueSNV, haploclique and SAVAGE

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
    //=================================Align + Indexes =================================
    Indexes{
        path "./${params.batch}/Aligned_and_Indexes"
    }
    BAM_out{
        path "./${params.batch}/Aligned_and_Indexes"
    }
    BAI_out{
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