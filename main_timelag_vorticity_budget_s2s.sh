 #!/bin/bash

#PBS -l ncpus=12
#PBS -l walltime=02:00:00
#PBS -l mem=100gb
#PBS -q normalbw
#PBS -lstorage=scratch/v46+gdata/v46+gdata/w40+gdata/rt52+gdata/ux62+gdata/hh5

module load ncl 

export ens="e03"
export var="conv_q"

ncl /g/data/v46/fm6730/script_access_s2/time_lag_ensemble_s2s_mfc.ncl 