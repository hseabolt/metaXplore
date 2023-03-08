process KRONA_DB {
    // Module citation: https://github.com/nf-core/mag/blob/master/modules/local/krona_db.nf

    conda "bioconda::krona=2.7.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/krona:2.7.1--pl526_5' :
        'quay.io/biocontainers/krona:2.7.1--pl526_5' }"

    output:
    path("taxonomy/taxonomy.tab"), emit: db
    path "versions.yml"          , emit: versions

    script:
    """
    ktUpdateTaxonomy.sh taxonomy
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ktImportTaxonomy: \$(ktImportTaxonomy 2>&1 | sed -n '/KronaTools /p' | sed 's/^.*KronaTools //; s/ - ktImportTaxonomy.*//')
    END_VERSIONS
    """
}