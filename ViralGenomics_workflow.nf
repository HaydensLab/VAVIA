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

workflow{

    main:
    PREPROCESSING() //runs fastqc, multiqc and fastp #######add option for trimmotatic

    //ALIGNMENT AND POST-PROCESSING
    BWAALIGNMENT(PREPROCESSING.out.Fastp_trimmed) //runs BWA-MEM and removes duplicate reads whilst generating a .bai for IGV viewing
    
    //Variant calling !!!!!!!!!!!!!!!! this currently DOES NOT WORK ------------ only works on first file put in
    VARIANT_CALLING(BWAALIGNMENT.out.BAM_out)

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
}