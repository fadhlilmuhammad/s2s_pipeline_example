ensembles=("e01" "e02" "e03")

for e in "${ensembles[@]}"; do
    echo "Submitting prep job for ensemble $e"
    qsub -v ENSEMBLE=$e /g/data/v46/fm6730/script_access_s2/vorticity/main_prep_parallel_s2s.sh
    echo "Submitted prep_$e"
done