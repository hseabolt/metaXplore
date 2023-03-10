# hseabolt/metaxplore: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

<!-- TODO nf-core: Write this documentation describing your workflow's output -->

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [FastQC](#fastqc) - Raw read QC
- [Host Removal](#bowtie2} - OPTIONAL: remove reads mapping to a user-provided host genome
- [FASTP](#fastp) - Read quality trimming, length filtering, adapter trimminer, etc.
- [Nonpareil](#nonpareil) - Estimate metagenome coverage and diversity
- [Kraken2](#kraken2) - Taxonomic classifier using exact k-mer matches
- [Bracken](#bracken) - Taxonomic classifier using k-mers and abundance estimations
- [MetaPhlAn4](#metaphlan4) - Genome-level marker gene based taxonomic classifier
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution


### FastQC

<details markdown="1">
<summary>Output files</summary>

- `fastqc/`
  - `*_fastqc.html`: FastQC report containing quality metrics.
  - `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

</details>

### FastQC

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. 

<details markdown="1">
<summary>Output files</summary>

- `QC_shortreads/fastqc/`
  - `[sample]_[1/2]_fastqc.html`: FastQC report, containing quality metrics for your untrimmed raw fastq files
  - `[sample].trimmed_[1/2]_fastqc.html`: FastQC report, containing quality metrics for trimmed and, if specified, filtered read files

</details>



### fastp

[fastp](https://github.com/OpenGene/fastp) is a all-in-one fastq preprocessor for read/adapter trimming and quality control. It is used in this pipeline for trimming adapter sequences and discard low-quality reads.

<details markdown="1">
<summary>Output files</summary>

- `QC_shortreads/fastp/[sample]/`
  - `fastp.html`: Interactive report
  - `fastp.json`: Report in json format

</details>

### Host read removal

The pipeline uses bowtie2 to map sequencing reads against a user-provbided host reference genome specified with `--host_fasta` and removes mapped reads.

<details markdown="1">
<summary>Output files</summary>

- `QC_shortreads/remove_host/`
  - `[sample].host_removed.bowtie2.log`: Contains the bowtie2 log file indicating how many reads have been mapped.
  - `[sample].host_removed.mapped*.read_ids.txt`: Contains a file listing the read ids of discarded reads.


### Nonpareil3

[Nonpareil3](https://journals.asm.org/doi/full/10.1128/mSystems.00039-18)





### Kraken

[Kraken2](https://link.springer.com/article/10.1186/s13059-019-1891-0) classifies reads using a k-mer based approach as well as assigns taxonomy using a Lowest Common Ancestor (LCA) algorithm.

<details markdown="1">
<summary>Output files</summary>

- `Taxonomy/kraken2/[sample]/`
  - `kraken2.report`: Classification in the Kraken report format. See the [kraken2 manual](https://github.com/DerrickWood/kraken2/wiki/Manual#output-formats) for more details
  - `taxonomy.krona.html`: Interactive pie chart produced by [KronaTools](https://github.com/marbl/Krona/wiki)

### Bracken (Workflow components under construction!)

[Bracken](https://ccb.jhu.edu/software/bracken/) (Bayesian Reestimation of Abundance with Kraken) uses the taxonomy labels assigned by Kraken to compute the abundance of species in DNA sequences from a metagenome. 

> This section is still under construction!

### Metaphlan4

[MetaPhlAn4](https://github.com/biobakery/metaphlan) is a classification tool for profiling the the abundance of species in DNA sequences from a metagenome via species-specific marker genes.

<details markdown="1">
<summary>Output files</summary>

- `metaphlan4/`
  - `metaphlan4_<db_name>_combined_reports.txt`: A combined profile of all samples aligned to a given database (as generated by `metaphlan_merge_tables`)
  - `<db_name>/`
    - `<sample_id>.biom`: taxonomic profile in BIOM format
    - `<sample_id>.bowtie2out.txt`: BowTie2 alignment information (can be re-used for skipping alignment when re-running MetaPhlAn3 with different parameters)
    - `<sample_id>_profile.txt`: MetaPhlAn3 taxonomic profile including abundance estimates

</details>

The main taxonomic profiling file from MetaPhlAn3 is the `*_profile.txt` file. This provides the abundance estimates from MetaPhlAn3 however does not include raw counts by default.

> Note: the current module is for Metaphlan4 but also supports Metaphlan3 databases!


### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
