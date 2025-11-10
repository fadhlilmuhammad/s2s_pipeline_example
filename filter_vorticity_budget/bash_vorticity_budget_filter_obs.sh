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
module load ncl

# vars=("vr_planetary_adv" "vr_total_source" "residual" "vr_stretch" "fD" "vrD" "adv_vr_zonal" "adv_vr_meridional" "adv_vr_vertical" "adv_vr" "vr_tilt")
for wave in "er" "mjo" "kelvin"; do
        # for var in "${vars[@]}"; do
        export wave="${wave}"
        # export var="${var}"
            ncl /g/data/v46/fm6730/script_access_s2/vorticity/filter_vorticity_budget/ncl_vorticity_budget_wave_filter_diag.ncl
        # echo "Completed NCL script for wave: ${wave} and var: ${var}"
        # done 
done

# "er" "mjo" "kelvin" "mrg" "td" "LF"