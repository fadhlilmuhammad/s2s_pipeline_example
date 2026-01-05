; UTILITY codes
;

load "/g/data/v46/fm6730/script/tc_senyar/wkSpaceTime_mod.ncl"
load "/g/data/v46/fm6730/script/tc_senyar/utils.ncl"


; data must be 3D (time, lat, lon)
; nint must be integer
; tname is the name of the time dimension, in string

undef ("obs_integration")
function obs_integration (\
  data[*][*][*]  : numeric, \
  nint           : integer, \
  tname          : string   \
  )

local None
begin

  ndims = dimsizes(data)
  ntim  = ndims(0)
  nlat  = ndims(1)
  nlon  = ndims(2)

  time  = data&$tname$

  x     = new((/ntim-nint, nint, nlat, nlon/), float)
  x!0   = "n_init"


  do t = 0, ntim-nint-1
    x(t,:,:,:) = data(t:t+(nint-1),:,:)
  end do

  delete(x&$tname$)
  x!1 = "time"
  x&time = ispan(0,nint-1,1)
  printVarSummary(x)

  return(x)
end


;TIME LAGGED ENSEMBLE FOR ACCESS-S2
undef ("time_lag_ens_access_s2")
function time_lag_ens_access_s2 (\
  data_lag2[*][*][*]   : numeric, \
  data_lag1[*][*][*]   : numeric, \
  data_lag0[*][*][*]   : numeric, \
  nint                 : integer \
)

local None
begin
  x_lag2     = data_lag2(2:nint+2-1,:,:)   ;remove the last 2 days
  x_lag1     = data_lag1(1:nint+1-1,:,:)   ;remove the last 1 day
  x_lag0     = data_lag0(0:nint-1,:,:)   ;reference day

  ndims  = dimsizes(x_lag2)
  nlat   = ndims(1)
  nlon   = ndims(2)

  x      = new((/3, nint, nlat, nlon/), float)

  x(0,:,:,:) = x_lag2
  x(1,:,:,:) = x_lag1
  x(2,:,:,:) = x_lag0

  x!0 = "time_lag"
  x&time_lag = (/-2,-1,0/)
  x@time_lag = "lagged by 2, 1, and 0 days"

  return(x)
end


;;;;GET THE 4TH HARMONICS

undef ("get_harmonic_cycle")
function get_harmonic_cycle (\
  data[*][*][*]       : numeric,\
  nharm               : integer \
)

local time, TIME, year, month, day, ddd, yyyyddd
begin
   time    = data&time                          ; time:units = "hours since 1-1-1 00:00:0.0"
   TIME    = cd_calendar(time, 0)          ; type float
   year    = toint( TIME(:,0) )
   month   = toint( TIME(:,1) )
   day     = toint( TIME(:,2) )
                                                                 ; check for calendar attribute
   if (isatt(TIME,"calendar")) then           ; default is gregorian
       year@calendar = TIME@calendar
   end if

   ddd     = day_of_year(year, month, day)
   if (isatt(year,"calendar")) then           ; default is gregorian
       ddd@calendar = year@calendar
   end if

   yyyyddd = year*1000 + ddd                                    ; needed for input
   if (isatt(ddd,"calendar")) then           ; default is gregorian
       yyyyddd@calendar = ddd@calendar
   end if

  hClmDay    = clmDayTLL(data, yyyyddd)
  x = smthClmDayTLL(hClmDay, nharm)

return (x)
end


undef ("remove_harmonic_cycle")
function remove_harmonic_cycle(\
  data[*][*][*]       : numeric,\
  data_clm[*][*][*]   : numeric,\
  nharm               : integer \
)

