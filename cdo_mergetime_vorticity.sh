#!/bin/bash
# filepath: /g/data/v46/fm6730/script_access_s2/vorticity/cdo_mergetime_vorticity.sh
#PBS -q normalbw
#PBS -l ncpus=4
#PBS -l walltime=2:00:00
#PBS -l mem=100gb
#PBS -l wd
#PBS -l storage=scratch/v46+gdata/v46

module load cdo

INPUT_DIR="/scratch/v46/fm6730/data/obs/vorticity_budget"
OUTPUT_DIR="/scratch/v46/fm6730/data/obs/integrated/vorticity_budget/merged"
OUTPUT_FILE="vorticity_budget.era.daymean.1979-2020.nc"
FILELIST="/tmp/vorticity_files_$$.txt"

echo "Creating file list..."
mkdir -p "$OUTPUT_DIR"

# Create sorted file list
ls ${INPUT_DIR}/*.nc | sort > "$FILELIST"

echo "File list created with $(wc -l < $FILELIST) files"
echo "First 5 files:"
head -5 "$FILELIST"

if [ ! -s "$FILELIST" ]; then
    echo "ERROR: No files found or empty file list"
    exit 1
fi

echo "Merging files into ${OUTPUT_DIR}/${OUTPUT_FILE}..."
rm -f "${OUTPUT_DIR}/${OUTPUT_FILE}"

echo "Starting CDO mergetime with file list..."
time cdo mergetime $(cat "$FILELIST") ${OUTPUT_DIR}/${OUTPUT_FILE}

# Cleanup
rm -f "$FILELIST"


if [ -f "${OUTPUT_DIR}/${OUTPUT_FILE}" ]; then
    echo "SUCCESS: $(du -h ${OUTPUT_DIR}/${OUTPUT_FILE})"
else
    echo "ERROR: Merge failed"
    exit 1
fi