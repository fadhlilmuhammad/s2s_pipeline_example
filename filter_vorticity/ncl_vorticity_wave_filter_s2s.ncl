load "/g/data/v46/fm6730/script_access_s2/s2s_utils.ncl"
load "/g/data/v46/fm6730/script_access_s2/kf_filter.ncl"

; vars=(/"vrD", "fD", "residual", "adv_vr_vertical", "adv_vr_zonal", "adv_vr_meridional", \\
; "vr_total_source", "vr_planetary_adv", "vr_tilt", "vr_stretch", "adv_vr", "dvr_dt"/)
; vars=(/"vrD", "fD"/)

vars = (/"vr"/)
varsobs = vars


; init = 19810201
; ens = "e01"
; wave = "er"

wave = wave
init = init
ens = ens


; diri = "/g/data/v46/fm6730/data/access_s2/rlut/"+ens_num+"_prep/"
; fili = "tlag_da_rlut_19810201_e01_remap_padded.nc"

outname = "tlag_da_vorticity_"+init+"_"+ens+"_remap_padded"
folder = "/scratch/v46/fm6730/data/access_s2/integrated/vorticity/"+ens+"_prep/"
folder_out = "/scratch/v46/fm6730/dataout/access_s2/integrated/vorticity/"+wave+"/"

system("mkdir -p "+folder_out)
system("rm "+folder_out+wave+"_"+outname+".nc")


g = addfile(folder_out+wave+"_"+outname+".nc", "c")

diri = folder


filimod = "tlag_da_vorticity_"+init+"_"+ens+"_remap_padded"
; ens_num=  
nint = 277
fili = filimod+".nc"
print(filimod)
folderout = folder_out;"/g/data/v46/fm6730/dataout/s2s_filtered/"+ens_num+"/"

HF_filter = True

do m=0, dimsizes(vars)-1
  var = vars(m)
  print("processing variable "+var +" ..." +wave)
; var  =
f    = addfile(diri+fili, "r")

latN = 30.
latS = -30.

x    = dble2flt(f->$var$(:,{latN:latS},:,:))

; time_lag = f->time_lag
; time = f->time 
; lon  = f->lon 
; lat  = f->lat({latN:latS})

dimn = dimsizes(x(:,:,:,:))
nens = dimn(3)
printVarSummary(x)

x@_FillValue = -999.
delete(x@missing_value)
printVarSummary(x)
print("Filtering...")

; mis@_FillValue = x@_FillValue

; wave_type = "mjo"
; wave  = wave_type

if wave.eq."mjo".or.wave.eq."er" then 
    print("Will do HF filtering...")
    HF_filter = True 
    nwt = 101
    freq = 100.
else if wave.eq."kelvin".or.wave.eq."td".or.wave.eq."mrg" then 
    HF_filter = True 
    nwt = 101
    freq = 20.
else if wave.eq."LF" then 
    HF_filter = False 
end if
end if
end if


if HF_filter then
print("HF filtering.... freq-"+freq)
xpass = x(0:730+277,:,:,:)

; print(xpass(:,0,120,0))
x_hipass_first = hipass_filtering_daily_ensemble(xpass, nwt, freq, nens)

; print(x_hipass_first(:,0,120,0))

x(0:730+277,:,:,:) = x_hipass_first

x_hipass = x(50:,:,:,:)
x_hipass(958-50:,:,:,:) = 0.
print("After filtering HF...")

; print(x_hipass(:,0,120,0))

else 
print("Without HF filtering....")
x_hipass = x
end if

time_lag = x_hipass&time_lag
time = x_hipass&time
lon  = x_hipass&lon
lat  = x_hipass&lat
printVarSummary((x_hipass))
printMinMax(x_hipass, False)
; printVarSummary((x_hipass))

filtered = new((/dimsizes(time_lag), dimsizes(time), dimsizes(lat), dimsizes(lon)/), float, -999.)

