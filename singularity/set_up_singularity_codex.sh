#!/usr/bin/env bash

# write this as if we're inside a singularity image

source /miniconda3/bin/activate codex
which python
python --version

pip3 install pytest

pybasic_path=/home/ingn/software/pybasic 
codex_path=/home/ingn/devel/codex

# copy pybasic to temporary storage ? 
pbprefix=/common/ingn/tmp/pybasic_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
mkdir $pbprefix
echo "copying pybasic to ${pbprefix}"
cp -r $pybasic_path $pbprefix
cd $pbprefix/pybasic
pwd
ls
pip3 install -e .

cd ${codex_path}/src
pwd

TZ=America/Los_Angeles date

#python3 -c "import pybasic; print('success!')"
PYTHONPATH=${codex_path} python3 ./main.py $@

TZ=America/Los_Angeles date

echo "removing pybasic from $pbprefix"
rm -r $pbprefix
echo "done"