local time, TIME, year, month, day, ddd, yyyyddd
begin
  xclm  = get_harmonic_cycle(data_clm, nharm)

  ; printVarSummary(xclm)
  time = data&time
  ; time@calendar = "standard"

  utc_date = cd_calendar(time,0)
  year   = tointeger(utc_date(:,0))    ; Convert to integer for
  month  = tointeger(utc_date(:,1))    ; use sprinti
  day    = tointeger(utc_date(:,2))

  xAnom  = data
  doy    = day_of_year(year, month, day)
  ; print(doy)

  ; printVarSummary(xclm)
  do i = 0, dimsizes(doy)-1
    ; print(i)
    d = doy(i)
    ; printVarSummary(data(i,:,:))
    ; printVarSummary(xclm({d},:,:))
    xAnom(i,:,:) = data(i,:,:) - xclm({d},:,:); write loop content
  end do


  ; xAnom = calcDayAnomTLL(data, yyyyddd, xclm)
  xAnom@long_name = "Anomalies from Smooth Daily Climatology harmonic-"+nharm

  ; copy_VarCoords()

  return(xAnom)
end


undef ("remove_harmonic_cycle_ensemble")
function remove_harmonic_cycle_ensemble (\
  data[*][*][*][*]    : numeric,\
  data_clm[*][*][*]   : numeric,\
  nharm               : integer \
)

begin
  ndims = dimsizes(data)
  nens  = ndims(0)

  x     = new((/nens, ndims(1), ndims(2), ndims(3)/), typeof(data))

  do e = 0, nens-1
    x(e,:,:,:) = remove_harmonic_cycle(data(e,:,:,:), data_clm, nharm); write loop content
  end do

  copy_VarMeta(data, x)
  return(x)
end

undef ("remove_model_mean_bias")
function remove_model_mean_bias(\
  model[*][*][*]      : numeric,\
  ninit               : integer \
)

begin
  model_mean =  dim_avg_n_Wrap(model(0:ninit-1,:,:), 0)
  xanom  = model(0:ninit-1,:,:) - conform_dims(dimsizes(model(0:ninit-1,:,:)), model_mean, (/1,2/))
  copy_VarMeta(model(0:ninit-1,:,:), xanom)
  return(xanom)
end

undef ("remove_model_mean_bias_ensemble")
function remove_model_mean_bias_ensemble(\
  model[*][*][*][*]   : numeric,\
  ninit               : integer\
)
begin

  ndims = dimsizes(model)

  xanom = new((/ndims(0), ndims(1), ndims(2), ndims(3)/), typeof(model))
  do e = 0, ndims(0)-1
    ; printVarSummary(model(e,0:ninit-1,:,:))
    model_mean =  dim_avg_n_Wrap(model(e,0:ninit-1,:,:), 0)
    xanom(e,:,:,:)  = model(e,0:ninit-1,:,:) - conform_dims(dimsizes(model(e,0:ninit-1,:,:)), model_mean, (/1,2/))
    ; copy_VarMeta(model(e,0:ninit-1,:,:), xanom(e,:,:,:))
  end do
    xanom!0 = "time_lag"
    xanom&time_lag = (/-2,-1,0/)
    xanom@time_lag = "lagged by 2, 1, and 0 days"

    xanom!1 = "time"
    time = model&time
    xanom&time = time(0:ninit-1)

    xanom!2 = "lat"
    xanom&lat = model&lat

    xanom!3 = "lon"
    xanom&lon = model&lon
    printVarSummary(xanom)
    return(xanom)
end


undef ("observation_padding")
function observation_padding(\
  data[*][*][*]      : numeric,\
  pad[*][*][*]       : numeric,\
  ind_init           : integer,\
  npad               : integer \
)

local time, date, time_add, ndims, ntim,nlat,nlon
begin

  data!0 = "time"
  time  = data&time
  date  = cd_calendar(time,-2)

  time_add = new((/dimsizes(date)+npad/), typeof(time))

  do d = 0, npad-1
    ; print(time(d))
    time_add(d) = time(0) - npad + d
  end do

  time_add(npad:) = time
  ; print(cd_calendar(time_add,-2))

  ndims = dimsizes(data)
  ntim  = ndims(0)
  nlat  = ndims(1)
  nlon  = ndims(2)

  x = new((/ntim+npad, nlat, nlon/), float)
  x(0:npad-1,:,:) = pad((ind_init - npad):ind_init-1, :, :)
  x(npad:,:,:)    = data

  x!0 = "time"
  x!1 = "lat"
  x!2 = "lon"

  x&time = time_add
  x&lat  = data&lat
  x&lon  = data&lon

  return(x)
