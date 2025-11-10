

load "/g/data/v46/fm6730/script_access_s2/s2s_utils.ncl"

; year = 2000

year = year

start_time = systemfunc("date +%s")
print("Script started at: " + systemfunc("date"))

fili_u =  "/g/data/su28/ERA5/daily/u/"+"u_era5_oper_pl_merge_1deg_daily_"+year+".nc"
fili_v =  "/g/data/su28/ERA5/daily/v/"+"v_era5_oper_pl_merge_1deg_daily_"+year+".nc"

latN = 35
latS = -latN

fu = addfile(fili_u, "r")
fv = addfile(fili_v, "r")


plev = 850.

g    = 9.81          ; m/s2

coord_model = fu->u
printVarSummary(coord_model)
lev_all = coord_model&level
ilev = ind(lev_all.eq.plev)
lev = lev_all(ilev-1:ilev+1)

print(lev)
delete(coord_model)

u = short2flt(fu->u(:,ilev,{latS:latN},:))
v = short2flt(fv->v(:,ilev,{latS:latN},:))

lon = u&lon 
lat = u&lat
time = u&time
print("Reading variables...")

printVarSummary(u)
printVarSummary(v)

ntime = dimsizes(time)

;gridfill if any of the variables contain missing values;
guess_type = 1                ; use zonal means
is_cyclic  = True             ; cyclic [global]
nscan      = 500             ; usually much less than this
epsx       = 1.e-2            ; variable dependent
relc       = 0.6              ; relaxation coefficient
opt        = 0                ; not used

if any(ismissing(u)) then
    print("u contains missing values")
    poisson_grid_fill(u, is_cyclic, guess_type, nscan, epsx, relc, opt)
    print("u filled")
end if

if any(ismissing(v)) then
    print("v contains missing values")
    poisson_grid_fill(v, is_cyclic, guess_type, nscan, epsx, relc, opt)
    print("v filled")
end if

print("Calculating vorticity and divergence...")

rad = get_d2r("float")
re = 6.371e+06
; g=9.81

vr = uv2vr_cfd(u,v,u&lat,u&lon, 3)
copy_VarCoords(u, vr)
vr@long_name = "Vorticity"
vr@units = "s^-1"
printVarSummary(vr)
printMinMax(vr, False)

coords = addfile("/g/data/v46/fm6730/data/access_s2/u850/e01/da_ua_19810130_e01_remap.nc", "r")
coords_lat = coords->lat
coords_lon = coords->lon

fo_vr = area_conserve_remap_Wrap (vr&lon,vr&lat,vr, coords_lon,coords_lat({latS:latN}), False)

print("Writing output files...")

setfileoption("nc","Format","NETCDF4")
folder1 = "/scratch/v46/fm6730/data/obs/vorticity/"
system("mkdir -p "+folder1)

filo1 = folder1+"vorticity_obs_"+year+"_remap"+".nc"
system("rm "+filo1)

fout = addfile(filo1, "c")
fout->vr = fo_vr(:,:,:)

fout@title = "Vorticity at 850 hPa"
fout@history = "Created by NCL script on " + systemfunc("date")
fout@source_file = fili_u + " and " + fili_v + " and " + fili_w
fout@creation_date = systemfunc("date")
fout@institution = "The University of Melbourne"
fout@source = "ERA5 Reanalysis"
fout@project = "ACCESS-S2 Seasonal Prediction"
fout@Conventions = "CF-1.6" 