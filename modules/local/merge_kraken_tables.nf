process MERGE_KRAKEN_TABLES {
    tag "$meta.id"
    label "process_low"

    conda "conda-forge::perl=5.26.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(list)

    output:
    tuple val(meta), path("*.abundance_table.txt")      , emit: report
    
    when:
    task.ext.when == null || task.ext.when

    script: // This script is packaged alongside the MetaXplore workflow
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '0.1.0'  // WARN: Increment this version number when using a newer version of this binary
    """
    merge_kraken_tables --input ${list} --output ${meta.id}.abundance_table.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merge_kraken_tables: $VERSION
    END_VERSIONS
    """
}