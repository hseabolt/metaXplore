//
// Compute Pavian reports from Kraken2 classifications
//

include { PAVIAN     } from '../../modules/local/pavian/pavian'

workflow PAVIAN_INDIVIDUAL {
    
    take:
    kreport
    scrubbed_kreport

    main:
    PAVIAN(kreport, scrubbed_kreport)

    emit:
    PAVIAN.out.pavian_out
}

workflow PAVIAN_SUMMARY {
    
    take:
    kreport
    scrubbed_kreport

    main:
    PAVIAN(kreport, scrubbed_kreport)

    emit:
    PAVIAN.out.pavian_summary_out
}