end

undef ("observation_padding_ensemble")
function observation_padding_ensemble(\
  data[*][*][*][*]   : numeric,\
  pad[*][*][*]       : numeric,\
  ind_init           : integer,\
  npad               : integer \
)
begin
  ndims = dimsizes(data)
  nens  = ndims(0)
  ntim  = ndims(1)
  nlat  = ndims(2)
  nlon  = ndims(3)
  x = new((/nens, ntim+npad, nlat, nlon/), typeof(data))
  do e = 0, nens-1
    x(e,:,:,:) = observation_padding(data(e,:,:,:), pad, ind_init, npad)
  end do
  x!0 = "time_lag"
  x&time_lag = (/-2,-1,0/)
  x@time_lag = "lagged by 2, 1, and 0 days"

  return(x)
end


undef ("zero_padding")
function zero_padding(\
  data[*][*][*]     : numeric, \
  npad              : integer
)

local time, date, time_add, ndims, ntim,nlat,nlon
begin
  data!0 = "time"
  time  = data&time
  printVarSummary(time)
  date  = cd_calendar(time,-2)

  time_add = new((/dimsizes(date)+npad/), typeof(time))

  ; printVarSummary(time)
  ; printVarSummary(time_add)
  time_add(0:dimsizes(date)-1) = time
  do d = 0, npad-1
    time_add(dimsizes(date)+d) = time(dimsizes(date)-1) + d
  end do

  ; print(time_add)
  ndims = dimsizes(data)
  ntim  = ndims(0)
  nlat  = ndims(1)
  nlon  = ndims(2)

  x = new((/ntim+npad, nlat, nlon/), float)
  x(0:ntim-1,:,:)  = data
  x(ntim:npad,:,:) = 0

  x!0 = "time"
  x!1 = "lat"
  x!2 = "lon"

  x&time = time_add
  x&lat  = data&lat
  x&lon  = data&lon

  return(x)

end


undef ("zero_padding_hourly")
function zero_padding_hourly(\
  data[*][*][*]     : numeric, \
  npad              : integer, \
  hour_interval     : integer  \
)

local time, time_units, date_start, ntim, nlat, nlon, time_new, x
begin
  data!0 = "time"
  time   = data&time
  time_units = time@units

  ndims = dimsizes(data)
  ntim  = ndims(0)
  nlat  = ndims(1)
  nlon  = ndims(2)

  ; Get last time value and create padded time array
  date_last = cd_calendar(time(ntim-1), 0)
  last_year  = toint(date_last(0,0))
  last_month = toint(date_last(0,1))
  last_day   = toint(date_last(0,2))
  last_hour  = toint(date_last(0,3))

  ; Create new time coordinate (original + padded)
  time_new = new((/ntim + npad/), typeof(time))
  time_new(0:ntim-1) = time

  ; Add padded times at hour_interval spacing
  do d = 0, npad-1
    time_new(ntim + d) = time(ntim-1) + (d+1) * hour_interval
  end do

  time_new!0 = "time"
  time_new@units = time_units
  if (isatt(time, "calendar")) then
    time_new@calendar = time@calendar
  end if

  ; Create padded data array
  x = new((/ntim + npad, nlat, nlon/), float)
  x(0:ntim-1, :, :) = data
  x(ntim:, :, :)    = 0

  x!0 = "time"
  x!1 = "lat"
  x!2 = "lon"

  x&time = time_new
  x&lat  = data&lat
  x&lon  = data&lon

  return(x)
end


undef ("gribcode_to_variable_name")
function gribcode_to_variable_name(\
  grib_code : string \
) 

begin 

  if (grib_code .eq. "u") then
    var_name = "var131"
  else if (grib_code .eq. "v") then
    var_name = "var132"
  else if (grib_code .eq. "q") then
    var_name = "var133"
  else if (grib_code .eq. "t") then
    var_name = "var167"
  else if (grib_code .eq. "w") then
    var_name = "var135"
  else
    var_name = "unknown_variable"
  end if
  end if 
  end if 
  end if 
  end if

  return(var_name)

