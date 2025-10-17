# metaT read count workflow
version 1.0

import "https://bitbucket.org/dongyingwu/dywu_wdl/raw/1ab980f6141b4e4ec2e9e5ad046716a98d11452a/readcount.wdl" as rc 

workflow readcount {

  input{
    String  proj_id
    String  count_out = "rnaseq_gea"
    String  bam
    String  gff
    String? map
    String? rg_file
    String  rna_type = "RNA" # RNA, aRNA (antisense RNA), non_stranded_RNA (nonstranded)
    String  container = "dongyingwu/rnaseqct@sha256:e7418cc7a5a58eb138c3b739608d2754a05fa3648b5881befbfbb0bb2e62fa95"
    Int     cpu = 1
    String  memory = "10G"
    Int     time = 360
    String  rc_mem = "100G"
    String  rc_time = 360
  }

  call prepare {
    input: 
    gff = gff,
    map_in = map,
    container = container,
    cpu = cpu,
    memory = memory,
    time = time
    }

  call rc.readcount as count {
    input: 
    bam = bam,
    map = prepare.map_out, 
    gff = gff,
    rg_file = rg_file,
    out = count_out,
    type=rna_type, 
    memory = rc_mem,
    runtime_minutes = rc_time
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
    count_out = count_out,
    count_dir = count.final_output,
    readcount_info = make_info_file.readcount_info,
    container = container,
    cpu = cpu,
    memory = memory,
    time = time
  }

  output{
    File  count_table = finish_count.final_count_table
    File? count_ig = finish_count.final_count_ig
    File? count_log = finish_count.final_count_log
    File  readcount_info = finish_count.final_readcount_info
   
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
    File    gff
    File?   map_in
    Boolean mapped = if (defined(map_in)) then true else false
    String  mapfile = "mapfile.map" 
    String  container
    Int     cpu
    String  memory
    String  time
  }

  command <<<
    set -eou pipefail
    # generate map file from gff scaffold names
    if [ "~{mapped}"  = true ] ; then
      ln -s ~{map_in} ~{mapfile} || ln ~{map_in} ~{mapfile}  
    else  
      awk '{print $1 "\t" $1}' ~{gff} > ~{mapfile}
    fi

  >>>

  output{
    File map_out = "mapfile.map" 
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
    Int    cpu
    String memory
    String time
    String proj_id
    String prefix = sub(proj_id, ":", "_")
  }

  command <<< 
    set -euo pipefail
    echo -e "MetaT Workflow - Read Counts Info File" > ~{prefix}_readcount.info
    echo -e "This workflow outputs a tab separated read count file from BAM and GFF using SAMTOOLS(1):" >> ~{prefix}_readcount.info
    echo -e "See https://github.com/microbiomedata/metaT_ReadCounts or"  >> ~{prefix}_readcount.info
    echo -e "https://bitbucket.org/dongyingwu/dywu_wdl/src/main/README.txt for more details."  >> ~{prefix}_readcount.info
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
    File   count_dir
    File   readcount_info
    String proj_id
    String prefix=sub(proj_id, ":", "_")
    String count_out
    String container
    Int    cpu
    String memory
    String time
    String count_table = "~{count_dir}/~{count_out}"
    String count_ig="~{count_dir}/~{count_out}.intergenic"
    String count_log="~{count_dir}/~{count_out}.Stats.log"
  }

    command<<<
      set -oeu pipefail
      end=`date --iso-8601=seconds`
      ln ~{count_table} ~{prefix}.rnaseq_gea.txt || ln -s ~{count_table} ~{prefix}.rnaseq_gea.txt
      if [ -f "~{count_ig}" ]; then
        ln ~{count_ig} ~{prefix}.rnaseq_gea.intergenic.txt || ln -s ~{count_ig} ~{prefix}.rnaseq_gea.intergenic.txt
      fi
      if [ -f "~{count_log}" ]; then
        ln ~{count_log} ~{prefix}.readcount.stats.log || ln -s ~{count_log} ~{prefix}.readcount.stats.log
      fi
      ln ~{readcount_info} ~{prefix}_readcount.info || ln -s ln ~{readcount_info} ~{prefix}_readcount.info
    >>>
    output {
      File  final_count_table = "~{prefix}.rnaseq_gea.txt"
      File? final_count_ig = "~{prefix}.rnaseq_gea.intergenic.txt"
      File? final_count_log = "~{prefix}.readcount.stats.log"
      File  final_readcount_info = "~{prefix}_readcount.info"
    }

    runtime {
      docker: container
      cpu: cpu
      memory: memory
      runtime_minutes: time
    }
}