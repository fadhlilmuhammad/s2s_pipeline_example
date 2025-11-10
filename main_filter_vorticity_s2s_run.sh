
for wave in "er" "mjo" "kelvin"; do
for ens in "e01" "e02" "e03"; do
    qsub /g/data/v46/fm6730/script_access_s2/vorticity/filter_vorticity/filter_s2s_vorticity_${wave}_${ens}.sh
done 
done
