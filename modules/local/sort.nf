process SORT {
	tag "$meta.id"
    label 'process_low'

    conda "conda-forge::pigz=2.3.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4' :
        'quay.io/biocontainers/pigz:2.3.4' }"

    input:
    tuple val(meta), path(file_in)

    output:
    tuple val(meta), path("*.tsv"), emit: file_out
	
    when:
    task.ext.when == null || task.ext.when

    script:  
	def args = task.ext.args ?: ''
    def header = task.ext.header ?: ''
    def prefix = task.ext.prefix ?: "${file_in.SimpleName}"
    """
    echo -e ${header} > ${prefix}.tsv
	grep -v "^#" ${file_in} | sort $args >> ${prefix}.tsv
    """
}