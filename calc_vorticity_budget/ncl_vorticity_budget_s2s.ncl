

load "/g/data/v46/fm6730/script_access_s2/vorticity_copy/s2s_utils.ncl"

; init = 19980201
; ens = "e01"

init = init 
ens = ens

print(init)
print(ens)

start_time = systemfunc("date +%s")
print("Script started at: " + systemfunc("date"))

fili_w =  "/g/data/ux62/access-s2/hindcast/raw_model/atmos/wa/daily/"+ens+"/da_wa_"+init+"_"+ens+".nc"
fili_u =  "/g/data/ux62/access-s2/hindcast/raw_model/atmos/ua/daily/"+ens+"/da_ua_"+init+"_"+ens+".nc"
fili_v =  "/g/data/ux62/access-s2/hindcast/raw_model/atmos/va/daily/"+ens+"/da_va_"+init+"_"+ens+".nc"

latN = 35
latS = -latN

fw = addfile(fili_w, "r")
fu = addfile(fili_u, "r")
fv = addfile(fili_v, "r")


plev = 850.

g    = 9.81          ; m/s2

coord_model = fw->wa
printVarSummary(coord_model)
lev_all = coord_model&z1_p_level
ilev = ind(lev_all.eq.plev)
lev = lev_all(ilev-1:ilev+1)

print(lev)
delete(coord_model)

w = short2flt(fw->wa(:,ilev-1:ilev+1,{latS:latN},:))
u = short2flt(fu->ua(:,ilev-1:ilev+1,{latS:latN},:))
v = short2flt(fv->va(:,ilev-1:ilev+1,{latS:latN},:))

lon = u&lon 
lat = u&lat
time = u&time
print("Reading variables...")

printVarSummary(w)
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

if any(ismissing(w)) then
    print("w contains missing values")
    poisson_grid_fill(w, is_cyclic, guess_type, nscan, epsx, relc, opt)
    print("w filled")
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

div = uv2dv_cfd(u,v,u&lat,u&lon, 3)
copy_VarCoords(u, div)
div@long_name = "Divergence"
div@units = "s^-1"
printVarSummary(div)
printMinMax(div, False)

; Some of this are taken and modified from https://github.com/sandrolubis/Moisture_Budget/blob/main/cal_vint_moist_budget.ncl

print("Calculating vorticity tendency...")
vr1 = vr
vr1(1:ntime-1,:,:,:) = (/vr(0:ntime-2,:,:,:)/)

dvr_dt = (/(vr-vr1)/86400.0/)
copy_VarCoords(vr, dvr_dt)

delete(vr1)
dvr_dt@long_name = "Local time derivative of horizontal wind"
dvr_dt@units = "s^-2"
printVarSummary(dvr_dt)
printMinMax(dvr_dt, False)


print("Calculating vorticity advection...")
dvr_dx = center_finite_diff_n(vr, lon * rad, True, 0, 3) / conform(vr, re * cos(lat * rad), 2)
dvr_dy = center_finite_diff_n(vr, lat * rad, False, 0, 2) / re
dvr_dp = center_finite_diff_n(vr, lev * 100., False, 0, 1) ;hPa to Pa

adv_vr_zonal 		= -u * dvr_dx
adv_vr_meridional 	= -v * dvr_dy
adv_vr_vertical 	= -w * dvr_dp
copy_VarCoords(vr, adv_vr_zonal)
adv_vr_zonal@long_name = "Zonal advection of relative vorticity"
copy_VarCoords(vr, adv_vr_meridional)
adv_vr_zonal@units = "s^-2"
printVarSummary(adv_vr_zonal)
printMinMax(adv_vr_zonal, False)

adv_vr_meridional@long_name = "Meridional advection of relative vorticity"
copy_VarCoords(vr, adv_vr_meridional)
adv_vr_meridional@units = "s^-2"
printVarSummary(adv_vr_meridional)
printMinMax(adv_vr_meridional, False)

