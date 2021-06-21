#!/usr/bin/env bash
#$ -V
#$ -cwd
#$ -j y
#$ -l mem_free=200G

# x #$ -q 1tb.q

# x #$ -l h=csclprd3-c001.local|csclprd3-c007.local|csclprd3-c008.local|csclprd3-c014.local|csclprd3-c016.local|csclprd3-c034.local|csclprd3-c036.local|csclprd3-c037.local|csclprd3-c038.local|csclprd3-c039.local|csclprd3-c040.local|csclprd3-c041.local|csclprd3-c042.local|csclprd3-c043.local|csclprd3-c044.local|csclprd3-c045.local|csclprd3-c046.local|csclprd3-c047.local|csclprd3-c048.local|csclprd3-c049.local|csclprd3-c050.local|csclprd3-c051.local|csclprd3-c052.local|csclprd3-c053.local

# x #$ -l h=csclprd3-c050.local

siffile=/home/ingn/sifs/codex.sif

hostname

TZ=America/Los_Angeles date

echo $@

# # Make sure the host we're on has AVX and AVX2 available
# # TensorFlow binaries are compiled with AVX on and segfault out if the CPU doesn't have those instructions
# if [[ -z `lscpu | grep avx` ]]
# then 
#   echo "avx instructions not found"
#   echo $@ >> /home/ingn/devel/micron2/scripts/avx_related_fails.txt
# 
#   exit 1
# fi

export TMPDIR=/scratch/ingn/tmp
module load singularity/3.6.0

echo "Starting singularity"
singularity exec -B /scratch:/scratch -B /common:/common --env TMPDIR=/scratch/ingn/tmp $siffile bash ./set_up_singularity_codex.sh $@

TZ=America/Los_Angeles date


