process SAVAGE{
    container "haydenslab/vavia-savage:1.0.1"
    tag("${sampleid}")
    maxForks(1) //SAVAGE is highly memory intensive, as such only 1 SAVAGE will run at a time to attempt to prevent OOM errors.


    input:
    tuple val(sampleid), path(read1), path(read2)
    val(split_num)

    output:
    tuple val(sampleid), path("${sampleid}_SAVAGEoutput/*"), emit: "SAVAGE_out", optional: true


    script:
    """ 
    gunzip -c ${read1} > "${sampleid}_1.fastq"
    gunzip -c ${read2} > "${sampleid}_2.fastq"

    raw="${params.min_overlap_length}"

    clean_len=\$(echo \$raw | xargs)

    if [[ \$clean_len =~ ^[0-9]+\$ ]]; then
        min_overlap="-m \$clean_len"
        echo "Minimum overlap set to: \$min_overlap"
    else
        min_overlap=""
        echo "Minimum overlap set to SAVAGE default (60%)"
    fi

    bash_split=$split_num

    if [ \$bash_split -lt 1 ]; then
        savage --split 1 --revcomp -t 8 \$min_overlap \
        -p1 ${sampleid}_1.fastq -p2 "${sampleid}_2.fastq" -o "${sampleid}_SAVAGEoutput/"
    elif ! [[ \$bash_split =~ ^[0-9]+\$ ]]; then
        echo "ERROR: calculated split_num for SAVAGE -splits was not a valid integer"
        exit 1
    else
        savage --split \$bash_split --revcomp -t 8 \$min_overlap \
        -p1 ${sampleid}_1.fastq -p2 "${sampleid}_2.fastq" -o "${sampleid}_SAVAGEoutput/"
    fi
    """
}