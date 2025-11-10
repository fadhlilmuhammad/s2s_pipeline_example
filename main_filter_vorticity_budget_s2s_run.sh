#!/bin/bash
#PBS -l ncpus=2
#PBS -l walltime=00:30:00
#PBS -l mem=10gb
#PBS -q normalbw
#PBS -P v46
#PBS -lstorage=scratch/v46+gdata/v46+gdata/w40+gdata/rt52+gdata/ux62+gdata/hh5

# var="adv_q"
# mode="wet"


for wave in "er" "mjo" "kelvin"; do
for ens in "e01" "e02" "e03"; do
    qsub /g/data/v46/fm6730/script_access_s2/vorticity/filter_vorticity_budget/filter_s2s_vorticity_budget_${wave}_${ens}.sh
done 
done
