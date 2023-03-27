process KRONA {
    // Module citation: https://github.com/nf-core/mag/blob/master/modules/local/krona.nf
    tag "${meta.classifier}-${meta.id}"

    conda "bioconda::krona=2.7.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/krona:2.7.1--pl526_5' :
        'quay.io/biocontainers/krona:2.7.1--pl526_5' }"

    input:
    tuple val(meta), path(report)
    path  "taxonomy/taxonomy.tab"

    output:
    path "*.html"       , emit: html
    path "versions.yml" , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ktImportTaxonomy "$report" -tax taxonomy -o ${prefix}_Krona_mqc.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ktImportTaxonomy: \$(ktImportTaxonomy 2>&1 | sed -n '/KronaTools /p' | sed 's/^.*KronaTools //; s/ - ktImportTaxonomy.*//')
    END_VERSIONS
    """
}