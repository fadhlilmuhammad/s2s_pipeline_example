# %%
import xarray as xr 
import numpy as np 
import pandas as pd
# import xskillscore as xs    
import sys
import os 
import gc


# %%
# wave = "mjo"
# waves = ['LF']
# waves = ['UF']
#%%
folder_phase = '/g/data/v46/fm6730/dataout/local_wave_phase/'

varss = ["vr"]  # e.g., 'rlut', 'u850', 'adv_q850', 'conv_q850'

season =sys.argv[1]  # e.g., 'NDJFMA', 'MJJASO'
mode = sys.argv[2]  # e.g., 'wet', 'dry'
e = sys.argv[3] 
wave = sys.argv[4]

time_active_str = dict()

if (wave == 'mjo') or (wave == 'kelvin'):
    ctrl_lon = 95
else:
    ctrl_lon = 133

folderout = f'/g/data/v46/fm6730/dataout/lifecycle/vorticity/{wave}/{mode}/'
os.makedirs(folderout, exist_ok=True)

file = f'local_{mode}_{wave}_phase_{season}_allclim.init_fors2s_{ctrl_lon}.nc'

phases = xr.open_dataset(os.path.join(folder_phase, file))

time_active = pd.to_datetime(phases.time.values)
time_active_str = set(time_active.strftime('%Y%m%d'))

mod_dict = {}
dia_dict = {}

# %%
init_sets = list(time_active_str)
init_sets = [init for init in time_active_str if init != '19810101']

print(init_sets)

mod_comp = {}
dia_comp = {}
# Store datasets instead of individual variables
mod_dict = {}
dia_dict = {}

for init in init_sets:
    print(f'Processing {wave} wave for {init} initialization')

    folder_mod = f'/scratch/v46/fm6730/dataout/access_s2/integrated/vorticity/{wave}/'
    folder_dia = f'/scratch/v46/fm6730/dataout/obs/integrated/vorticity/merged/'

    file_mod = f'{wave}_tlag_da_vorticity_{init}_{e}_remap_padded.nc'
    file_dia = f'vorticity.{wave}.30_truth_for_S2S.nc'

    print(f'Opening {file_mod}')
    ds_mod = xr.open_dataset(os.path.join(folder_mod, file_mod))
    ds_dia = xr.open_dataset(os.path.join(folder_dia, file_dia))

    # Select only the variables we need
    ds_mod = ds_mod[varss]
    ds_dia = ds_dia[varss]

    # Reverse latitude if ascending
    if ds_mod['lat'][0] < ds_mod['lat'][-1]:
        ds_mod = ds_mod.reindex(lat=ds_mod.lat[::-1])
    if ds_dia['lat'][0] < ds_dia['lat'][-1]:
        ds_dia = ds_dia.reindex(lat=ds_dia.lat[::-1])

    # Select region and time
    ds_mod_sel = abs(ds_mod.sel(lat=slice(15, -15), time=slice(init, None)))
    ds_dia_sel = abs(ds_dia.sel(lat=slice(15, -15), time=slice(init, None)))

    print("Flipping sign for Southern Hemisphere...")
    for var in varss:
        # Create a sign array: +1 for NH, -1 for SH
        sign = xr.where(ds_mod_sel['lat'] >= 0, 1, -1)
        ds_mod_sel[var] = ds_mod_sel[var].copy() * sign
        ds_dia_sel[var] = ds_dia_sel[var].copy() * sign
        
    # Calculate weights
    weights = np.cos(np.deg2rad(ds_mod_sel['lat']))

    print(f'Length of ds_mod_sel: {len(ds_mod_sel["time"])}')

    # Apply weighted mean to entire dataset
    ds_mod_weighted = ds_mod_sel.weighted(weights).mean(dim='lat')
    ds_dia_weighted = ds_dia_sel.weighted(weights).mean(dim='lat')

    # Select first 50 time steps
    ds_mod_weighted = ds_mod_weighted.isel(time=slice(0, 60))
    ds_dia_weighted = ds_dia_weighted.isel(time=slice(0, 60))

    print(f'Length of ds_mod_weighted: {len(ds_mod_weighted["time"])}')

    # Replace time with lead days
    ds_mod_weighted['time'] = np.arange(0, len(ds_mod_weighted['time']))
    ds_dia_weighted['time'] = np.arange(0, len(ds_dia_weighted['time']))

    # Store datasets
    mod_dict[init] = ds_mod_weighted
    dia_dict[init] = ds_dia_weighted

    print(f'Finished processing {wave} wave for {init} initialization')

    # Clear variables to free memory
    del ds_mod, ds_dia, ds_mod_sel, ds_dia_sel
    del ds_mod_weighted, ds_dia_weighted
    gc.collect()

print(f"Concatenating {len(mod_dict)} initializations...")

# Concatenate all initializations at once (for all variables)
mod_concat = xr.concat(mod_dict.values(), dim='init')
dia_concat = xr.concat(dia_dict.values(), dim='init')

print(f'Concatenated mod_concat: {mod_concat}')

# Take mean across initializations
ds_mod_mean = mod_concat.mean(dim='init')
ds_dia_mean = dia_concat.mean(dim='init')

# Combine into output dataset
ds_out = xr.Dataset()
for var in varss:
    ds_out[f'{var}_mod'] = ds_mod_mean[var]
    ds_out[f'{var}_dia'] = ds_dia_mean[var]

print(f'Saving to {folderout}')
print(f'Dataset contains {len(ds_out.data_vars)} variables: {list(ds_out.data_vars)}')

# Define compression settings for all variables
compression_settings = {var: {"zlib": True, "complevel": 6} for var in ds_out.data_vars}

outfile = os.path.join(folderout, f'hovmuller_lon{ctrl_lon}_{mode}_{wave}_{season}_vorticity_{e}_leaddays.nc')
ds_out.to_netcdf(outfile, encoding=compression_settings)

print(f'Vorticity {wave} {mode} saved to {outfile}')
