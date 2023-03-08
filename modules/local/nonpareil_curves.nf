process NONPAREIL_CURVES {
    label 'process_low'

	conda "bioconda::nonpareil=3.4.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nonpareil:3.4.1--r42h9f5acd7_2' :
        'quay.io/biocontainers/nonpareil:3.4.1--r42h9f5acd7_2' }"

    input:
    path(samplesheet)

    output:
	path("*.tif")              , emit: tif
	
    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
	#!/usr/bin/env Rscript --vanilla

    library(Nonpareil)
    samples <- as.data.frame(read.table("${samplesheet}", sep="\\t", header=FALSE, as.is=TRUE))
    colnames(samples) <- c("File", "Name", "Col")
    img <- tiff(file="${prefix}.tif", res=300, compression="lzw", height=2250, width=3000)
    attach(samples)
    nps <- Nonpareil.set(File, col=Col, labels=Name, plot.opts=list(plot.observed=FALSE))
    detach(samples)
    dev.off()
    summary(nps)
    """
}
