process CREATE_NONPAREIL_SAMPLESHEET {
    tag "$meta.id"
    label "process_low"

    conda "conda-forge::sed=4.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path(npo)
    path(colors)

    output:
    path("*.txt")           , emit: samplesheet

    when:
    task.ext.when == null || task.ext.when

    script: 
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    COL=`shuf -n 1 ${colors}`
    NPO=`realpath ${npo}`
    echo -e "\$NPO\\t${meta.id}\\t\$COL" > ${prefix}.np.txt
    """
}