end 


undef ("zero_padding_ensemble")
function zero_padding_ensemble(\
data[*][*][*][*]  : numeric, \
npad              : integer
)
begin
  ndims = dimsizes(data)
  nens  = ndims(0)
  ntim  = ndims(1)
  nlat  = ndims(2)
  nlon  = ndims(3)

  x    = new((/nens, ntim+npad, nlat, nlon/), float)
  do e = 0, nens-1
    x(e,:,:,:) = zero_padding(data(e,:,:,:), npad)
  end do

  x!0 = "time_lag"
  x&time_lag = (/-2,-1,0/)
  x@time_lag = "lagged by 2, 1, and 0 days"

  return(x)

end


undef ("data_taper_n")
function data_taper_n(\
  data[*][*][*]     : numeric,\
  n                 : integer,\
  days_to_taper     : integer \
)
begin
  ndim  = dimsizes(data)

  nsize = ndim(n)

  p     = tofloat(days_to_taper)/tofloat(nsize)
  ; print(p)

  x     = taper_n(data, p, 1, n)
  copy_VarMeta(data, x)

  return(x)

end

undef("half_taper")
function half_taper(\
  data[*][*][*]     : numeric,\
  days_to_taper     : integer,\
  force_zero        : integer \
)
begin
  ndim  = dimsizes(data)

  nsize = ndim(0)

  p     = tofloat(days_to_taper)/tofloat(nsize)
  ; print(p)


  wgt = new((/nsize, ndim(1), ndim(2)/), typeof(data))
  do t = 0, nsize-1
    wgt(t,:,:)   = 0.5*(1 - cos(get_pi("f")*(t+0.5)/nsize))
    if force_zero.eq.1 then
      wgt(t,:,:) = where(wgt(t,:,:).le.0.1, 0, wgt(t,:,:))
    end if
  end do

  print(wgt(:,20,100))
  x = data
  x(0:days_to_taper-1,:,:) = data(0:days_to_taper-1,:,:) * wgt(0:days_to_taper-1,:,:)
  ; x     = taper_n(data, p, 1, n)
  copy_VarMeta(data, x)

  return(x)

end

undef ("half_taper_ensemble")
function half_taper_ensemble(\
  data[*][*][*][*]   : numeric,\
  days_to_taper      : integer,\
  force_zero         : integer \
)

begin
  ndims = dimsizes(data)
  nens  = ndims(0)
  ntim  = ndims(1)
  nlat  = ndims(2)
  nlon  = ndims(3)

  x = new((/nens, ntim, nlat, nlon/), typeof(data))
  do e = 0, nens-1
    x(e, :,:,:) = half_taper(data(e,:,:,:), days_to_taper, force_zero)
  end do

  x!0 = "time_lag"
  x&time_lag = (/-2,-1,0/)
  x@time_lag = "lagged by 2, 1, and 0 days"

  return(x)
end


undef ("wkSpaceTime_S2S")
procedure wkSpaceTime_S2S(\
  data[*][*][*]     : numeric,\
  data_clm[*][*][*] : numeric,\
  var               : string, \
  diro              : string, \
  case              : string, \
  latN              : numeric,\
  cpd               : integer,\
  nDayWin           : integer,\
  nDaySkip          : integer,\
  opt \
)

begin
  data_clm!0 = "time"
  time_s2s   = data&time
  time       = data_clm&time

  date_s2s   = cd_calendar(time_s2s, 0)
  date       = cd_calendar(time, 0)
  ; print(date_s2s)
  mon_s2s    = date_s2s(0,1)

  seasname   = name_season(mon_s2s)

  if (isatt(opt, "season")) then
    iseason    = choose_season(seasname, date)
    data_back  = data_clm(iseason,:,:)
  else
    data_back  = data_clm
  end if


  opt_back   = False
  spec_back  = SpaceTime_Background(data_back, diro, case, var             \
              ,latN, cpd, nDayWin, nDaySkip, opt_back  )
  ;
  ; opt@Fig_3a      = log10(/1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8 /)
  ; opt@Fig_3b      = log10(/1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8 /) ; unequal
  ; opt@pltColorMap = "WhiteBlueGreenYellowRed"
  wkSpaceTime_Seas (data, spec_back,  diro, case, var             \
                ,latN, cpd, nDayWin, nDaySkip, opt  )
