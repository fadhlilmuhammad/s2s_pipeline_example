#!/bin/bash
# Run an embarrassingly parallel job, where each command is totally independent
# Uses GNU Parallel as a task scheduler, then executes each task on the available CPUs with pbsdsh

#PBS -q normalbw
#PBS -l ncpus=20
#PBS -l walltime=18:00:00
#PBS -l mem=200gb
#PBS -l wd
#PBS -l storage=scratch/w40+gdata/v46+gdata/w40+gdata/rt52+gdata/ux62+gdata/hh5+gdata/su28

module load parallel
module load ncl

# mkdir -p /scratch/v46/fm6730/tmp
# export TMPDIR=/scratch/v46/fm6730/tmp

e=e03
INPUTS=/g/data/v46/fm6730/script_access_s2/vorticity/calc_vorticity_budget/dates_with_$e.txt  # Each line in this file is a script to run

# INPUTS=/g/data/v46/fm6730/script_access_s2/vimfc/patch_input.txt  # Each line in this file is a script to run
PARALLEL_JOBS=4  # Use 4 cores
SCRIPT=/g/data/v46/fm6730/script_access_s2/vorticity/calc_vorticity_budget/bash_vorticity_budget_s2s.sh
echo $INPUTS
cat ${INPUTS}

# echo "Testing parallel execution command (dry run):"
# parallel --dry-run -j ${PARALLEL_JOBS} --colsep ' ' bash ${SCRIPT} {1} {2} :::: ${INPUTS}

# echo "Starting parallel execution with retry logic:"
# parallel -j ${PARALLEL_JOBS} --colsep ' ' bash ${SCRIPT} {1} {2} :::: ${INPUTS}

echo "Testing parallel execution command (dry run):"
parallel --dry-run -j ${PARALLEL_JOBS} --colsep ' ' bash ${SCRIPT} {1} {2} :::: ${INPUTS}

echo "Starting parallel execution:"
parallel -j ${PARALLEL_JOBS} --colsep ' ' bash ${SCRIPT} {1} {2} :::: ${INPUTS}