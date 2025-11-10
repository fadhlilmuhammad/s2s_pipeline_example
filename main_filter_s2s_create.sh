
for e in "e01" "e02" "e03"; do
for wave in "er" "mjo" "kelvin" "td" "LF" ; do

cat > /g/data/v46/fm6730/script_access_s2/vorticity/main_filter_vorticity_budget_${wave}.sh << EOF
            #!/bin/bash

module use /g/data/hh5/public/modules
module load conda/analysis3 
module load parallel
module load ncl 


# echo "Running NCL script with init: $1 and ens: $2"
# export init=$1 
# export ens=$2

wave=$wave

echo "init: \$1"
echo "ens: \$2"

ncl init=\"\$1\" ens=\"\$2\" wave=\"\${wave}\" /g/data/v46/fm6730/script_access_s2/vorticity/filter_vorticity_budget/ncl_vorticity_budget_wave_filter_s2s.ncl

EOF
chmod +x /g/data/v46/fm6730/script_access_s2/vorticity/main_filter_vorticity_budget_${wave}.sh
done
done