end

;#############################################################################
;#############################################################################
;######################      CROSS-SPECTRUM        ###########################
;#############################################################################
;#############################################################################
;#############################################################################

undef("cross_spectrum")
function cross_spectrum(X[*][*][*]:numeric, Y[*][*][*]:numeric \
                   ,segLen[1]:integer , segOverLap[1]:integer \
                   ,opt:logical)

local nMsgX, nMsgY, dimX, dimY, ntim, nlat, mlon, switc    \
    , x, y, pct, STC, stc, namStc, kseg, freq, wave        \
    , ntStrt, ntLast
begin
                                      ; error check
  dimX = dimsizes(X)
  dimY = dimsizes(Y)
  if (.not.all(dimX.eq.dimY)) then
      print("cross_spectrum: X and Y must be same size")
      print("           dimX="+dimX+"   dimY="+dimY)
      exit
  end if

  nMsgX = num( ismissing(X) )
  nMsgY = num( ismissing(Y) )
 ;if ((nMsgX+nMsgY).gt.0) then  ; checked in builin function
 ;    print("mjo_cross: currently, missing data not allowed: nMsgX="+nMsgX+"  nMsgY="+nMsgY)
 ;    exit
 ;end if

  ntim = dimX(0)                       ; total times
  nlat = dimX(1)
  mlon = dimX(2)

  x    = X                             ; local copy (time,lat,lon)
  y    = Y
  ;
  x    = decompose2SymAsym( x, 0)      ; decompose
  y    = decompose2SymAsym( y, 0)
                                       ; x may change
  if (isatt(x,"_FillValue")) then
      delete(x@_FillValue)             ; avoid annoying warning msg
  end if                               ; from dtrend
  if (isatt(y,"_FillValue")) then
      delete(y@_FillValue)
  end if

  x       = dtrend_leftdim(x, False )  ; detrend overall series in time
  y       = dtrend_leftdim(y, False )

  if (opt .and. isatt(opt,"taper_seg") ) then
      pct = opt@taper_seg   ; over-ride default
  else
      pct = 0.10            ; default; taper 10% of series
  end if

  x       = taper_leftdim(x, pct, 0 )  ; taper in time
  y       = taper_leftdim(y, pct, 0 )

; -------------------------------------------------------------------


  STC    = new ( (/16,segLen/2+1,mlon+1/), "double", 1d20)
  STC    = 0.0

  kseg   = 0
  ntStrt = 0
  switch = True
  do while (switch)
     ntLast = ntStrt + segLen-1
     if (ntLast.gt.(ntim-1)) then
         switch = False
         break
     end if

     XX     = taper_leftdim( x(ntStrt:ntLast,:,:), pct, 0)
     YY     = taper_leftdim( y(ntStrt:ntLast,:,:), pct, 0)

     kseg   = kseg+1
     STC    = STC + mjo_cross_segment(XX,YY,0)

     ntStrt = ntStrt + abs(segOverLap)
  end do

  STC    = STC/kseg                          ; average

                                            ; use averaged power
  mjo_cross_coh2pha(STC, 0)                 ; to get coh2 / phase

  freq   = fspan(0,0.5,segLen/2+1)
  freq@long_term = " frq (cycles per day)"   ; for plot
  freq@units     = "cycles per day"
  freq!0 = "freq"
  wave   = fspan(-mlon/2,mlon/2,mlon+1)
  wave@long_term = "zonal wavenumber"
  wave@units     = "zonal wavenumber"
  wave!0 = "wave"

  STC!0  = "var"
  STC!1  = "freq"
  STC!2  = "wave"
  STC&freq = freq
  STC&wave = wave

  STC@varName  = (/"PEE1_SYM"   , "PEE1_ASY"    \
                  ,"PEE2_SYM"   , "PEE2_ASY"    \
                  ,"P12_SYM"    , "P12_ASY"     \
                  ,"Q12_SYM"    , "Q12_ASY"     \
                  ,"COH2_SYM"   , "COH2_ASY"    \
                  ,"PHAS_SYM"   , "PHAS_ASY"    \
                  ,"V1_SYM"     , "V1_ASY"      \
                  ,"V2_SYM"     , "V2_ASY"      /)

  STC@segmentLength  = segLen
  STC@segmentOverLap = segOverLap
  STC@segmentRepeat  = segLen-segOverLap
  STC@number_of_segments = kseg
  STC@dof            = 2.667*kseg     ; conservative estimate
                                      ; 2.667 is for 1-2-1 smoother

  p = (/0.80, 0.85, 0.90, 0.925, 0.95, 0.99/); probability levels
  STC@prob       = p
  STC@prob_coh2  = 1.-(1.-p^(0.5*STC@dof -1))

  return( STC )
