process PAVIAN_SUMMARIZE {
    label 'process_medium'

    errorStrategy { task.attempt <= params.retryattemptMax ? 'retry' : 'ignore' }
    container "${baseDir}/assets/pavian.sif"

    input:
    path(my_reports)

    output:
    tuple val(meta), path("*.pav"), emit: pavian_summary_out

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    !# /usr/bin/R
    library(pavian)

    reports <- pavian::read_reports(${my_reports}, ${meta.id})
    samples_summary <- pavian::summarize_reports(reports)
    samples_summary <- samples_summary[,c(11,10,9,8,7,6,5,4,3,2,1)]
    write.table(samples_summary,"${meta.id}.summary.pav",sep="\t",row.names=TRUE)
    """
}
