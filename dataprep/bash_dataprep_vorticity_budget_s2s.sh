#!/bin/bash

module use /g/data/hh5/public/modules
module load conda/analysis3 
module load parallel
module load ncl 


# echo "Running NCL script with init: $1 and ens: $2"
# export init=$1 
# export ens=$2

echo "init: ${1}"
echo "ens: ${2}"

ncl init=\"${1}\" ens=\"${2}\" /g/data/v46/fm6730/script_access_s2/vorticity/dataprep/dataprep_vorticity_budget_s2s.ncl