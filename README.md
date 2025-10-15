# The Data Preprocessing workflow

## Summary
This repository is based off JGI's metatranscriptomic analysis package for transcriptomic reads and uses SAMTOOLS (1.15) in the pipeline `ReadCov.py` to generate a tab separated read count file from BAM and GFF files. 

## Running Workflow in Cromwell

Description of the files:
 - `.wdl` file: the WDL file for workflow definition
 - `.json` file: the example input for the workflow
 - `.conf` file: the conf file for running Cromwell.
 - `.sh` file: the shell script for running the example workflow


## The Docker image and Dockerfile can be found here

[dongyingwu/rnaseqct:2.0](https://hub.docker.com/r/dongyingwu/rnaseqct/)


## Input files

The inputs for this workflow are as follows:

1. project name 
2. BAM File 
3. GFF File
4. (optional) Map file
5. (optional) RNA type
6. (optional) Read group file
7. (optional) Memory and time 

```
{
    "readcount.proj_id":"nmdc:xxxxxxx",
    "readcount.bam": "./test_files/nmdc_xxxxxxx_pairedMapped_sorted.bam",
    "readcount.gff": "./test_files/nmdc_xxxxxxx_functional_annotation.gff",
    "readcount.rna_type": "RNA",
    "readcount.map": "./test_files/mapfile.map"
}
```

The map file connects the naming schemes between the GFF and BAM files. If the naming scheme is the same, the map file can either be generated automatically if none is specified, or user can make a tsv with two columns of the names from the GFF file. 
The RNA type inputs are include `RNA`, `aRNA` (antisense RNA), `non_stranded_RNA` (nonstranded). This is the explanation from the script itself:

```
    -aRNA: yes (means use antisense reads during counting,default no)
    -non_stranded: yes (for cDNA input, default no, override "-aRNA yes" if "-non_stranded yes")
```

## Script

The script is called as such within the WDL.

```
   ReadCov.py  \
      -b ~{bam} \               # input BAM
      -m ~{map} \               # map file auto generated or user upload
      -g ~{gff} \               # input GFF
      -o final_output/~{out} \  # prefix for output files (project ID)
      ~{rna_type}               # RNA, aRNA, non_stranded_RNA
```

## Output files

The output will have one directory named by prefix project name and a bunch of output files, including statistical numbers, status log, and run information. 

The main read count table output is named by prefix.readcount. 

```
|-- nmdc_xxxxxxx_readcount.info
|-- nmdc_xxxxxxx.readcount.stats.log
|-- nmdc_xxxxxxx.rnaseq_gea.intergenic.txt
|-- nmdc_xxxxxxx.rnaseq_gea.txt
```

### Columns in the data file

| Column | Description |
| ------------- | ------------- |
| `img_gene_oid` | gene_oid of the gene for which expression is counted |
| `img_scaffold_oid` | scaffold/contig id on which the gene has been predicted |
| `locus_tag` | another gene id of the gene for which expression is counted; this is included because all genomes and some metagenomes and metatranscriptomes used as references have both gene oids and locus tags, while others don't |
| `scaffold_accession` | another identifier of scaffold/contig on which the gene has been predicted |
| `strand` | strand on which the gene has been predicted |
| `locus_type` | type of the gene; for example CDS (protein-coding gene), tRNA, rRNA, tmRNA, etc. |
| `length` | length of the gene for which expression is counted |
| `reads_cnt` | number of reads mapped on the same strand as predicted gene within the coordinates of the gene |
| `mean` | mean expression of the predicted gene, i. e. mean per-base coverage of the strand on which the gene was predicted within the coordinates of the predicted gene |
| `median` | median expression of the predicted gene, i. e. median per-base coverage of the strand on which the gene was predicted within the coordinates of the predicted gene |
| `stdev` | standard deviation of the expression of the predicted gene |
| `reads_cntA` | number of reads mapped to the opposite strand of the predicted gene within the coordinates of the gene |
| `meanA` | mean expression of the opposite strand of the predicted gene, i. e. mean per-base coverage of the strand opposite to that on which the gene was predicted within the coordinates of the predicted gene |
| `medianA` | median expression of the opposite strand of the predicted gene, i. e. median per-base coverage of the strand opposite to that on which the gene was predicted within the coordinates of the predicted gene |
| `stdevA` | standard deviation of the expression of the opposite strand of the predicted gene |


For more information, please refer to the [IMG documentation](https://bitbucket.org/dongyingwu/dywu_wdl/src/main/README.txt).