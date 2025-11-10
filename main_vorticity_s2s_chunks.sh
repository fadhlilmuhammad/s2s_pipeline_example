#!/bin/bash
# submit_chunks_vorticity.sh
# Usage: ./submit_chunks_vorticity.sh [NROWS]
# Submits sequential qsub jobs each processing NROWS lines from the INPUTS file.

NROWS="${1:-150}"
E="e03"
INPUTS=/g/data/v46/fm6730/script_access_s2/vorticity/calc_vorticity_budget/dates_with_${E}.txt
JOBSCRIPT=/g/data/v46/fm6730/script_access_s2/vorticity/main_vorticity_s2s.sh

total_lines=$(wc -l < "$INPUTS")
echo "Total lines: $total_lines  chunk size: $NROWS"

start=1
while [ $start -le $total_lines ]; do
  echo "Submitting job for lines ${start}..$((start+NROWS-1))"
  qsub -v E=${E},START=${start},NROWS=${NROWS} "$JOBSCRIPT"
  start=$(( start + NROWS ))
done