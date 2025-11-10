#!/bin/bash

#PBS -l ncpus=12
#PBS -l walltime=20:00:00
#PBS -l mem=120gb
#PBS -q normalbw
#PBS -lstorage=gdata/v46+gdata/w40+gdata/rt52

module load cdo
module load parallel

start=$(date +%s)
echo "Getting data..."

#variables
var=w
#Grid folder
griddes="/g/data/v46/fm6730/data/"

mkdir -p /g/data/v46/fm6730/data/obs/${var}850_raw/

# multi-level example
folder=/g/data/su28/ERA5/daily/${var}/{1}/
cdo -L -b F32 -f nc4 -remapscon2,"${griddes}grid_olr_noaa.txt" -sellevel,850 /g/data/su28/ERA5/daily/${var}/${var}_era5_oper_pl_merge_1deg_daily_${1}.nc /g/data/v46/fm6730/data/obs/${var}850_raw/${var}.${1}.nc

#single-level example
cdo -L -b F32 -f nc4 -remapscon2,"${griddes}grid_olr_noaa.txt" /g/data/su28/ERA5/daily/${var}/${var}_era5_oper_pl_merge_1deg_daily_${1}.nc /g/data/v46/fm6730/data/obs/${var}850_raw/${var}.${1}.nc


