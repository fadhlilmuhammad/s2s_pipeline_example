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

ens=e03
ncl e=\"$ens\" /g/data/v46/fm6730/script_access_s2/vorticity/timelag/time_lag_ensemble_vorticity_s2s.ncl