end


undef("coh2pha")
  function coh2pha(stc[*][*][*]:numeric, mode:string, opt:logical)
local cspc_xy,qspc_xy,spc_x,spc_y

begin

if mode.eq."symmetric" then
  cspc_xy  = stc(4,:,:)
  qspc_xy  = stc(6,:,:)
  spc_x    = stc(0,:,:)
  spc_y    = stc(2,:,:)
else if mode.eq."asymmetric" then
  cspc_xy  = stc(5,:,:)
  qspc_xy  = stc(7,:,:)
  spc_x    = stc(1,:,:)
  spc_y    = stc(3,:,:)
else
  print("ERROR! 'mode' has to be 'symmetric' or 'asymmetric' ")
end if
end if

if (opt) then
    print("1-2-1 smoothing applied before coherence...")
    wk_smooth121(cspc_xy(wave|:, freq|:))
    wk_smooth121(qspc_xy(wave|:, freq|:))
    wk_smooth121(spc_x(wave|:, freq|:))
    wk_smooth121(spc_y(wave|:, freq|:))
else
    print("NO smoothing applied before coherence...")
end if


    nwave  = dimsizes(cspc_xy&wave)
    printVarSummary(qspc_xy)
    coh2   = (cspc_xy^2 + qspc_xy^2)/(spc_x * spc_y)
    pha    = atan2(qspc_xy,cspc_xy)

    copy_VarMeta(cspc_xy, coh2)
    v1_pha = qspc_xy

    printVarSummary( qspc_xy(wave|nwave/2:nwave-1, freq|:))
    printVarSummary(v1_pha(wave|nwave/2:nwave-1, freq|:))
    v1_pha(wave|nwave/2:nwave-1, freq|:) = qspc_xy(wave|nwave/2:nwave-1, freq|:)/sqrt(qspc_xy(wave|nwave/2:nwave-1,freq|:)^2 + cspc_xy(wave|nwave/2:nwave-1, freq|:)^2)
    v1_pha(wave|0:nwave/2-1, freq|:) = -qspc_xy(wave|0:nwave/2-1,freq|:)/sqrt(qspc_xy(wave|0:nwave/2-1, freq|:)^2 + cspc_xy(wave|0:nwave/2-1,  freq|:)^2)
    v2_pha = cspc_xy/sqrt(qspc_xy^2+cspc_xy^2)

copy_VarMeta(cspc_xy, pha)
copy_VarMeta(cspc_xy, v1_pha)
copy_VarMeta(cspc_xy, v2_pha)

if mode.eq."symmetric" then
    stc(8,:,:)  = coh2(freq|:, wave|:)
    stc(10,:,:) = pha(freq|:, wave|:)
    stc(12,:,:) = v1_pha(freq|:, wave|:)
    stc(14,:,:) = v2_pha(freq|:, wave|:)
else if mode.eq."asymmetric" then
    stc(9,:,:)  = coh2(freq|:, wave|:)
    stc(11,:,:) = pha(freq|:, wave|:)
    stc(13,:,:) = v1_pha(freq|:, wave|:)
    stc(15,:,:) = v2_pha(freq|:, wave|:)
