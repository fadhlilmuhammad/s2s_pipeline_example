
import xarray as xr
import numpy as np
import os

import sys


# folder = "/scratch/v46/fm6730/dataout/access_s2/integrated/vorticity_budget/er/"
folder = sys.argv[1]
folderout = sys.argv[2]
fname = sys.argv[3]
foutname = sys.argv[4]

variables = ["vr","div","vr_tilt", "vr_planetary_adv", "vr_total_source", "residual", "vr_stretch", "fD", "vrD", "adv_vr_zonal", "adv_vr_meridional", "adv_vr", "adv_vr_vertical"]
# variables = ["vr_tilt"]

print(f"Processing variable:")
ds = xr.open_dataset(f"{folder}{fname}")
encoding = {}
for var in ds.data_vars:
    data = ds[var]
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
ds.to_netcdf(f"{folderout}{foutname}", encoding=encoding)
ds.close()