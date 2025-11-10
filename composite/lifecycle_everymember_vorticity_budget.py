# %%
import xarray as xr 
import numpy as np 
import pandas as pd
import xskillscore as xs    
import sys
import gc

import os 


# %%
# wave = "mjo"
# waves = ['LF']
# waves = ['UF']
#%%
folder_phase = '/g/data/v46/fm6730/dataout/local_wave_phase/'

season =sys.argv[1]  # e.g., 'NDJFMA', 'MJJASO'
mode = sys.argv[2]  # e.g., 'wet', 'dry'
e = sys.argv[3] 
wave = sys.argv[4]

folderout = f'/g/data/v46/fm6730/dataout/lifecycle/vorticity_budget/{wave}/{mode}/'
os.makedirs(folderout, exist_ok=True)

varss = ["vr", "div", "vrD", "fD", "residual", "adv_vr_vertical", "adv_vr_zonal", "adv_vr_meridional",
"vr_total_source", "vr_planetary_adv", "vr_tilt", "vr_stretch", "dvr_dt"]  # e.g., 'rlut', 'u850', 'adv_q850', 'conv_q850'

time_active_str = dict()

if (wave == 'mjo') or (wave == 'kelvin'):
    ctrl_lon = 95
else:
    ctrl_lon = 133

file = f'local_{mode}_{wave}_phase_{season}_allclim.init_fors2s_{ctrl_lon}.nc'

phases = xr.open_dataset(os.path.join(folder_phase, file))

time_active = pd.to_datetime(phases.time.values)
time_active_str = set(time_active.strftime('%Y%m%d'))

mod_dict = {}
obs_dict = {}
dia_dict = {}

# %%
init_sets = list(time_active_str)
init_sets = [init for init in time_active_str if init != '19810101']

print(init_sets)

mod_comp = {}
dia_comp = {}

for init in init_sets:
    
    print(f'Processing {wave} wave for {init} initialization')

    folder_mod = f'/scratch/v46/fm6730/dataout/access_s2/integrated/vorticity_budget/{wave}/'
    # folder_obs = f'/scratch/v46/fm6730/data/obs/integrated/{var}/obs_prepped/'
    folder_dia = f'/scratch/v46/fm6730/dataout/obs/integrated/vorticity_budget/merged/'

    file_mod = f'{wave}_tlag_da_vorticity_budget_{init}_{e}_remap_padded.nc'
    # file_obs = f'obs_{varmod}_{init}_277days_padded.nc'
    file_dia = f'vorticity_budget.{wave}.30_truth_for_S2S.nc'


    # %%

    print(f'Opening {file_mod}')
    ds_mod = xr.open_dataset(os.path.join(folder_mod, file_mod))
    # ds_obs = xr.open_dataset(os.path.join(folder_obs, file_obs))
    ds_dia = xr.open_dataset(os.path.join(folder_dia, file_dia))

    # Reverse latitude if ascending
    if ds_mod['lat'][0] < ds_mod['lat'][-1]:
        ds_mod = ds_mod.reindex(lat=ds_mod.lat[::-1])
    # if da_obs['lat'][0] < da_obs['lat'][-1]:
    #     da_obs = da_obs.reindex(lat=da_obs.lat[::-1])
    if ds_dia['lat'][0] < ds_dia['lat'][-1]:
        ds_dia = ds_dia.reindex(lat=ds_dia.lat[::-1])

    ds_mod_sel = ds_mod.sel(time=slice(init,None))
    # da_obs_sel = da_obs.sel(lat=slice(15, -15),time=slice(init,None))
    ds_dia_sel = ds_dia.sel(time=slice(init,None))

    print("Flipping sign for Southern Hemisphere...")
    for var in varss:
        # Create a sign array: +1 for NH, -1 for SH
        sign = xr.where(ds_mod_sel['lat'] >= 0, 1, -1)
        ds_mod_sel[var] = ds_mod_sel[var].copy() * sign
        ds_dia_sel[var] = ds_dia_sel[var].copy() * sign
    # %%

    print(f'Length of ds_mod_sel: {len(ds_mod_sel["time"])}')

    weighted_mod_mean = ds_mod_sel
    # weighted_obs_mean = da_obs_sel.weighted(weights_obs).mean(dim='lat')
    weighted_dia_mean = ds_dia_sel


    # %%
    mod_weighted = weighted_mod_mean.isel(time=slice(0, 60))
    # obs_weighted = weighted_obs_mean.isel(time=slice(0, 50))
    dia_weighted = weighted_dia_mean.isel(time=slice(0, 60))

    print(f'Length of mod_weighted: {len(mod_weighted["time"])}')

    mod_weighted['time'] = np.arange(0, len(mod_weighted['time']))
    # obs_weighted['time'] = np.arange(0, len(obs_weighted['time']))
    dia_weighted['time'] = np.arange(0, len(dia_weighted['time']))

    mod_dict[init] = mod_weighted
    # obs_dict[init] = obs_weighted
    dia_dict[init] = dia_weighted
    print(f'Finished processing {wave} wave for {init} initialization')

    print("Clearing variables to free memory and avoid potential issues...")
    # Clear variables to free memory
    del ds_mod, ds_dia
    del ds_mod_sel, ds_dia_sel
    # del weights_mod, weights_dia
    del weighted_mod_mean, weighted_dia_mean
    del mod_weighted, dia_weighted
    gc.collect() # ✅ Good - forces immediate memory release    


print(mod_dict)
mod_concat = xr.concat(mod_dict.values(), dim='init')
# obs_comp = xr.concat(obs_dict.values(), dim='init')
dia_concat = xr.concat(dia_dict.values(), dim='init')
print(f'Concatenated mod_concat: {mod_concat}')

mod_comp = mod_concat.mean(dim='init')
# obs_comp = obs_comp.mean(dim='init')
dia_comp = dia_concat.mean(dim='init')

print(mod_comp)

print("Clearing variables to free memory and avoid potential issues...")
print("Clearing mod_dict and dia_dict...")
del mod_dict, dia_dict

print(f'Finished processing {wave} wave for {init} initialization')


print(f'Saving to {folderout}')

ds_out = xr.Dataset()

for var in varss:
    ds_out[f'{var}_mod'] = mod_comp[var]
    ds_out[f'{var}_dia'] = dia_comp[var]

# Define compression settings for all variables
compression_settings = {var: {"zlib": True, "complevel": 6} for var in ds_out.data_vars}

outfile = os.path.join(folderout, f'lifecycle_lon{ctrl_lon}_{mode}_{wave}_{season}_vorticity_budget_{e}_leaddays.nc')
ds_out.to_netcdf(outfile, encoding=compression_settings)

print(f'Vorticity budget {wave} {mode} saved to {outfile}')




# %%
