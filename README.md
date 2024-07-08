# The Data Preprocessing workflow

## Summary
This repository is based off JGI's metatranscriptomic analysis package for transcriptomic reads and uses SAMTOOLS (1.15) in the pipeline `readCov_metaTranscriptome_2k20.pl` to generate a tab separated read count file from BAM and GFF files. 

## Running Workflow in Cromwell

Description of the files:
 - `.wdl` file: the WDL file for workflow definition
 - `.json` file: the example input for the workflow
 - `.conf` file: the conf file for running Cromwell.
 - `.sh` file: the shell script for running the example workflow


## The Docker image and Dockerfile can be found here

[dongyingwu/rnaseqct:1.1](https://hub.docker.com/r/dongyingwu/rnaseqct/)


## Input files

The inputs for this workflow are as follows:

1. project name 
2. BAM File 
3. GFF File
4. RNA type
5. (optional) Map file

```
{
    "readcount.proj_id":"nmdc:xxxxxxx",
    "readcount.bam": "./test_files/nmdc_xxxxxxx_pairedMapped_sorted.bam",
    "readcount.gff": "./test_files/nmdc_xxxxxxx_functional_annotation.gff",
    "readcount.rna_type": "aRNA",
    "readcount.map": "./test_files/mapfile.map"
}
```

The map file connects the naming schemes between the GFF and BAM files. If the naming scheme is the same, the map file can either be generated automatically if none is specified, or user can make a tsv with two columns of the names from the GFF file. The RNA type inputs are either `aRNA` or `non_stranded_RNA`, which are transformed to script inputs `-aRNA yes` or `-non_stranded yes`, respectively.

## Script

The script is called as such within the WDL.

```
  readCov_metaTranscriptome_2k20.pl  \
      -b ~{bam} \       # input BAM
      -m ~{map} \       # map file auto generated or user upload
      -g ~{gff} \       # input GFF
      -o ~{out} \       # prefix for output files (project ID)
      ~{rna_type}       # '-aRNA yes' or '-non_stranded yes'
```

## Output files

The output will have one directory named by prefix project name and a bunch of output files, including statistical numbers, status log, and run information. 

The main read count table output is named by prefix.readcount. 

```
|-- nmdc_xxxxxxx.readcount
|-- nmdc_xxxxxxx.readcount.intergenic
|-- nmdc_xxxxxxx.readcount.Stats.log
|-- nmdc_xxxxxxx_readcount.info
```