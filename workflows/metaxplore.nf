/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def valid_params = [
    classifier       : ['kraken2', 'metaphlan4']
]

// Validate input parameters
WorkflowMetaxplore.initialise(params, log, valid_params)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.db, params.bracken_db, params.host_fasta ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// SUBWORKFLOWS
include { INPUT_CHECK                                        } from '../subworkflows/local/input_check'

// MODULES
include { FASTQC                                             } from '../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_TRIMMED                           } from '../modules/nf-core/fastqc/main'
include { BOWTIE2_REMOVAL_ALIGN                              } from '../modules/local/bowtie2_removal_align'
include { BOWTIE2_REMOVAL_BUILD                              } from '../modules/local/bowtie2_removal_build'
include { MINIMAP2_ALIGN                                     } from '../modules/nf-core/minimap2/align/main'
include { SAMTOOLS_INDEX                                     } from '../modules/nf-core/samtools/index/main'
include { SAMTOOLS_STATS                                     } from '../modules/nf-core/samtools/stats/main'
include { SAMTOOLS_COVERAGE                                  } from '../modules/nf-core/samtools/coverage/main'
include { MULTIQC                                            } from '../modules/nf-core/multiqc/main'
include { KRAKEN2_DB_PREPARATION                             } from '../modules/local/kraken2_db_preparation'
include { KRAKEN2                                            } from '../modules/local/kraken2'
include { BRACKEN_BRACKEN as BRACKEN                         } from '../modules/nf-core/bracken/bracken/main'
include { MASHTREE                                           } from '../modules/nf-core/mashtree/main'
include { HEATMAP                                            } from '../modules/local/heatmap'
include { FQ2FA                                              } from '../modules/local/fq2fa'
include { CAT_CAT as CAT                                     } from '../modules/nf-core/cat/cat/main'
include { SORT                                               } from '../modules/local/sort'
include { FASTP                                              } from '../modules/nf-core/fastp/main'
include { KRAKENTOOLS_COMBINEKREPORTS as COMBINEKREPORTS     } from '../modules/nf-core/krakentools/combinekreports/main'
include { METAPHLAN4_METAPHLAN4 as METAPHLAN4                } from '../modules/local/metaphlan4'
include { METAPHLAN3_MERGEMETAPHLANTABLES as MERGEMPATABLES  } from '../modules/nf-core/metaphlan3/mergemetaphlantables/main'
include { MPA2KRAKEN                                         } from '../modules/local/mpa2kraken'
include { MERGE_KRAKEN_TABLES                                } from '../modules/local/merge_kraken_tables'
include { NONPAREIL                                          } from '../modules/local/nonpareil'
include { CREATE_NONPAREIL_SAMPLESHEET                       } from '../modules/local/create_nonpareil_samplesheet'
include { NONPAREIL_CURVES                                   } from '../modules/local/nonpareil_curves'
include { KRONA_DB                                           } from '../modules/local/krona_db'
include { KRONA                                              } from '../modules/local/krona'
include { CUSTOM_DUMPSOFTWAREVERSIONS                        } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow METAXPLORE {

    ch_versions = Channel.empty()
    ch_reads    = Channel.empty()
    ch_host_fasta = params.host_fasta ? Channel.value(file( "${params.host_fasta}" )) : Channel.empty()
    ch_target_genome = params.target_genome ? Channel.value(file( "${params.target_genome}" )) : Channel.empty()
    ch_kraken2_db = ( params.db && params.classifier == 'kraken2' ) ? Channel.value(file( "${params.db}" )) : Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_reads    = INPUT_CHECK.out.reads
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_reads
    )
    ch_versions = ch_versions.mix(FASTQC.out.versions)

    //
    // Remove host reads, if user provides a host genome FASTA
    // Credit: nf-core/mag
    //
    ch_bowtie2_removal_host_multiqc = Channel.empty()
    if ( params.host_fasta ) {
        BOWTIE2_HOST_REMOVAL_BUILD (
            ch_host_fasta
        )
        ch_host_bowtie2index = BOWTIE2_HOST_REMOVAL_BUILD.out.index
        BOWTIE2_HOST_REMOVAL_ALIGN (
            ch_reads,
            ch_host_bowtie2index
        )
        ch_reads = BOWTIE2_HOST_REMOVAL_ALIGN.out.reads
        ch_bowtie2_removal_host_multiqc = BOWTIE2_HOST_REMOVAL_ALIGN.out.log
        ch_versions = ch_versions.mix(BOWTIE2_HOST_REMOVAL_ALIGN.out.versions)
    }

    //
    // MODULE: Trim reads with Fastp
    //
    ch_reads_for_np       = Channel.empty()
    ch_reads_for_taxonomy = Channel.empty()
    ch_trimmed_reads      = Channel.empty()
    FASTP (
        ch_reads, [], false, false
    )
    ch_versions = ch_versions.mix(FASTP.out.versions)
    ch_reads_for_np       = ch_reads_for_np.mix(FASTP.out.reads)
    ch_reads_for_taxonomy = ch_reads_for_taxonomy.mix(FASTP.out.reads)
    ch_trimmed_reads      = ch_trimmed_reads.mix(FASTP.out.reads)

    FASTQC_TRIMMED (
        ch_trimmed_reads
    )

    // Map reads against a target genome if a target is provided, and compute some stats from this file
     ch_coverage = Channel.empty()
    if ( params.target_genome ) {
        MINIMAP2_ALIGN (
            ch_trimmed_reads, ch_target_genome, true, false, false
        )
        SAMTOOLS_INDEX (
            MINIMAP2_ALIGN.out.bam
        )
        ch_bam = MINIMAP2_ALIGN.out.bam.join(SAMTOOLS_INDEX.out.bai)
        SAMTOOLS_STATS (
            ch_bam, ch_target_genome
        )
        SAMTOOLS_COVERAGE (
            ch_bam
        )
        SAMTOOLS_COVERAGE.out.for_cat
            .collect{meta, tsv -> tsv}
            .map{ tsv -> [[id: "Coverage"], tsv]}
            .set{ ch_for_cat }
        CAT (
            ch_for_cat
        )
        SORT (
            CAT.out.file_out
        )
        ch_coverage = ch_coverage.mix(SORT.out.file_out)
    }

    // Estimate metagenome coverage and diversity with Nonpariel module
    NONPAREIL (
        ch_reads_for_np
    )
    ch_versions = ch_versions.mix(NONPAREIL.out.versions)
    CREATE_NONPAREIL_SAMPLESHEET (
        NONPAREIL.out.npo, "$baseDir/assets/Rcolors.txt"
    )
    ch_np_samplesheet = CREATE_NONPAREIL_SAMPLESHEET.out.samplesheet.collectFile(name: 'np.samplesheet.txt', newLine: true)
    NONPAREIL_CURVES (
        ch_np_samplesheet
    )

    // Estimate overall Jaccard-MinHash similarity between metagenomes with MashTree
    // TODO: set up logical handling to compute mashtree distances only if we have more than 1 sample
    FQ2FA (
        ch_trimmed_reads
    )
    FQ2FA.out.fasta
        .collect{meta, reads -> reads}
        .map{ reads -> [[id: "mashtree"], reads]}
        .set{ ch_mashtree }
    MASHTREE (
        ch_mashtree
    )
    // Plot a heatmap for MultiQC of pairwise Mash distances
    HEATMAP (
        MASHTREE.out.matrix
    )

    //
    // Classify trimmed reads with classifier of choice (by default: Kraken2)
    //
    ch_profiles          = Channel.empty()
    ch_combined_report   = Channel.empty()
    ch_results_for_krona = Channel.empty()
    ch_mpa_profiles      = Channel.empty()
    if ( params.classifier == 'metaphlan4' ) {
        METAPHLAN4 (
            ch_reads_for_taxonomy, params.db
        )
        ch_versions = ch_versions.mix(METAPHLAN4.out.versions)
        ch_profiles = ch_profiles.mix(METAPHLAN4.out.profile)
        
        // Merge MPA reports with utility program 
        ch_profiles.collect{meta, profile -> profile}.map{ profile -> [[id: "MPA_merged"], profile]}.set{ ch_merge_mpa }
        MERGEMPATABLES(
            ch_merge_mpa
        )
        ch_versions = ch_versions.mix(MERGEMPATABLES.out.versions)
        ch_combined_report = ch_combined_report.mix(MERGEMPATABLES.out.txt)

        // Transform the MPA report into a Kraken2-style report
        MPA2KRAKEN (
            ch_profiles
        )
        ch_mpa_profiles = ch_mpa_profiles.mix(MPA2KRAKEN.out.report)
        ch_versions = ch_versions.mix(MPA2KRAKEN.out.versions)
        ch_results_for_krona = ch_results_for_krona.mix(MPA2KRAKEN.out.results_for_krona)
    } else {
        KRAKEN2_DB_PREPARATION (
            ch_kraken2_db
        )
        KRAKEN2 ( 
            ch_reads_for_taxonomy, KRAKEN2_DB_PREPARATION.out.db
        )
        ch_versions = ch_versions.mix(KRAKEN2.out.versions)
        ch_profiles = ch_profiles.mix(KRAKEN2.out.report)
        ch_results_for_krona = ch_results_for_krona.mix(KRAKEN2.out.results_for_krona)
        
        // WARN: Bracken implementation here is experimental/under construction!
        if ( params.use_bracken ) {
            BRACKEN(
                ch_profiles, params.bracken_db
            )
            ch_versions = ch_versions.mix(BRACKEN.out.versions)
            ch_profiles = ch_profiles.mix(BRACKEN.out.reports)
        }

        // Merge Kraken2/Bracken reports with KrakenTools :: CombineKReports
        ch_profiles.collect{meta, report -> report}.map{ report -> [[id: "Kraken2_merged"], report]}.set{ ch_merge_kraken }
        COMBINEKREPORTS (
            ch_merge_kraken
        )
        ch_versions = ch_versions.mix(COMBINEKREPORTS.out.versions)
        ch_combined_report = COMBINEKREPORTS.out.txt
    }
    
    // 
    // SUBWORKFLOW: Visualize the classification reports with Krona
    //
    KRONA_DB ()
    KRONA (
        ch_results_for_krona,
        KRONA_DB.out.db.collect()
    )
    ch_versions = ch_versions.mix(KRONA.out.versions)

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowMetaxplore.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowMetaxplore.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_TRIMMED.out.zip.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_profiles.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_coverage.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(SAMTOOLS_STATS.out.stats.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(HEATMAP.out.heatmap.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_mpa_profiles.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(NONPAREIL_CURVES.out.png.collect())

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
