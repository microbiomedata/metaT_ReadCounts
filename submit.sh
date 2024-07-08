#!/bin/bash
#SBATCH --qos=regular
#SBATCH --time=12:00:00
#SBATCH --output=/global/cfs/projectdirs/m3408/aim2/readcount/log/readcount_%j.log
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task 62
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=your@mail.com
#SBATCH --constraint=haswell
#SBATCH --account=m3408
#SBATCH --job-name=rc_%j

java -Dconfig.file=shifter.conf -jar /global/common/software/m3408/cromwell-45.jar run -m metadata_out.json -i input.json readcount.wdl
