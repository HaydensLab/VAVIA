#!/usr/bin/env nextflow
nextflow.enable.dsl=2


params{
    read_location: String
    study_code: String
    batch_id: String
    Keep_intermediates: Boolean
    batch: String = "batch_default"
}

//aliases are used here to allow for reusing of processes under different names to avoid overwriting
include { fastqc } from "./modules/fastqc.nf"
include { fastqc as fastqc_trimmed} from "./modules/fastqc.nf"

include { multiqc } from "./modules/multiqc.nf"
include { multiqc as multiqc_trimmed} from "./modules/multiqc.nf"

include { fastp } from "./modules/fastp.nf"


// process CleanUp{
//     input:
//     output:
//     script:
// }


// process RunConfigImport{
    
// }


// process Aligner{

// }

// process PostProcessing{

// }

// process VariantCalling{

// }

// process VariantFiltering{

// }

// process VariantAnnotation{

// }


//each channel displays as a symlink to the previous work directory of the previous process, hence the loss of absolute file path


workflow{

    main:
    //Input channel inputting a flat array of the ID, Read1 path, Read2 path.
    Raw_Reads_channel = channel.fromFilePairs("${params.read_location}/*_{1,2}.fastq.gz", flat: true).view()//this specifies group pairs matching the pattern starts with ERR ends with _1 OR _2 it outputs an array with value 0 being ID before _1/2 and the read pair

    //initial raw read QC
    fastqc(Raw_Reads_channel)
    multiqc(params.batch_id, fastqc.out.qc_path.collect())
    
    //running fastp to remove adapters where possible
    fastp(Raw_Reads_channel)

    //second round of post-trimming QC
    fastqc_trimmed(fastp.out.read_tuple)
    multiqc_trimmed(params.batch_id, fastqc_trimmed.out.qc_path.collect())


    publish:
    QCresults = fastqc.out.qc_path
    multiqc_results = multiqc.out
    fastp_results = fastp.out.read_tuple //trimmed reads to go for later processing (with sample id)
    fastp_html = fastp.out.html //report html
    fastp_json = fastp.out.json //report json
    Trimmed_QCresults = fastqc_trimmed.out.qc_path.view()
    Trimmed_multiqc_results = multiqc_trimmed.out.view()

}

output{
    //=================================raw QC outputs=================================
    QCresults{
        path "./${params.batch}/raw_QC"
        mode "copy"
    }
    multiqc_results{
        path "./${params.batch}/raw_multiqc"
        mode "copy"
    }

    //=================================fastp outputs=================================
    fastp_results{
        path "./${params.batch}/fastp/"
        mode "copy"
    }
    fastp_html{
        path "./${params.batch}/fastp/"
        mode "copy"
    }
    fastp_json{
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
}