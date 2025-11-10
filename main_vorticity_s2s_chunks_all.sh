#!/bin/bash
# filepath: /g/data/v46/fm6730/script_access_s2/vorticity/main_vorticity_s2s_chunks_all_ensembles.sh
# Usage: ./main_vorticity_s2s_chunks_all_ensembles.sh [NROWS]
# Submits sequential qsub jobs for each ensemble, each processing NROWS lines from the INPUTS file.

NROWS="${1:-150}"
ensembles=("e01" "e02" "e03")

echo "=== SUBMITTING CHUNKED VORTICITY JOBS FOR ALL ENSEMBLES ==="
echo "Chunk size: $NROWS lines per job"

all_chunk_jobs=()

for E in "${ensembles[@]}"; do
    echo ""
    echo "Processing ensemble: $E"
    
    INPUTS=/g/data/v46/fm6730/script_access_s2/vorticity/calc_vorticity_budget/dates_with_${E}.txt
    JOBSCRIPT=/g/data/v46/fm6730/script_access_s2/vorticity/main_vorticity_s2s.sh

    total_lines=$(wc -l < "$INPUTS")
    echo "  Total lines for $E: $total_lines"

    ensemble_jobs=()
    start=1
    chunk_num=1
    
    while [ $start -le $total_lines ]; do
        echo "  Submitting $E chunk $chunk_num: lines ${start}..$((start+NROWS-1))"
        jobid=$(qsub -N vort_${E}_chunk${chunk_num} -v E=${E},START=${start},NROWS=${NROWS} "$JOBSCRIPT")
        echo "    Job ID: $jobid"
        
        ensemble_jobs+=($jobid)
        all_chunk_jobs+=($jobid)
        
        start=$(( start + NROWS ))
        chunk_num=$(( chunk_num + 1 ))
    done
    
    echo "  Submitted ${#ensemble_jobs[@]} chunk jobs for ensemble $E"
done

echo ""
echo "=== SUBMITTING MAIN PROCESSING CHAIN ==="

# Build dependency string for ALL chunk jobs
depend_string=$(IFS=:; echo "${all_chunk_jobs[*]}")
echo "Main chain will wait for ${#all_chunk_jobs[@]} chunk jobs to complete"

# Submit the main processing chain that depends on ALL chunk jobs
main_chain_job=$(qsub -N main_vorticity_chain -W depend=afterok:$depend_string /g/data/v46/fm6730/script_access_s2/vorticity/_main_run_all_jobs.sh)
echo "Submitted main processing chain: $main_chain_job"

echo ""
echo "=== SUBMISSION SUMMARY ==="
echo "Total chunk jobs submitted: ${#all_chunk_jobs[@]}"
echo "Chunk jobs by ensemble:"
chunk_idx=0
for E in "${ensembles[@]}"; do
    INPUTS=/g/data/v46/fm6730/script_access_s2/vorticity/calc_vorticity_budget/dates_with_${E}.txt
    total_lines=$(wc -l < "$INPUTS")
    num_chunks=$(( (total_lines + NROWS - 1) / NROWS ))  # Ceiling division
    
    echo "  $E: $num_chunks jobs"
    chunk_idx=$(( chunk_idx + num_chunks ))
done

echo "Main chain job: $main_chain_job"

echo ""
echo "Dependency flow:"
echo "  [All chunk jobs for e01, e02, e03] -> main_chain($main_chain_job)"
echo ""
echo "Monitor with: watch -n 30 'qstat -u \$USER'"