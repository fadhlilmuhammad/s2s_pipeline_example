#!/bin/bash
# filepath: /g/data/v46/fm6730/script_access_s2/vorticity/_main_run_all_jobs.sh

echo "=== STARTING COMPLETE VORTICITY PROCESSING WORKFLOW ==="

# Configuration
NROWS="${NROWS:-150}"  # Chunk size, can be overridden with -v NROWS=X
ensembles=("e01" "e02" "e03")

echo "Chunk size: $NROWS lines per job"

# Step 1: Submit chunked vorticity budget calculation for all ensembles
echo ""
echo "=== STEP 1: SUBMITTING CHUNKED VORTICITY BUDGET JOBS ==="

all_budget_jobs=()

for E in "${ensembles[@]}"; do
    echo ""
    echo "Processing ensemble: $E"
    
    INPUTS=/g/data/v46/fm6730/script_access_s2/vorticity/calc_vorticity_budget/dates_with_${E}.txt
    JOBSCRIPT=/g/data/v46/fm6730/script_access_s2/vorticity/main_vorticity_budget_chunks_s2s.sh

    total_lines=$(wc -l < "$INPUTS")
    echo "  Total lines for $E: $total_lines"

    start=1
    chunk_num=1
    
    while [ $start -le $total_lines ]; do
        echo "  Submitting $E chunk $chunk_num: lines ${start}..$((start+NROWS-1))"
        jobid=$(qsub -N budget_${E}_chunk${chunk_num} -v E=${E},START=${start},NROWS=${NROWS} "$JOBSCRIPT")
        echo "    Job ID: $jobid"
        
        all_budget_jobs+=($jobid)
        
        start=$(( start + NROWS ))
        chunk_num=$(( chunk_num + 1 ))
    done
done

echo ""
echo "Submitted ${#all_budget_jobs[@]} budget chunk jobs total"

# Build dependency string for all budget chunk jobs
budget_depend_string=$(IFS=:; echo "${all_budget_jobs[*]}")

# Step 2: Observational vorticity budget (can run in parallel with chunks)
echo ""
echo "=== STEP 2: OBSERVATIONAL VORTICITY BUDGET ==="
job1b=$(qsub -N vorticity_obs /g/data/v46/fm6730/script_access_s2/vorticity/main_vorticity_budget_obs.sh)
echo "Submitted vorticity calculation obs: $job1b"

# Step 2.5: CDO mergetime (depends on all budget chunks)
echo ""
echo "=== STEP 2.5: CDO MERGETIME ==="
job2a=$(qsub -N cdo_mergetime -W depend=afterok:$budget_depend_string /g/data/v46/fm6730/script_access_s2/vorticity/cdo_mergetime_vorticity.sh)
echo "Submitted CDO mergetime: $job2a"

# Step 3: Time lag processing (depends on CDO mergetime)
echo ""
echo "=== STEP 3: TIME LAG PROCESSING ==="
job2=$(qsub -N timelag -W depend=afterok:$job2a /g/data/v46/fm6730/script_access_s2/vorticity/timelag/bash_run_timelag.sh)
echo "Submitted time lag processing: $job2"

# Step 4: Data Preparation - submit separate jobs for each ensemble (depends on job2)
echo ""
echo "=== STEP 4: DATA PREPARATION ==="
prep_jobs=()

for e in "${ensembles[@]}"; do
    echo "Submitting prep job for ensemble $e"
    jobid=$(qsub -N prep_$e -W depend=afterok:$job2 -v ENSEMBLE=$e /g/data/v46/fm6730/script_access_s2/vorticity/main_prep_parallel_s2s.sh)
    echo "Submitted prep_$e: $jobid"
    prep_jobs+=($jobid)
done

# Build dependency string for all prep jobs
prep_depend_string=$(IFS=:; echo "${prep_jobs[*]}")

# Step 5: Wave filtering
echo ""
echo "=== STEP 5: WAVE FILTERING ==="
job4a=$(qsub -N filter_model -W depend=afterok:$prep_depend_string /g/data/v46/fm6730/script_access_s2/vorticity/main_filter_vorticity_budget_s2s_run.sh)
echo "Submitted wave filtering model: $job4a"

job4b=$(qsub -N filter_obs -W depend=afterok:$job1b /g/data/v46/fm6730/script_access_s2/vorticity/filter_vorticity_budget/bash_vorticity_budget_filter_obs.sh)
echo "Submitted wave filtering obs: $job4b"

# Step 6: Ensemble mean calculation (depends on job4a)
echo ""
echo "=== STEP 6: ENSEMBLE MEAN CALCULATION ==="
job5=$(qsub -N ensemble_mean -W depend=afterok:$job4a /g/data/v46/fm6730/script_access_s2/vorticity/main_ensmean_vorticity_budget.sh)
echo "Submitted ensemble mean calculation: $job5"

# Step 7: Composite analysis (depends on job5 and job4b)
echo ""
echo "=== STEP 7: COMPOSITE ANALYSIS ==="
job6=$(qsub -N composite -W depend=afterok:$job5:$job4b /g/data/v46/fm6730/script_access_s2/vorticity/main_hovmuller_everymember_vorticity_budget.sh)
echo "Submitted composite analysis: $job6"

echo ""
echo "=== COMPLETE WORKFLOW SUBMITTED ==="
echo "Budget chunk jobs: ${#all_budget_jobs[@]} jobs"
echo "Main processing jobs:"
echo "  Vorticity obs: $job1b" 
echo "  CDO mergetime: $job2a"
echo "  Time lag: $job2"
echo "  Prep jobs: ${prep_jobs[*]}"
echo "  Filter model: $job4a"
echo "  Filter obs: $job4b"
echo "  Ensemble mean: $job5"
echo "  Composite: $job6"

echo ""
echo "Complete dependency flow:"
echo "  [Budget chunks: e01, e02, e03] -> cdo_mergetime($job2a) -> timelag($job2) -> [prep_e01 & prep_e02 & prep_e03] -> filter_model($job4a) -> ensemble_mean($job5)"
echo "  obs($job1b) -> filter_obs($job4b) -----------------------------------------------------------> composite($job6) <-----------"

echo ""
echo "Monitor with: watch -n 30 'qstat -u \$USER'"
echo "Total jobs submitted: $(( ${#all_budget_jobs[@]} + ${#prep_jobs[@]} + 6 ))" 