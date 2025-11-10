#!/bin/bash
#PBS -l ncpus=20
#PBS -l walltime=10:30:00
#PBS -l mem=200gb
#PBS -q normalbw
#PBS -P v46
#PBS -lstorage=scratch/v46+gdata/v46+gdata/w40+gdata/rt52+gdata/ux62+gdata/hh5

# var="adv_q"
# mode="wet"

module load parallel
module use /g/data/hh5/public/modules
module load conda/analysis3 

SCRIPT='/g/data/v46/fm6730/script_access_s2/vorticity/composite/lifecycle_everymember_vorticity_budget.py'
INPUTS='/g/data/v46/fm6730/script_access_s2/vorticity/composite/input_composite_vorticity.txt'

PARALLEL_JOBS=$((PBS_NCPUS / 2))
echo "Using ${PARALLEL_JOBS} parallel jobs (half of ${PBS_NCPUS} CPUs)"

# Debug: print first few lines of input file
echo "Input file contents:"
head -n 4 ${INPUTS}

# Run parallel with explicit argument passing
parallel --verbose --colsep ' ' -j ${PARALLEL_JOBS} python ${SCRIPT} {1} {2} {3} {4} :::: ${INPUTS}

# for mode in wet dry; do
#     for wave in er td mrg kelvin mjo; do
#         for var in adv_q conv_q; do 
#             for ens in e01 e02 e03; do
#             # for ens in ensmean; do
#                 echo "Processing ensemble: $ens for wave: $wave" 
#                 # Call the Python script for each ensemble
#                 # python /g/data/v46/fm6730/script_access_s2/lifecycle/map_lifecycle_everymember.py "$var" "$mode" "$ens"
#                 python /g/data/v46/fm6730/script_access_s2/vimfc/lifecycle_lifecycle_everymember_vimfc.py "$var" "$mode" "$ens" "$wave"
#             done
#         done
#     done
# done

# Note: Ensure that the Python script 'map_lifecycle_everymember.py' is designed to handle
# the variable, mode, and ensemble member as arguments.
# and has access to the necessary data files for each ensemble member.

# The above script processes the variable 'rlut' for different ensembles
# and generates lifecycle maps for each ensemble member.
# Ensure that the Python script is designed to handle the ensemble argument
# and that the necessary data is available for each ensemble member.
# The script assumes that the Python script 'map_lifecycle_everymember.py'
# is capable of processing the variable and mode specified, as well as the ensemble member.
# Make sure to check the output and logs for any errors or issues during processing.
# The script is designed to run on a high-performance computing cluster     