ndims = dimsizes(filtered)

filtered!0 = "time_lag"
filtered!1 = "time"
filtered!2 = "lat"
filtered!3 = "lon"

filtered&time_lag = time_lag
filtered&time = time
filtered&lat = lat
filtered&lon = lon

filtered@units = x@units
obsPerDay = 1

mis = -999.


; printVarSum

print("wave filtering")

; wave = waves(i)
wave_type = wave
do tlag = 0, nens-1
  
    if (wave.eq."mjo") then
        wavenumber = (/1, 5/)
        period = (/20, 100/)
        depth = (/mis, mis/)
        filtered@long_name = "Madden-Julian Oscillations in Vorticity "
    else if (wave.eq."kelvin") then
        wavenumber = (/1, 14/)
        period = (/2.5, 17/)
        depth = (/8, 90/)
        filtered@long_name = "Kelvin Waves in Vorticity "
    else if (wave.eq."er") then
        wavenumber = (/-10, -1/)
        period = (/9, 72/)
        depth = (/8, 90/)
        filtered@long_name = "Equatorial Rossby Waves in Vorticity "
    else if (wave.eq."mrg") then
        wavenumber = (/-10, -1/)
        period = (/3, 10/)
        depth = (/8, 90/)
        filtered@long_name = "Mixed Rossby-Gravity Waves in Vorticity "
    else if (wave.eq."eig") then
        wavenumber = (/1, 14/)
        period = (/1, 5/)
        depth = (/12, 50/)
        wave_type = "ig0"
        filtered@long_name = "Eastward Inertio Gravity Waves in Vorticity "
    else if (wave.eq."td") then
        wavenumber = (/-20, -6/)
        ; period = (/2.5, 10/)
        period = (/2.5, 5/)
        depth = (/mis, 90/)
        wave_type = "td-type"
        filtered@long_name = "Tropical Depression-Type Waves in Vorticity "
    else if (wave.eq."LF") then
        wavenumber = (/-99, 99/)
        ; period = (/2.5, 10/)
        period = (/120, 9999/)
        depth = (/mis, mis/)
        wave_type = "LF"
        filtered@long_name = "Low Frequency Variabilities in Vorticity "
    end if
    end if
    end if
    end if
    end if
    end if
    end if

    do y = 0, (dimsizes(lat) - 1)
        filtered(time_lag|tlag, time|:, lat|y, lon|:) = (/kf_filter(x_hipass(time_lag|tlag, time|:, lat|y, lon|:), obsPerDay, period(0), period(1), wavenumber(0), wavenumber(1), depth(0), depth(1), wave_type)/)
        ; print((/lat(y)/))
        ; printMinMax((filtered), 0)
    end do
end do

printVarSummary(filtered)
printMinMax(filtered, False)

print("Opening the output file...")

; print(filtered(0,:,0,120))


; outname="tlag_da_var_19880801_e01_remap_padded"

print("Writing the output file...")

date_filtered = cd_calendar(filtered&time, -2)
idinit = ind(date_filtered.eq.init)
print(idinit)
print(date_filtered(idinit))
if wave.eq."LF" then 
    g->$var$ = filtered(time|50:,lat|:,lon|:,time_lag|:)
else
    g->$var$ = filtered(time|idinit:idinit+380,lat|:,lon|:,time_lag|:)
end if

print(filtered(time|idinit:idinit+380,lat|0,lon|0,time_lag|0))
print("Closing the output file...")

delete(filtered)

end do 


print("Compressing the output file...")
outfile = wave+"_"+outname+".nc"
compress_script = "/g/data/v46/fm6730/script_access_s2/vorticity/filter_vorticity_budget/compress_filter_s2s.py"
system("python "+compress_script+" "+folder_out+ " "+folder_out+ " " + outfile + " " + outfile)
; delete(period)
; delete(wavenumber)
; delete(depth)