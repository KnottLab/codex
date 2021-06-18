#!/usr/bin/env bash

# write this as if we're inside a singularity image

source /miniconda3/bin/activate codex
which python
python --version
which pip3

pip3 install --no-cache-dir pytest

pybasic_path=/common/shaha4/shaha4/codex/pybasic 
codex_path=/home/ingn/devel/codex

echo "temp dir:"
echo $TMPDIR

export RAY_OBJECT_STORE_ALLOW_SLOW_STORAGE=1

# copy pybasic to temporary storage ? 
pbprefix=/common/ingn/tmp/pybasic_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
mkdir $pbprefix
echo "copying pybasic to ${pbprefix}"
cp -r $pybasic_path $pbprefix
cd $pbprefix/pybasic
pwd

pip3 install -e .

cd ${codex_path}/src
pwd

TZ=America/Los_Angeles date

#python3 -c "import pybasic; print('success!')"
PYTHONPATH=${codex_path} python3 ../src/main.py $@

TZ=America/Los_Angeles date

echo "removing pybasic from $pbprefix"
rm -rf $pbprefix
echo "done"

