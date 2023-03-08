process NONPAREIL {
    tag "$meta.id"
    label "process_medium"

    conda "bioconda::nonpareil=3.4.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nonpareil:3.4.1--r42h9f5acd7_2' :
        'quay.io/biocontainers/nonpareil:3.4.1--r42h9f5acd7_2' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.npo")           , emit: npo
    tuple val(meta), path("*.npa")           , emit: npa
    tuple val(meta), path("*.npc")           , emit: npc
    tuple val(meta), path("*.npl")           , emit: npl
    path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: 
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cmd  = "$reads".endsWith(".gz") ? "zcat" : "cat"
    def input_type = ( "$reads".contains("fastq") || "$reads".contains("fq") ) ? "fastq" : "fasta"
    def input_data  = ("$reads".contains("fastq")) && !meta.single_end ? "${reads[0]}" : "$reads"
    """
    if [ "${input_type}" == "fastq" ]; then
        $cmd ${input_data} | paste - - - - | awk 'BEGIN { FS="\t" } { print ">"substr(\$1,2)"\n"\$2}' > reads.fasta
    else 
        $cmd ${input_data} > reads.fasta
    fi
    nonpareil \\
        -s reads.fasta \\
        -T kmer \\
        -t $task.cpus \\
        -b ${meta.id} \\
        $args
    rm reads.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nonpareil: \$(echo \$(nonpareil -V 2>&1) | cut -f2 | sed '/v//')
    END_VERSIONS
    """
}