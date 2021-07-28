#!/usr/bin/env bash
#$ -V
#$ -cwd
#$ -j y
#$ -l mem_free=200G

# x #$ -q 1tb.q
# x #$ -l h=csclprd3-c050.local

# usage example:
#
# ./run_shading.sh --output_path /full/path/shading_dict.pkl --cycles 14 --channels 4 -j 12 --input_dirs `ls -d /output/group/*/1a_shading_correction_input`
# 


siffile=/home/ingn/sifs/codex.sif

hostname

TZ=America/Los_Angeles date

echo $@


export TMPDIR=/scratch/ingn/tmp
module load singularity/3.6.0

echo "Starting singularity"
singularity exec -B /scratch:/scratch -B /common:/common --env TMPDIR=/scratch/ingn/tmp $siffile bash ./set_up_singularity_shading.sh $@

TZ=America/Los_Angeles date


