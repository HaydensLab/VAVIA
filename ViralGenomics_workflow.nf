#!/usr/bin/env nextflow
nextflow.enable.dsl=2


params{
    read_location: String
    study_code: String
    Keep_intermediates: Boolean
    batch: String = "batch_default"
    Ref_genome_path: Path
    Ref_Accession: String
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

process BWA_Indexing{
    tag("indexing reference genome")

    //container "biocontainers/bwa:v0.7.17_cv1" //pure bwa docker image

    input:
    path(reference_genome) //importing the reference genome

    output:
    path "*.{anb,ann,bwt,pac,sa}", emit: "Index_files" //output all files

    script:
    """
    bwa index ${reference_genome}
    """

    stub:
    """
    touch "${params.Ref_Accession}.amb"
    touch "${params.Ref_Accession}.ann"
    touch "${params.Ref_Accession}.bwt"
    touch "${params.Ref_Accession}.pac"
    touch "${params.Ref_Accession}.sa"
    """
}

process Aligner{
        
    tag("${sampleid}")

    container "community.wave.seqera.io/library/bwa_samtools:eac4ad78deba8f5d"
        
    input:
    tuple val(sampleid), path(read1), path(read2)
    path(Indexes)
    path(Reference)

    output:
    path("*.bam"), emit: "bam", optional: true
    path("*.cram"), emit: "cram", optional: true
    path("*.crai"), emit: "crai", optional: true
    path("*.csi"), emit: "csi", optional: true

    script:
    read_group = "@RG\tID:Seq${sampleid}\tSM:Seq${sampleid}\tPL:ILLUMINA\tPI:150"
    """
    bwa mem -R ${read_group} ${Indexes} ${Reference} ${read1} ${read2} | samtools view -b -S | samtools sort -n -o "${sampleid}.bam"
    """

    stub:
    """
    touch ${sampleid}.bam
    touch ${sampleid}.csi
    touch ${sampleid}.crai
    """
}

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
    Raw_Reads_channel = channel.fromFilePairs("${params.read_location}/*_{1,2}.fastq.gz", flat: true)//this specifies group pairs matching the pattern starts with ERR ends with _1 OR _2 it outputs an array with value 0 being ID before _1/2 and the read pair

    //initial raw read QC
    fastqc(Raw_Reads_channel)
    multiqc(params.batch, fastqc.out.qc_path.collect())
    
    //running fastp to remove adapters where possible
    fastp(Raw_Reads_channel)

    //second round of post-trimming QC
    fastqc_trimmed(fastp.out.read_tuple)
    multiqc_trimmed(params.batch, fastqc_trimmed.out.qc_path.collect())

    //NOT COMPLETE #############################################################################!!!!!!!!!!!!!!!!!!
    Reference_channel = channel.fromPath(params.Ref_genome_path)
    BWA_Indexing(Reference_channel)
    Aligner_input_ch = fastp.out.read_tuple
    Aligner_indexes_ch = BWA_Indexing.out.Index_files.collect().map{ Index_files -> tuple(Index_files)}.view()
    Aligner(Aligner_input_ch, Aligner_indexes_ch, Reference_channel)
    

    publish:
    QCresults = fastqc.out.qc_path
    Multiqc_results = multiqc.out
    Fastp_results = fastp.out.read_tuple //trimmed reads to go for later processing (with sample id)
    Fastp_html = fastp.out.html //report html
    Fastp_json = fastp.out.json //report json
    Trimmed_QCresults = fastqc_trimmed.out.qc_path
    Trimmed_multiqc_results = multiqc_trimmed.out
    //Index and align
    Indexes = BWA_Indexing.out.Index_files
    BAM_out = Aligner.out.bam

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
    Fastp_results{
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
}