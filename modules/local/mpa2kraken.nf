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
    tuple val(meta), path("*.krona.report.txt")        , emit: results_for_krona
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is packaged alongside the MetaXplore workflow
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '0.1.0'  // WARN: Increment this version number when using a newer version of this binary
    """
    mpa2kraken --input ${mpa_report} --output ${meta.id}.kraken2.report.txt --krona ${meta.id}.krona.report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mpa2kraken: ${VERSION}
    END_VERSIONS
    """
}