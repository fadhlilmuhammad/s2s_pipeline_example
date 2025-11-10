
load "/g/data/v46/fm6730/script_access_s2/s2s_utils.ncl"

mode="linearremove"

vars=(/"vr"/)
; vars=(/"vrD", "fD"/)
varsobs = vars

init = init 
ens = ens

; init = 19810201
; ens = "e01"
; var = "rlut"
; varobs = "field"
; var = var
; varobs = "adv_q"
; var = "conv_q"
; varobs = "conv_q"

; var = "ua"
; varobs = "u"
lev = ""
; var = "rlut"
; varobs = "field"
folderin = "/scratch/v46/fm6730/data/obs/integrated/"
folder = "/scratch/v46/fm6730/data/access_s2/integrated/vorticity/"+ens+"_tlag_long/"
folder_out = "/scratch/v46/fm6730/data/access_s2/integrated/vorticity/"+ens+"_prep/"
outname = "tlag_da_vorticity_"+init+"_"+ens+"_remap_padded"

dirout = folder_out
filo   = outname
system("mkdir -p "+folder_out)
filimod = "tlag_da_vorticity_"+init+"_"+ens+"_remap"
fili     = "vorticity/merged/vorticity.era.daymean.1979-2020.nc"
; fclim = addfile(folderin + "access_s2/"+var+"_access_s2_lead_time_clim.nc", "r")
setfileoption("nc","CompressionLevel",6)
setfileoption("nc","Format","NetCDF4Classic")
system("rm "+dirout+filo+".nc")

print("writing to file")
fnc = addfile(dirout+filo+".nc", "c")

; fili     = "field.day.mean.nc"
f      = addfile(folderin + fili, "r")
fmod   = addfile(folder + filimod+".nc", "r")


do m = 0, dimsizes(vars)-1
  var = vars(m)
  print("processing variable "+var)
  varobs = var

  field   = dble2flt(f->$varobs$)
  field_mod= dble2flt(fmod->$var$)
  ; model_mean = fclim->$var$

  ystrt = 19810101
  ylast = 20181231

  printVarSummary(field)
  printVarSummary(field_mod)
  time_ind  = field&time 
  date_ind  = cd_calendar(time_ind,-2)
  istrt = ind(date_ind.eq.ystrt)
  ilast = ind(date_ind.eq.ylast)

    ;Fill missing data
    guess     = 1                ; use zonal means
    is_cyclic = True             ; cyclic [global]
    nscan     = 500             ; usually much less than this
    eps       = 1.e-2            ; variable dependent
    relc      = 0.6              ; relaxation coefficient
    opt_fill       = 0                ; not used

    num_missing_obs = num(ismissing(field_mod))
    print(num_missing_obs)

  if (any(ismissing(field_mod))) then 
  print("fill missing data (ACCESS)...")
    poisson_grid_fill( field_mod, is_cyclic, guess, nscan, eps, relc, opt_fill)
  end if


  if (any(ismissing(field))) then
    print("fill missing data (OBS)...")
    poisson_grid_fill( field, is_cyclic, guess, nscan, eps, relc, opt_fill)
  end if

  printVarSummary(field_mod)

  ndims  = dimsizes(field_mod)

  if (var.eq."ua").or.(var.eq."va") then 
  xobs   = remove_harmonic_cycle(field(:,:,:),field(istrt:ilast,:,:), 3)
  else 
  xobs   = remove_harmonic_cycle(field,field(istrt:ilast,:,:), 3)
  end if

  nint   = 277
  nharm  = 3
  npad   = 365
  nfil   = 365

  ; print(field_mod&time)
  print("removing harmonic cycle")
  if (var.eq."ua").or.(var.eq."va") then 
  x = remove_harmonic_cycle_ensemble(field_mod, field(istrt:ilast,:,:), nharm)
  else  
  x = remove_harmonic_cycle_ensemble(field_mod, field(istrt:ilast,:,:), nharm)
  end if
  printVarSummary(x)

  time   = x&time
  date   = cd_calendar(time, -2)

  time_obs = field&time
  date_obs = cd_calendar(time_obs, -2)

  idate  = new((/dimsizes(date)/), integer)
  do i = 0, dimsizes(date)-1
    idate(i) = ind(date_obs.eq.date(i))
  end do

  ;Removing Model Drift

  print("remove model drift")
  if mode.eq."leadtimeclim" then 
    xanom = remove_model_mean_bias_ensemble(x, nint, model_mean)
  else if mode.eq."linearremove" then 
  ; Remove the time mean
    xanom = remove_linear_trend(x, nint)
  end if
  end if

  ; printVarSummary(xobs)

  init_mod = date(0)
  ind_init = ind(init_mod.eq.date_obs)

  printVarSummary(xobs)
  printVarSummary(xanom)

  ; printVarSummary(xanom)
  print(cd_calendar(time_obs(ind_init),-2))
  ; print(cd_calendar(time(ind(date.eq.init_mod)),-2))
  print("obs padding")
  xpad   = observation_padding_ensemble(xanom, xobs, ind_init, toint(npad*2))

  printVarSummary((xpad&time))


  print("half taper ensemble")
  xtaper = half_taper_ensemble(xpad,nfil, 0)

  print("zero padding ensemble")
  xpad_zero = zero_padding_ensemble(xtaper, npad*2-nint-1)
  printVarSummary((xpad_zero))

  print("assigning time")
  time_padded = xpad_zero&time
  printVarSummary((time_padded))
  ; print(cd_calendar(time_padded,-2))

  copy_VarAtts(field_mod, xpad_zero)
  fnc->$var$ = xpad_zero(time|:,lat|:,lon|:,time_lag|:)

end do
  print("finished.. saved in "+ dirout+filo+".nc")


  ; delete(fnc)
  ; print("Compressing the output file...")

  ; system("sync")
  ; system("sleep 2")
  
  ; ; Verify file is readable before compressing
  ; system("ncdump -h " + dirout + filo + ".nc | head -20")
  
  ; ; Set permissions to ensure Python can read/write
  ; system("chmod 664 " + dirout + filo + ".nc")

  ; outfile = outname+".nc"
  ; compress_script = "/g/data/v46/fm6730/script_access_s2/vorticity/filter_vorticity_budget/compress_filter_s2s.py"
  ; system("python "+compress_script+" "+folder_out+ " "+folder_out+ " " + outname + " " + outname)


