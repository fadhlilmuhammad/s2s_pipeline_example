#!/bin/bash
# Run an embarrassingly parallel job, where each command is totally independent
# Uses GNU Parallel as a task scheduler, then executes each task on the available CPUs with pbsdsh

#PBS -q normalbw
#PBS -l ncpus=20
#PBS -l walltime=15:00:00
#PBS -l mem=200gb
#PBS -l wd
#PBS -P v46
#PBS -l storage=scratch/v46+scratch/w40+gdata/v46+gdata/w40+gdata/rt52+gdata/ux62+gdata/hh5+gdata/su28

module load parallel
module load ncl

e="${ENSEMBLE:-e01}"
INPUTS=/g/data/v46/fm6730/script_access_s2/vorticity/dataprep/${e}_dates.txt
SCRIPT=/g/data/v46/fm6730/script_access_s2/vorticity/dataprep/bash_dataprep_vorticity_budget_s2s.sh
echo $INPUTS
cat ${INPUTS}
# Here '{%}' gets replaced with the job slot ({1..$PBS_NCPUS})
# and '{}' gets replaced with a line from ${INPUTS}

# Run parallel with explicit argument passing
# parallel --verbose --colsep ' ' -j ${PBS_NCPUS} \
#     ${SCRIPT} {1} {2} :::: ${INPUTS}

# parallel -j ${PBS_NCPUS} --colsep ' ' "${SCRIPT} {1} {2}" :::: ${INPUTS}

echo "Testing parallel execution command (dry run):"
parallel --dry-run -j ${PBS_NCPUS} --colsep ' ' bash ${SCRIPT} {1} {2} :::: ${INPUTS}

echo "Starting parallel execution:"
parallel -j ${PBS_NCPUS} --colsep ' ' bash ${SCRIPT} {1} {2} :::: ${INPUTS}