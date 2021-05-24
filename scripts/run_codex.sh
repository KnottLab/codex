#!/usr/bin/env bash
#$ -j y
#$ -cwd
#$ -V
#$ -l mem_free=64G

source activate codex

echo $@

export PYTHONPATH=/common/
python codex.py $@

