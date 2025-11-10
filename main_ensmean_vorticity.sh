for wave in "er" "mjo" "kelvin"; do
    qsub -v wave="${wave}" /g/data/v46/fm6730/script_access_s2/vorticity/ensmean/ensmean_create_vorticity_budget.sh
done