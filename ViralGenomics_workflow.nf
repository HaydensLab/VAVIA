#!/usr/bin/env nextflow
nextflow.enable.dsl=2


params{
    read_location: String
    study_code: String
    batch_id: String
    Keep_intermediates: Boolean
    batch: String = "batch_default"
}

include { fastqc } from "./modules/fastqc"


process multiqc{
    container "multiqc/multiqc:latest"
   
    tag("${sampleid}")

    input:
    val sampleid
    path qc_results_path

    output:
    path("*")

    script:
    """
    multiqc ${qc_results_path}
    """
}

// process CleanUp{
//     input:
//     output:
//     script:
// }


// process RunConfigImport{
    
// }



// process Trimming{


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
    Reads_channel = channel.fromFilePairs("${params.read_location}/*_{1,2}.fastq.gz") //this specifies group pairs matching the pattern starts with ERR ends with _1 OR _2

    fastqc(Reads_channel)
    multiqc(params.batch_id, fastqc.out.qc_path.collect())

    publish:
    QCresults = fastqc.out.qc_path
    multiqc_result = multiqc.out.view()



}

output{
    QCresults{
        path "./${params.batch}"
        mode "copy"
    }
    multiqc_result{
        path "./${params.batch}/multiqc"
        mode "copy"
    }
}