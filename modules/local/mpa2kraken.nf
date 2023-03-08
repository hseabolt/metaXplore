process MPA2KRAKEN {
    tag "$meta.id"
    label "process_low"

    conda "conda-forge::perl=5.26.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'quay.io/biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(mpa_report)

    output:
    tuple val(meta), path("*.kraken2.report.txt")      , emit: report
    
    when:
    task.ext.when == null || task.ext.when

    script: // This script is packaged alongside the MetaXplore workflow
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mpa2kraken --input ${mpa_report} --output ${meta.id}.kraken2.report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        map2kraken: \$(echo \$(mpa2kraken --version 2>&1) | cut -f2 | sed '/v//')
    END_VERSIONS
    """
}