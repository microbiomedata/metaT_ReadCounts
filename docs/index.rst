MetaT Read Counts Workflow (v0.0.5)
=============================

.. image:: mt_rc_workflow2024.png
   :align: center
   :scale: 50%


Workflow Overview
-----------------
This workflow generates tab separated read count files from BAM and GFF files. 
The repository is based off JGI's metatranscriptomic analysis package for transcriptomic reads and uses SAMTOOLS (1.15) in the pipeline `readCov_metaTranscriptome_2k20.pl`.

The script is called as such within the WDL.

.. code-block:: 
   readCov_metaTranscriptome_2k20.pl \
         -b ~{bam} \       # input BAM
         -m ~{map} \       # map file auto generated or user upload
         -g ~{gff} \       # input GFF
         -o ~{out} \       # prefix for output files (project ID)
         ~{rna_type}       # left blank, '-aRNA yes', or '-non_stranded yes'


Workflow Availability
---------------------
The workflow is available in GitHub: https://github.com/microbiomedata/metaT_ReadCounts/ and the corresponding Docker image is available in DockerHub: 
- `dongyingwu/rnaseqct:1.1 <https://hub.docker.com/r/dongyingwu/rnaseqct>`_


Requirements for Execution (recommendations are in bold):  
---------------------------------------------------------

- WDL-capable Workflow Execution Tool **(Cromwell)**
- Container Runtime that can load Docker images **(Docker v2.1.0.3 or higher)**

Hardware Requirements: 
----------------------
- Memory: >100 GB RAM

Workflow Dependencies
---------------------
- Third party software (This is included in the Docker image.)  
   - samtools 1.15
   - readCov_metaTranscriptome_2k20.pl


Sample datasets
---------------
[to come]


Input
------
 A JSON file containing the following: 

1. project name 
2. BAM File 
3. GFF File
4. (optional) Map file
5. (optional) RNA type

An example JSON file is shown below:

.. code-block:: JSON
   {
      "readcount.proj_id":"nmdc:xxxxxxx",
      "readcount.bam": "./test_files/nmdc_xxxxxxx_pairedMapped_sorted.bam",
      "readcount.gff": "./test_files/nmdc_xxxxxxx_functional_annotation.gff",
      "readcount.rna_type": "aRNA",
      "readcount.map": "./test_files/mapfile.map"
   }


The map file connects the naming schemes between the GFF and BAM files. If the naming scheme is the same, the map file can either be generated automatically if none is specified, or user can make a tsv with two columns of the names from the GFF file. 
The RNA type inputs are include nothing, `aRNA`, or `non_stranded_RNA`, which are transformed to script inputs `(default)`, `-aRNA yes`, or `-non_stranded yes`, respectively. This is the explanation from the script itself:

.. code-block:: 
    -aRNA: yes (means use antisense reads during counting,default no)
    -non_stranded: yes (for cDNA input, default no, override "-aRNA yes" if "-non_stranded yes")



Output
------

The output will have one directory named by prefix project name and output files including count statistics, status log, and run information. 

The main read count table output is named by prefix.readcount. 
 
 - nmdc_xxxxxxx.rnaseq_gea.txt
 - nmdc_xxxxxxx.rnaseq_gea.intergenic.txt
 - nmdc_xxxxxxx.readcount.stats.log
 - nmdc_xxxxxxx_readcount.info


### Description of IMG metatranscriptome data file.

IMG provides expression values and read counts for gene features predicted on the contigs, be it self-assembly of metatranscriptome or another dataset to which the metatranscriptome reads were mapped. Expression values are computed as mean and median per-base coverage of the sequence within the coordinates of the feature.

Since JGI generally generates stranded libraries, expression values and read counts for two strands are computed and reported separately. These values are NOT expression values and read counts of direct and reverse strand of the contig; instead these are expression values and read counts of the predicted feature (i. e. reads generated for the same strand on which the feature was predicted) and of the opposite strand of the predicted feature. Essentially this "expected" read coverage (in a sense of being generated from the strand that we expect to be expressed) and "unexpected" read coverage (i. e. generated from the strand that we did not expect to be expressed based on structural annotation of the sequence). For obvious reasons, some of the "unexpected" coverage is the result of imperfect structural annotation, which is not uncommon for short contigs in metaT self assembly.

Specific columns in the file:
============================ ============================================================================
Column                        Description
============================ ============================================================================
`img_gene_oid`                gene_oid of the gene for which expression is counted
`img_scaffold_oid`            scaffold/contig id on which the gene has been predicted
`locus_tag`                   another gene id of the gene for which expression is counted; this is included because all genomes and some metagenomes and metatranscriptomes used as references have both gene oids and locus tags, while others don't
`scaffold_accession`          another identifier of scaffold/contig on which the gene has been predicted
`strand`                      strand on which the gene has been predicted
`locus_type`                  type of the gene; for example CDS (protein-coding gene), tRNA, rRNA, tmRNA, etc.
`length`                      length of the gene for which expression is counted
`reads_cnt`                   number of reads mapped on the same strand as predicted gene within the coordinates of the gene
`mean`                        mean expression of the predicted gene, i. e. mean per-base coverage of the strand on which the gene was predicted within the coordinates of the predicted gene
`median`                       median expression of the predicted gene, i. e. median per-base coverage of the strand on which the gene was predicted within the coordinates of the predicted gene
`stdev`                       standard deviation of the expression of the predicted gene
`reads_cntA`                  number of reads mapped to the opposite strand of the predicted gene within the coordinates of the gene
`meanA`                       mean expression of the opposite strand of the predicted gene, i. e. mean per-base coverage of the strand opposite to that on which the gene was predicted within the coordinates of the predicted gene
`medianA`                     median expression of the opposite strand of the predicted gene, i. e. median per-base coverage of the strand opposite to that on which the gene was predicted within the coordinates of the predicted gene
`stdevA`                      standard deviation of the expression of the opposite strand of the predicted gene