adv_vr_vertical@long_name = "Vertical advection of relative vorticity"
copy_VarCoords(vr, adv_vr_vertical)
adv_vr_vertical@units = "s^-2"
printVarSummary(adv_vr_vertical)
printMinMax(adv_vr_vertical, False)

adv_vr = adv_vr_zonal + adv_vr_meridional + adv_vr_vertical
copy_VarCoords(vr, adv_vr)
adv_vr@long_name = "Advection of relative vorticity"
adv_vr@units = "s^-2"
printVarSummary(adv_vr)
printMinMax(adv_vr, False)

print("Calculating Vortex Stretching...")
vrD = -vr*div 
copy_VarCoords(vr, vrD)
vrD@long_name = "Vortex stretching term (eta D)"
vrD@units = "s^-2"
printVarSummary(vrD)    

f = 2 * 7.2921*10^-5 * sin(lat * rad)
copy_VarCoords(vr&lat, f)
f@long_name = "Coriolis parameter"
f@units = "s^-1"
printVarSummary(f)
printMinMax(f, False)


fD  = -conform(div, f, 2)*div 
copy_VarCoords(div, fD)
fD@long_name = "Planetary vorticity stretching term (f D)"
fD@units = "s^-2"
printVarSummary(fD)

vr_stretch = vrD + fD
copy_VarCoords(vr, vr_stretch)
vr_stretch@long_name = "Vortex stretching term (eta D + f D)"
vr_stretch@units = "s^-2"
printVarSummary(vr_stretch)
printMinMax(vr_stretch, False)

print("Calculating Vortex Tilting...")
dw_dx = center_finite_diff_n(w, lon * rad, True, 0, 3) / conform(w, re * cos(lat * rad), 2) 
dw_dy = center_finite_diff_n(w, lat * rad, False, 0, 2) / re
dv_dp = center_finite_diff_n(v, lev * 100., False, 0, 1)
du_dp = center_finite_diff_n(u, lev * 100., False, 0, 1)

vr_tilt = -(dw_dx * dv_dp - dw_dy * du_dp)
copy_VarCoords(vr, vr_tilt)
vr_tilt@long_name = "Vortex tilting term (-dwdx dvdp + dwdy dudp)"
vr_tilt@units = "s^-2"
printVarSummary(vr_tilt)
printMinMax(vr_tilt, False)

print("Calculating Planetary Vorticity Advection...")
beta = 2 * 7.2921*10^-5 * cos(lat * rad) / re

vr_planetary_adv = -v * conform(v, beta, 2)
copy_VarCoords(vr, vr_planetary_adv)
vr_planetary_adv@long_name = "Planetary vorticity advection term (-Bv)"
vr_planetary_adv@units = "s^-2"
printVarSummary(vr_planetary_adv)
printMinMax(vr_planetary_adv, False)

print("Calculating residual...")
residual = dvr_dt - adv_vr - vr_stretch - vr_tilt - vr_planetary_adv
copy_VarCoords(vr, residual)
residual@long_name = "Vorticity tendency residual (dvr_dt - Adv - Stretch - Tilt - Planetary Adv)"
residual@units = "s^-2"
printVarSummary(residual)

vr_total_source = vr_planetary_adv + fD
copy_VarCoords(vr, vr_total_source)
vr_total_source@long_name = "Total vorticity source term (-Bv + -fD)"
vr_total_source@units = "s^-2"
printVarSummary(vr_total_source)
printMinMax(vr_total_source, False)

coords = addfile("/g/data/v46/fm6730/data/access_s2/u850/e01/da_ua_19810130_e01_remap.nc", "r")
coords_lat = coords->lat
coords_lon = coords->lon

