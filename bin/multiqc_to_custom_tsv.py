#!/usr/bin/env python
# copied from nf-core/viralrecon and adjusted

import os
import sys
import errno
import argparse
import yaml


def parse_args(args=None):
    Description = (
        "Create custom spreadsheet for pertinent MultiQC bowtie 2 metrics generated by the nf-core/mag pipeline."
    )
    Epilog = "Example usage: python multiqc_to_custom_tsv.py"
    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument(
        "-md",
        "--multiqc_data_dir",
        type=str,
        dest="MULTIQC_DATA_DIR",
        default="multiqc_data",
        help="Full path to directory containing YAML files for each module, as generated by MultiQC. (default: 'multiqc_data').",
    )
    parser.add_argument(
        "-se",
        "--single_end",
        dest="SINGLE_END",
        action="store_true",
        help="Specifies that the input is single-end reads.",
    )
    return parser.parse_args(args)


def make_dir(path):
    if not len(path) == 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise


# Find key in dictionary created from YAML file recursively
# From https://stackoverflow.com/a/37626981
def find_tag(d, tag):
    if tag in d:
        yield d[tag]
    for k, v in d.items():
        if isinstance(v, dict):
            for i in find_tag(v, tag):
                yield i


def yaml_fields_to_dict(YAMLFile, AppendDict={}, FieldMappingList=[]):
    with open(YAMLFile) as f:
        yaml_dict = yaml.safe_load(f)
        for k in yaml_dict.keys():
            key = k
            if key not in AppendDict:
                AppendDict[key] = {}
            if FieldMappingList != []:
                for i, j in FieldMappingList:
                    val = list(find_tag(yaml_dict[k], j[0]))
                    if len(val) != 0:
                        val = val[0]
                        if len(j) == 2:
                            val = list(find_tag(val, j[1]))[0]
                        if i not in AppendDict[key]:
                            AppendDict[key][i] = val
                        else:
                            print(
                                "WARNING: {} key already exists in dictionary so will be overwritten. YAML file {}.".format(
                                    i, YAMLFile
                                )
                            )
            else:
                AppendDict[key] = yaml_dict[k]
    return AppendDict


# customized
def metrics_dict_to_file(FileFieldList, MultiQCDataDir, OutFile, se):
    MetricsDict = {}
    FieldList = []
    for yamlFile, mappingList in FileFieldList:
        yamlFile = os.path.join(MultiQCDataDir, yamlFile)
        if os.path.exists(yamlFile):
            MetricsDict = yaml_fields_to_dict(YAMLFile=yamlFile, AppendDict=MetricsDict, FieldMappingList=mappingList)
            FieldList += [x[0] for x in mappingList]
        else:
            print("WARNING: File does not exist: {}".format(yamlFile))

    if MetricsDict != {}:
        make_dir(os.path.dirname(OutFile))
        with open(OutFile, "w") as fout:
            if se:
                fout.write(
                    "{}\n".format("\t".join(["Sample", "SE reads not mapped (kept)", "SE reads mapped (discarded)"]))
                )
            else:
                fout.write(
                    "{}\n".format(
                        "\t".join(
                            [
                                "Sample",
                                "PE reads not mapped concordantly (kept)",
                                "PE reads mapped concordantly (discarded)",
                            ]
                        )
                    )
                )
            for k in sorted(MetricsDict.keys()):
                # write out # not mapped reads and # mapped reads (uniquely + multi mapping reads)
                fout.write(
                    "{}\n".format(
                        "\t".join(
                            [
                                k,
                                str(MetricsDict[k][FieldList[0]]),
                                str(MetricsDict[k][FieldList[1]] + MetricsDict[k][FieldList[2]]),
                            ]
                        )
                    )
                )
    return MetricsDict


def main(args=None):
    args = parse_args(args)

    ## File names for MultiQC YAML along with fields to fetch from each file
    Bowtie2FileFieldList = []
    if args.SINGLE_END:
        Bowtie2FileFieldList = [
            (
                "multiqc_bowtie2.yaml",
                [
                    ("# Not mapped reads", ["unpaired_aligned_none"]),
                    ("# Mapped reads 1", ["unpaired_aligned_one"]),
                    ("# Mapped reads multi", ["unpaired_aligned_multi"]),
                ],
            ),
        ]
    else:
        Bowtie2FileFieldList = [
            (
                "multiqc_bowtie2.yaml",
                [
                    ("# Not mapped reads", ["paired_aligned_none"]),
                    ("# Mapped reads 1", ["paired_aligned_one"]),
                    ("# Mapped reads multi", ["paired_aligned_multi"]),
                ],
            ),
        ]

    ## Write Bowtie 2 metrics to file
    metrics_dict_to_file(
        FileFieldList=Bowtie2FileFieldList,
        MultiQCDataDir=args.MULTIQC_DATA_DIR,
        OutFile="host_removal_metrics.tsv",
        se=args.SINGLE_END,
    )


if __name__ == "__main__":
    sys.exit(main())