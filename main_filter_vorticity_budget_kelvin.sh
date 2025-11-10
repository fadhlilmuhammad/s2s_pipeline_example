            #!/bin/bash

module use /g/data/hh5/public/modules
module load conda/analysis3 
module load parallel
module load ncl 


# echo "Running NCL script with init:  and ens: "
# export init= 
# export ens=

wave=kelvin

echo "init: $1"
echo "ens: $2"

ncl init=\"$1\" ens=\"$2\" wave=\"${wave}\" /g/data/v46/fm6730/script_access_s2/vorticity/filter_vorticity_budget/ncl_vorticity_budget_wave_filter_s2s.ncl

