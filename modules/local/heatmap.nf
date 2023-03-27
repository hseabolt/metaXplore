process HEATMAP {
    tag "$meta.id"
    label 'process_low'
    label 'error_ignore'

	conda "conda-forge::r-ggplot2=3.4.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-genomicsupersignature:1.6.0--r42hdfd78af_0' :
        'quay.io/biocontainers/bioconductor-genomicsupersignature:1.6.0--r42hdfd78af_0' }"

    input:
    tuple val(meta), path(tsv_file)

    output:
	tuple val(meta), path("*.png")              , emit: heatmap
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
	#!/usr/bin/env Rscript --vanilla
    library(ggplot2)
    library(reshape2)
    heats = as.matrix(read.table(file="${tsv_file}", sep="\\t", header=T, row.names=1))
    heats = as.data.frame(melt(heats))
    ggplot(heats, aes(Var1, Var2, fill=value)) + geom_tile(color="black") + 
        theme(axis.text.x=element_text(angle=45, vjust=0.85, hjust=1)) +
        xlab("Library 1") + ylab("Library 2") + 
        labs(value="Distance")
    ggsave("${prefix}.png", dpi=300, height=8, width=8, units="in")
    """
}
