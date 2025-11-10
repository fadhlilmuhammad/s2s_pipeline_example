#!/bin/bash
# Run an embarrassingly parallel job, where each command is totally independent
# Uses GNU Parallel as a task scheduler, then executes each task on the available CPUs with pbsdsh

#PBS -q normalbw
#PBS -l ncpus=20
#PBS -l walltime=5:00:00
#PBS -l mem=200gb
#PBS -l wd
#PBS -l storage=scratch/w40+gdata/v46+gdata/w40+gdata/rt52+gdata/ux62+gdata/hh5+gdata/su28

# mkdir -p /scratch/v46/fm6730/tmp
# export TMPDIR=/scratch/v46/fm6730/tmp


module load parallel
module load ncl

PARALLEL_JOBS=10  # Use half the available cores

INPUTS=/g/data/v46/fm6730/script_access_s2/vorticity/get_data/years_1979_2020.txt  # Each line in this file is a script to run

# INPUTS=/g/data/v46/fm6730/script_access_s2/vimfc/patch_input.txt  # Each line in this file is a script to run

SCRIPT=/g/data/v46/fm6730/script_access_s2/vorticity/calc_vorticity/bash_vorticity_obs.sh
echo $INPUTS
cat ${INPUTS}

echo "Testing parallel execution command (dry run):"
parallel --dry-run -j ${PARALLEL_JOBS} --colsep ' ' bash ${SCRIPT} {1} :::: ${INPUTS}

echo "Starting parallel execution:"
parallel -j ${PARALLEL_JOBS} --colsep ' ' bash ${SCRIPT} {1} :::: ${INPUTS}

# echo "Testing parallel execution command (dry run):"
# parallel --dry-run -j ${PBS_NCPUS} --colsep ' ' bash ${SCRIPT} {1} :::: ${INPUTS}

# echo "Starting parallel execution:"
# parallel -j ${PBS_NCPUS} --colsep ' ' bash ${SCRIPT} {1} :::: ${INPUTS}