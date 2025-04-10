# metaT read count workflow
version 1.0

workflow readcount {

  input{
    String proj_id
    String bam
    String gff
    String? map
    String rna_type = " "
    String container = "dongyingwu/rnaseqct@sha256:e7418cc7a5a58eb138c3b739608d2754a05fa3648b5881befbfbb0bb2e62fa95"
    Int cpu = 1
    String memory = "100G"
    String time = "360"
  }

  call prepare {
    input: 
    rna_type=rna_type,
    gff = gff,
    bam = bam, 
    map_in = map,
    container = container,
    cpu = cpu,
    memory = memory,
    time = time
    }

  call count {
    input: 
    # bam = prepare.renamed_bam, 
    # gff = prepare.renamed_gff, 
    bam = bam,
    gff = gff,
    proj_id = proj_id,
    map = prepare.map_out, 
    rna_type=prepare.type_list[0], 
    container = container,
    cpu = cpu,
    memory = memory,
    time = time
    } 

  call make_info_file{
    input:
    container = container,
    cpu = cpu,
    memory = memory,
    time = time,
    proj_id = proj_id
  }

  call finish_count {
    input:
    proj_id = proj_id, 
    count_table = count.tab,
    count_ig = count.ig,
    count_log = count.log,
    readcount_info = make_info_file.readcount_info,
    container = container,
    cpu = cpu,
    memory = memory,
    time = time
  }

  output{
   File count_table = finish_count.final_count_table
    File? count_ig = finish_count.final_count_ig
    File? count_log = finish_count.final_count_log
    File readcount_info = finish_count.final_readcount_info
   
  }
  parameter_meta {
	  proj_id: "NMDC project ID"
    bam: "BAM file output from MetaT Assembly"
    gff: "Functional GFF file output from MetaG Annotation"
    out: "Out directory or string to name files"
    rna_type: "RNA strandedness, default blank, 'aRNA', or 'non_stranded_RNA'"
	}
}

task prepare  {
  input{
    String? rna_type 
    File bam
    String out_bam = "renamed_input.bam"
    File gff
    String out_gff = "renamed_input.gff"
    File? map_in
    Boolean mapped = if (defined(map_in)) then true else false
    String mapfile = "mapfile.map" 
    String container
    Int cpu
    String memory
    String time
  }

  command <<<
    set -eou pipefail
    # rename bam and gff file to recognize suffix from URL submission 
    ln -s ~{bam} ./~{out_bam} || ln ~{bam} ./~{out_bam}
    ln -s ~{gff} ./~{out_gff} || ln ~{gff} ./~{out_gff}


    # generate map file from gff scaffold names
    if [ "~{mapped}"  = true ] ; then
      ln -s ~{map_in} ~{mapfile} || ln ~{map_in} ~{mapfile}  
      else  
          awk '{print $1 "\t" $1}' ~{gff} > ~{mapfile}
     fi

    if [ ~{rna_type} == 'aRNA' ]
      then 
        echo '-aRNA yes'
    elif [ ~{rna_type} == 'non_stranded_RNA' ] 
      then
        echo '-non_stranded yes'
    else
        echo '  '
    fi
  >>>

  output{
    File renamed_bam = out_bam
    File renamed_gff = out_gff
    File map_out = "mapfile.map" 
    Array[String] type_list=read_lines(stdout())
   }

   runtime {
        docker: container
        cpu: cpu
        memory: memory
        runtime_minutes: time
    }
 }


task count {
  input{
    File bam
    File map
    File gff
    String proj_id
    String prefix=sub(proj_id, ":", "_")
    String rna_type
    String container
    Int cpu
    String memory
    String time
  }

  command <<< 
  set -eou pipefail
    ls -lah /usr/bin/readCov_metaTranscriptome_2k20.pl
    readCov_metaTranscriptome_2k20.pl  \
    -b ~{bam} \
    -m ~{map} \
    -g ~{gff} \
    -o "~{prefix}.rnaseq_gea" \
    ~{rna_type}
    >>>

  output{
   File   tab = "~{prefix}.rnaseq_gea"
   File? log="~{prefix}.rnaseq_gea.Stats.log"
   File? ig="~{prefix}.rnaseq_gea.intergenic"
  }
 
    runtime {
        docker: container
        cpu: cpu
        memory: memory
        runtime_minutes: time
    }

}

task make_info_file {
  input{
    String container
    Int cpu
    String memory
    String time
    String proj_id
    String prefix = sub(proj_id, ":", "_")
  }

  command <<< 
  set -euo pipefail
  echo -e "MetaT Workflow - Read Counts Info File" > ~{prefix}_readcount.info
  echo -e "This workflow outputs a tab separated read count file from BAM and GFF using SAMTOOLS(1):" >> ~{prefix}_readcount.info
  echo -e "`samtools --version | head -2`"  >> ~{prefix}_readcount.info

  echo -e "\nContainer: ~{container}"  >> ~{prefix}_readcount.info
  
  echo -e "\n(1) Danecek, P., Bonfield, J. K., Liddle, J., Marshall, J., Ohan, V., Pollard, M. O., Whitwham, A., Keane, T., McCarthy, S. A., Davies, R. M., & Li, H. (2021). Twelve years of samtools and bcftools. GigaScience, 10(2), giab008. https://doi.org/10.1093/gigascience/giab008" >>  ~{prefix}_readcount.info # samtools

    >>>

  output{
   File readcount_info = "~{prefix}_readcount.info"
  }
 
    runtime {
        docker: container
        cpu: cpu
        memory: memory
        runtime_minutes: time
    }

}

task finish_count {
  input {
    File   count_table
    File?  count_log
    File?  count_ig
    File   readcount_info
    String proj_id
    String prefix=sub(proj_id, ":", "_")
    String container
    Int cpu
    String memory
    String time
  }

    command<<<

        set -oeu pipefail
        end=`date --iso-8601=seconds`
        ln ~{count_table} ~{prefix}.rnaseq_gea.txt || ln -s ~{count_table} ~{prefix}.rnaseq_gea.txt
        ~{if defined(count_ig) then "ln ~{count_ig} ~{prefix}.rnaseq_gea.intergenic.txt || ln -s ~{count_ig} ~{prefix}.rnaseq_gea.intergenic.txt" else ""}
        ~{if defined(count_log) then "ln ~{count_log} ~{prefix}.readcount.stats.log || ln -s ~{count_log} ~{prefix}.readcount.stats.log" else ""}
        ln ~{readcount_info} ~{prefix}_readcount.info || ln -s ln ~{readcount_info} ~{prefix}_readcount.info


    >>>
    output {
        File final_count_table = "~{prefix}.rnaseq_gea.txt"
        File? final_count_ig = "~{prefix}.rnaseq_gea.intergenic.txt"
        File? final_count_log = "~{prefix}.readcount.stats.log"
        File final_readcount_info = "~{prefix}_readcount.info"
    }

    runtime {
        docker: container
        cpu: cpu
        memory: memory
        runtime_minutes: time
    }
}