fo_vr = area_conserve_remap_Wrap (vr&lon,vr&lat,vr, coords_lon,coords_lat({latS:latN}), False)
fo_div = area_conserve_remap_Wrap (div&lon,div&lat,div, coords_lon,coords_lat({latS:latN}), False)
fo_dvr_dt = area_conserve_remap_Wrap (dvr_dt&lon,dvr_dt&lat,dvr_dt, coords_lon,coords_lat({latS:latN}), False)
fo_adv_vr = area_conserve_remap_Wrap (adv_vr&lon,adv_vr&lat,adv_vr, coords_lon,coords_lat({latS:latN}), False)
fo_vr_stretch = area_conserve_remap_Wrap (vr_stretch&lon,vr_stretch&lat,vr_stretch, coords_lon,coords_lat({latS:latN}), False)
fo_vr_tilt = area_conserve_remap_Wrap (vr_tilt&lon,vr_tilt&lat,vr_tilt, coords_lon,coords_lat({latS:latN}), False)
fo_vr_planetary_adv = area_conserve_remap_Wrap (vr_planetary_adv&lon,vr_planetary_adv&lat,vr_planetary_adv, coords_lon,coords_lat({latS:latN}), False)
fo_vr_total_source = area_conserve_remap_Wrap (vr_total_source&lon,vr_total_source&lat,vr_total_source, coords_lon,coords_lat({latS:latN}), False)

fo_adv_vr_zonal = area_conserve_remap_Wrap (adv_vr_zonal&lon,adv_vr_zonal&lat,adv_vr_zonal, coords_lon,coords_lat({latS:latN}), False)
fo_adv_vr_meridional = area_conserve_remap_Wrap (adv_vr_meridional&lon,adv_vr_meridional&lat,adv_vr_meridional, coords_lon,coords_lat({latS:latN}), False)
fo_adv_vr_vertical = area_conserve_remap_Wrap (adv_vr_vertical&lon,adv_vr_vertical&lat,adv_vr_vertical, coords_lon,coords_lat({latS:latN}), False)
fo_residual = area_conserve_remap_Wrap (residual&lon,residual&lat,residual, coords_lon,coords_lat({latS:latN}), False)  
fo_fD = area_conserve_remap_Wrap (fD&lon,fD&lat,fD, coords_lon,coords_lat({latS:latN}), False)
fo_vrD = area_conserve_remap_Wrap (vrD&lon,vrD&lat,vrD, coords_lon,coords_lat({latS:latN}), False)

print("Writing output files...")

setfileoption("nc","Format","NETCDF4")
folder1 = "/scratch/v46/fm6730/data/access_s2/integrated/vorticity_budget/"+ens+"/"
system("mkdir -p "+folder1)

filo1 = folder1+"da_vorticity_budget_"+init+"_"+ens+"_remap"+".nc"
system("rm "+filo1)

fout = addfile(filo1, "c")
fout->vr = fo_vr(:,{plev},:,:)
fout->div = fo_div(:,{plev},:,:)
fout->dvr_dt = fo_dvr_dt(:,{plev},:,:)
fout->adv_vr = fo_adv_vr(:,{plev},:,:)
fout->vr_stretch = fo_vr_stretch(:,{plev},:,:)
fout->vr_tilt = fo_vr_tilt(:,{plev},:,:)
fout->vr_planetary_adv = fo_vr_planetary_adv(:,{plev},:,:)
fout->vr_total_source = fo_vr_total_source(:,{plev},:,:)
fout->adv_vr_zonal = fo_adv_vr_zonal(:,{plev},:,:)
fout->adv_vr_meridional = fo_adv_vr_meridional(:,{plev},:,:)
fout->adv_vr_vertical = fo_adv_vr_vertical(:,{plev},:,:)
fout->residual = fo_residual(:,{plev},:,:)
fout->fD = fo_fD(:,{plev},:,:)
fout->vrD = fo_vrD(:,{plev},:,:)

fout@title = "Vorticity budget terms at 850 hPa"
fout@history = "Created by NCL script on " + systemfunc("date")
fout@source_file = fili_u + " and " + fili_v + " and " + fili_w
fout@creation_date = systemfunc("date")
fout@institution = "The University of Melbourne"
fout@source = "ACCESS-S2 model data"
fout@model = "ACCESS-S2"
fout@experiment = ens
fout@project = "ACCESS-S2 Seasonal Prediction"
fout@Conventions = "CF-1.6" 