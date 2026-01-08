# Vorticity Budget Analysis for ACCESS-S2

This repository contains scripts for computing and analyzing vorticity and vorticity budget diagnostics from ACCESS-S2 subseasonal-to-seasonal (S2S) hindcast data.

## Directory Structure

```
vorticity_copy/
├── calc_vorticity_budget/   # NCL scripts to calculate vorticity budget terms
├── composite/               # Python scripts for Hovmöller and lifecycle composites
├── dataprep/                # Data preparation and preprocessing scripts
├── ensmean/                 # Ensemble mean calculation scripts
├── filter_vorticity/        # Wave filtering for vorticity only
├── filter_vorticity_budget/ # Wave filtering for vorticity budget terms
├── get_data/                # Data retrieval scripts
├── logs/                    # Log files from job submissions
├── timelag/                 # Time-lagged ensemble scripts
├── utils/                   # Utility NCL functions (s2s_utils.ncl, kf_filter.ncl, etc.)
└── main_*.sh                # Main wrapper scripts to run each step
```

## Workflow Overview

The workflow can be shortened to two steps:

### 1. Data Retrieval

This will get data from the GADI data storage. This script includes the remapping schedule. If you want to use an external dataset, skip this process and proceed to the main pipeline. Make sure the variable name and structure is applicable to the subprocess.
```bash
sh _main_get_data.sh
```
Get the required ACCESS-S2 and ERA5 data for processing.

### 2. Main Pipeline
```bash
sh _main_run_all_jobs.sh 
```
| This is a Master script to run entire workflow |


## Sub-process Overview (in case you want to modify something)

### 1. Data Retrieval
```bash
sh _main_get_data.sh
```
Get the required ACCESS-S2 and ERA5 data for processing.

### 2. Data Preparation
```bash
sh main_prep_parallel_s2s.sh
```
Prepares and preprocesses raw data for vorticity calculations.

### 3. Vorticity Budget Calculation
```bash
sh main_vorticity_budget_s2s.sh      # For S2S model data
sh main_vorticity_budget_obs.sh      # For observations/reanalysis
```
Calculates vorticity budget terms including:
- Vorticity tendency
- Horizontal advection
- Vertical advection
- Stretching term
- Tilting term

### 4. Ensemble Mean
```bash
sh main_ensmean_vorticity_budget.sh
```
Computes ensemble means across multiple ensemble members.

### 5. Wave Filtering
Filter vorticity budget for specific equatorial waves:
```bash
sh main_filter_vorticity_budget_mjo.sh     # MJO
sh main_filter_vorticity_budget_er.sh      # Equatorial Rossby waves
sh main_filter_vorticity_budget_kelvin.sh  # Kelvin waves
sh main_filter_vorticity_budget_LF.sh      # Low-frequency
sh main_filter_vorticity_budget_td.sh      # Tropical depression-type
```

### 6. Time-Lagged Ensemble
```bash
sh main_timelag_vorticity_budget_s2s.sh
```
Creates time-lagged ensemble members for improved statistics.

### 7. Composite Analysis
```bash
sh main_hovmuller_everymember_vorticity_budget.sh  # Hovmöller diagrams
sh main_lifecycle_everymember_vorticity_budget.sh  # Lifecycle composites
```

## Key Scripts

| Script | Description |
|--------|-------------|
| `_main_run_all_jobs.sh` | Master script to run entire workflow |
| `_monitor_jobs.sh` | Monitor PBS job status |
| `main_vorticity_budget_chunks_s2s.sh` | Process data in chunks for memory efficiency |

## Dependencies

### NCL Libraries (in `utils/`)
- `s2s_utils.ncl` - S2S-specific utility functions
- `kf_filter.ncl` - Wavenumber-frequency filtering
- `wkSpaceTime_mod.ncl` - Wheeler-Kiladis space-time spectral analysis
- `utils.ncl` - General utility functions

### Python Packages
- numpy
- xarray
- pandas

### Environment
- NCL (NCAR Command Language)
- Python 3.x
- CDO (Climate Data Operators)
- PBS job scheduler (Gadi HPC)

## Data Paths

- **Input data**: ACCESS-S2 hindcast data, ERA5 wind
- **Output data**: Filtered & Padded ACCESS-S2 hindcast, Filtered Reference Data (OBS), 

Feel free to change the input data as you need.

## PBS Job Submission

Some scripts are designed for the Gadi HPC system. Example submission:
```bash
qsub script.sh
```

The main workflow should be submitted as follows:
```bash
sh main_script.sh
```

## Author

Created for ACCESS-S2 vorticity budget analysis project.

## Notes

- This is a copy of the original `vorticity/` folder with modified paths
- Library paths point to `/g/data/v46/fm6730/script_access_s2/vorticity_copy/`
- Excludes NetCDF output files (`.nc`) and PBS log files (`.e*`, `.o*`)
