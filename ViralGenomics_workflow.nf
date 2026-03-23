#!/usr/bin/env nextflow
nextflow.enable.dsl=2


params{
    read_location: String
    study_code: String
}

include { fastqc } from "./modules/fastqc"





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
    Reads_channel = channel.fromFilePairs("${params.read_location}/${params.study_code}*_{1,2}.fastq.gz") //this specifies group pairs matching the pattern starts with ERR ends with _1 OR _2

    fastqc(Reads_channel)

    publish:
    QCresults = fastqc.out

}

output{
    QCresults{
        path "."
        mode "copy"
    }
}