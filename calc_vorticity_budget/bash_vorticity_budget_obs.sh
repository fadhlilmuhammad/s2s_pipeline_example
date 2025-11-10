#!/bin/bash

module use /g/data/hh5/public/modules
module load conda/analysis3 
module load parallel
module load ncl 


echo "init: ${1}"
echo "ens: ${2}"

ncl year=\"${1}\" /g/data/v46/fm6730/script_access_s2/vorticity/calc_vorticity_budget/ncl_vorticity_budget_obs.ncl

# Set unique temporary directory for each process
# export TMPDIR="/scratch/v46/fm6730/tmp/ncl_$$_$(date +%s)"
# mkdir -p "$TMPDIR"

# # Run NCL with error handling
# echo "Running NCL for init=${1}, ens=${2}"
# ncl -Q init=\"${1}\" ens=\"${2}\" /g/data/v46/fm6730/script_access_s2/vorticity/calc_vorticity_budget/ncl_vorticity_budget_s2s.ncl 2>&1
# exit_code=$?

# # Cleanup
# rm -rf "$TMPDIR" 2>/dev/null

# if [ $exit_code -ne 0 ]; then
#     echo "NCL script failed for init=${1}, ens=${2} with exit code $exit_code"
# else
#     echo "NCL script completed successfully for init=${1}, ens=${2}"
# fi
