
import xarray as xr 
import sys 
import os 


# Check arguments
# if len(sys.argv) < 4:
#     print(f"Usage: {sys.argv[0]} <wave> <init> <var>")
#     print(f"Got arguments: {sys.argv}")
#     sys.exit(1)

# Generate date range

#ensemble members 
ens = ['e01', 'e02', 'e03']

# wave = "er"
# init = "19810201"
wave = sys.argv[1]
init = sys.argv[2]
# var = sys.argv[3]

folder_mod = {}
fmod = {}
ds = {}


folder_out =f"/scratch/v46/fm6730/dataout/access_s2/integrated/vorticity_budget/{wave}/"

os.makedirs(folder_out, exist_ok=True)

for e in ens:
    folder_mod[e] = f"/scratch/v46/fm6730/dataout/access_s2/integrated/vorticity_budget/{wave}/"
    fmod[e] = f"{wave}_tlag_da_vorticity_budget_{init}_{e}_remap_padded.nc"

    ds[e] = xr.open_dataset(folder_mod[e]+fmod[e]) 
    # ds[e] = ds[e].mean(dim="time_lag")

ds_ens = (ds['e01'] + ds['e02'] + ds['e03'])/3
print(ds_ens)
ds_ens_out = ds_ens.copy().mean(dim="time_lag")

encoding = {}
for var in ds_ens_out.data_vars:
    data = ds_ens_out[var]
    # Calculate scale_factor and add_offset for optimal packing
    vmin = float(data.min())
    vmax = float(data.max())
    
    # Pack into int16 (range: -32768 to 32767)
    scale_factor = (vmax - vmin) / 65534  # Leave room for missing values
    add_offset = vmin + 32767 * scale_factor
    
    encoding[var] = {
        "zlib": True, 
        "complevel": 6,
        "dtype": "int16",
        "scale_factor": scale_factor,
        "add_offset": add_offset,
        "_FillValue": -32768,
    }

ds_ens_out.to_netcdf(f"{folder_out}{wave}_tlag_da_vorticity_budget_{init}_ensmean_remap_padded.nc", encoding=encoding)


