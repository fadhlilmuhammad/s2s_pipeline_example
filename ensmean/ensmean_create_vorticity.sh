#!/bin/bash
# Run an embarrassingly parallel job, where each command is totally independent
# Uses GNU Parallel as a task scheduler, then executes each task on the available CPUs with pbsdsh

#PBS -q express
#PBS -l ncpus=12
#PBS -l walltime=1:40:00
#PBS -l mem=100gb
#PBS -P v46
#PBS -l wd
#PBS -l storage=scratch/v46+gdata/v46+gdata/w40+gdata/rt52+gdata/ux62+gdata/hh5

module load parallel
module use /g/data/hh5/public/modules
module load conda/analysis3 

if [ -n "$1" ]; then
  wave="$1"
fi

wave="${wave:-$WAVE}"

# sanity checks
if [ -z "$wave" ]; then
  echo "ERROR: wave not set. Provide as positional arg or with -v wave=..."
  echo "Environment preview:"
  printenv | grep -E '^(wave|WAVE)=' || true
  exit 1
fi


echo "wave=$wave"
# Define paths
SCRIPT='/g/data/v46/fm6730/script_access_s2/vorticity/ensmean/ensmean_create_vorticity.py'
INPUTS='/g/data/v46/fm6730/script_access_s2/vorticity/ensmean/ensmean_input_'${wave}'.txt'

# Debug: print first few lines of input file
echo "Input file contents:"
head -n 3 ${INPUTS}

# Run parallel with explicit argument passing
parallel --verbose --colsep ' ' -j ${PBS_NCPUS} python ${SCRIPT} {1} {2} :::: ${INPUTS}