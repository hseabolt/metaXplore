process FQ2FA {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::seqkit=2.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.1.0--h9ee0642_0':
        'quay.io/biocontainers/seqkit:2.1.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("*.fasta*"), emit: fasta

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input = meta.single_end ? "${fastq}" :  "${fastq[0]}" 
    def extension = fastq[0].endsWith('.gz') ? 'fasta.gz' : 'fasta'
    """
    seqkit fq2fa \\
        $args \\
        --threads ${task.cpus} \\
        -o ${prefix}.${extension} \\
        $input
    """
}