end if
end if

return(stc)

end


undef("cross_spectrum_segment")
function cross_spectrum_segment(X[*][*][*]:numeric, Y[*][*][*]:numeric \
                   ,segLen[1]:integer , segOverLap[1]:integer \
                   ,opt:logical)

local nMsgX, nMsgY, dimX, dimY, ntim, nlat, mlon, switc    \
    , x, y, pct, STC, stc, namStc, kseg, freq, wave        \
    , ntStrt, ntLast
begin
                                      ; error check
  dimX = dimsizes(X)
  dimY = dimsizes(Y)
  if (.not.all(dimX.eq.dimY)) then
      print("cross_spectrum: X and Y must be same size")
      print("           dimX="+dimX+"   dimY="+dimY)
      exit
  end if

  nMsgX = num( ismissing(X) )
  nMsgY = num( ismissing(Y) )
 ;if ((nMsgX+nMsgY).gt.0) then  ; checked in builin function
 ;    print("mjo_cross: currently, missing data not allowed: nMsgX="+nMsgX+"  nMsgY="+nMsgY)
 ;    exit
 ;end if

  ntim = dimX(0)                       ; total times
  nlat = dimX(1)
  mlon = dimX(2)

  x    = X                             ; local copy (time,lat,lon)
  y    = Y
  ;
  x    = decompose2SymAsym( x, 0)      ; decompose
  y    = decompose2SymAsym( y, 0)
                                       ; x may change
  if (isatt(x,"_FillValue")) then
      delete(x@_FillValue)             ; avoid annoying warning msg
  end if                               ; from dtrend
  if (isatt(y,"_FillValue")) then
      delete(y@_FillValue)
  end if

  x       = dtrend_leftdim(x, False )  ; detrend overall series in time
  y       = dtrend_leftdim(y, False )

  if (opt .and. isatt(opt,"taper_seg") ) then
      pct = opt@taper_seg   ; over-ride default
  else
      pct = 0.10            ; default; taper 10% of series
  end if

  x       = taper_leftdim(x, pct, 0 )  ; taper in time
  y       = taper_leftdim(y, pct, 0 )

; -------------------------------------------------------------------


  STC    = new ( (/16,segLen/2+1,mlon+1/), "double", 1d20)
  STC    = 0.0

  kseg   = 0
  ntStrt = 0
  switch = True
  do while (switch)
     ntLast = ntStrt + segLen-1
     if (ntLast.gt.(ntim-1)) then
         switch = False
         break
     end if

     XX     = taper_leftdim( x(ntStrt:ntLast,:,:), pct, 0)
     YY     = taper_leftdim( y(ntStrt:ntLast,:,:), pct, 0)

     kseg   = kseg+1
     STC    = STC + mjo_cross_segment(XX,YY,0)

     ntStrt = ntStrt + abs(segOverLap)
  end do
  printVarSummary(STC)

  freq   = fspan(0,0.5,segLen/2+1)
  freq@long_term = " frq (cycles per day)"   ; for plot
  freq@units     = "cycles per day"
  freq!0 = "freq"
  wave   = fspan(-mlon/2,mlon/2,mlon+1)
  wave@long_term = "zonal wavenumber"
  wave@units     = "zonal wavenumber"
  wave!0 = "wave"

  STC!0  = "var"
  STC!1  = "freq"
  STC!2  = "wave"
  STC&freq = freq
  STC&wave = wave

  STC@varName  = (/"PEE1_SYM"   , "PEE1_ASY"    \
                  ,"PEE2_SYM"   , "PEE2_ASY"    \
                  ,"P12_SYM"    , "P12_ASY"     \
                  ,"Q12_SYM"    , "Q12_ASY"     \
                  ,"COH2_SYM"   , "COH2_ASY"    \
                  ,"PHAS_SYM"   , "PHAS_ASY"    \
                  ,"V1_SYM"     , "V1_ASY"      \
                  ,"V2_SYM"     , "V2_ASY"      /)

  STC@segmentLength  = segLen
  STC@segmentOverLap = segOverLap
  STC@segmentRepeat  = segLen-segOverLap
  STC@number_of_segments = kseg
  STC@dof            = 2.667*kseg     ; conservative estimate
                                      ; 2.667 is for 1-2-1 smoother

  p = (/0.80, 0.85, 0.90, 0.925, 0.95, 0.99/); probability levels
  STC@prob       = p
  STC@prob_coh2  = 1.-(1.-p^(0.5*STC@dof -1))

  return( STC )
end
; undef ("observation_padding_taper")
; function observation_padding_taper(\
;   data[*][*][*]      : numeric,\
;   pad[*][*][*]       : numeric,\
;   ind_init           : integer,\
;   npad               : integer,\
;   days_to_taper      : integer \
; )
;
; local time, date, time_add, ndims, ntim,nlat,nlon
; begin
;
;   data!0 = "time"
;   time  = data&time
;   date  = cd_calendar(time,-2)
;
;   time_add = new((/dimsizes(date)+npad/), typeof(time))
;
;   do d = 0, npad-1
;     ; print(time(d))
;     time_add(d) = time(0) - npad + d
;   end do
;
;   time_add(npad:) = time
;   ; print(cd_calendar(time_add,-2))
;
;   ndims = dimsizes(data)
;   ntim  = ndims(0)
;   nlat  = ndims(1)
;   nlon  = ndims(2)
;
;   x = new((/ntim+npad, nlat, nlon/), float)
;
;   ; printVarSummary(pad((ind_init - npad):(ind_init-npad+days_to_taper)-1, :, :))
;
;   tapered = data_taper_n(pad((ind_init - npad):(ind_init-npad+days_to_taper+1), :, :), 0, days_to_taper )
;   ; printVarSummary(tapered)
;   x(0:days_to_taper-1,:,:) = tapered(0:days_to_taper-1,:,:)
;
;   printVarSummary(pad(ind_init-days_to_taper:ind_init-1,:,:))
;   printVarSummary(x(days_to_taper:npad-1, :, :))
;   x(days_to_taper:npad-1, :, :) = pad((ind_init-days_to_taper):ind_init-1,:,:)
;   x(npad:,:,:)    = data
;
;   x!0 = "time"
;   x!1 = "lat"
;   x!2 = "lon"
;
;   x&time = time_add
;   x&lat  = data&lat
;   x&lon  = data&lon
;
;   return(x)
; end
;
; undef ("observation_padding_taper")
; function observation_padding_taper(\
;   data[*][*][*]      : numeric,\
;   pad[*][*][*]       : numeric,\
;   ind_init           : integer,\
;   npad               : integer,\
;   days_to_taper      : integer \
; )
;
; local time, date, time_add, ndims, ntim,nlat,nlon
; begin
;
;   data!0 = "time"
;   time  = data&time
;   date  = cd_calendar(time,-2)
;
;   time_add = new((/dimsizes(date)+npad/), typeof(time))
;
;   do d = 0, npad-1
;     ; print(time(d))
;     time_add(d) = time(0) - npad + d
;   end do
;
;   time_add(npad:) = time
;   ; print(cd_calendar(time_add,-2))
;
;   ndims = dimsizes(data)
;   ntim  = ndims(0)
;   nlat  = ndims(1)
;   nlon  = ndims(2)
;
;   x = new((/ntim+npad, nlat, nlon/), float)
;
;   ; printVarSummary(pad((ind_init - npad):(ind_init-npad+days_to_taper)-1, :, :))
;
;   tapered = data_taper_n(pad((ind_init - npad):(ind_init-1), :, :), 0, days_to_taper )
;   printVarSummary(tapered)
;   ; x(0:days_to_taper-1,:,:) = tapered(0:days_to_taper-1,:,:)
;   ; printVarSummary(x(0:npad-1, :, :))
;   x(0:npad-1, :, :) = tapered(:,:,:)
;   x(npad:,:,:)    = data
;
;   x!0 = "time"
;   x!1 = "lat"
;   x!2 = "lon"
;
;   x&time = time_add
;   x&lat  = data&lat
;   x&lon  = data&lon
;
;   return(x)
; end
