; Author: Dr. Sandro Lubis (Jan 2020)
;         How to filter CCEW signalsa using kf_filter
;         Lubis, SW, Respati, MR. Impacts of convectively coupled
;         equatorial waves on rainfall extremes in Java, Indonesia.
;         Int J Climatol. 2021; 41: 2418– 2440
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load "/g/data/v46/fm6730/script_access_s2/kf_filter.ncl"

; wave=getenv("wave")
wave="kelvin"
; var = getenv("var")
vars=(/"vr"/)

smooth = True
; var = "adv_q"
folder = "/scratch/v46/fm6730/data/obs/integrated/vorticity/merged/"
folderout = "/scratch/v46/fm6730/dataout/obs/integrated/vorticity/merged/"
;wave = "er"; input variable (mjo, kelvin, er, mrg, eig, td)

; wave = "mjo"
system("mkdir -p "+folderout)
print("Reading the input file...")

; f = addfile(folder + "olr.day.mean.1980-2019.nc", "r")

fname = "vorticity.era.daymean.1979-2020.nc"
print(fname)

f        = addfile(folder+fname, "r")


date = cd_calendar(f->time, -2)
date_start = ind(date.eq.19790101)
date_end = ind(date.eq.20201231)

latN = 30
latS = -latN

time = f->time(date_start:date_end)
lat = f->lat({latS:latN})
lon = f->lon


print("Opening the output file...")

setfileoption("nc","Format","NetCDF4")   ; or "64-bit Offset" if you prefer
setfileoption("nc","CompressionLevel",6)         ; enable compression (0-9)
setfileoption("nc","Shuffle",1)         ; enable shuffle filter to improve compression

foutname = "vorticity."+ wave + "."+latN+"_truth_for_S2S.nc"
system("rm "+folderout+foutname)
g = addfile(folderout+foutname, "c")

do m = 0, dimsizes(vars)-1

	var = vars(m)
	olr = dble2flt(f->$var$(time|date_start:date_end, {lat|latS:latN}, lon|:))

	print("Calculating climatology and anomaly...")

	time = f->time(date_start:date_end)
	TIME = cd_calendar(time, -5)
	year = TIME(:, 0)
	month = TIME(:, 1)
	day = TIME(:, 2)
	ddd = day_of_year(year, month, day)
	yyyyddd = year * 1000 + ddd

	if smooth then
		nhar = 1 ; ONLY CONSIDER ANNUal cycle
		climday     = clmDayTLL(olr, yyyyddd)
		climatology = smthClmDayTLL(climday,nhar)
		anomaly = calcDayAnomTLL(olr, yyyyddd, climatology)
	else
		climatology = clmDayTLL(olr, yyyyddd)
		anomaly = calcDayAnomTLL(olr, yyyyddd, climatology)
	end if

	print("Filtering...")

	filtered = new((/dimsizes(time), dimsizes(lat), dimsizes(lon)/), float, -999)

	filtered!0 = "time"
	filtered!1 = "lat"
	filtered!2 = "lon"

	filtered&time = time
	filtered&lat = lat
	filtered&lon = lon

	filtered@units = olr@units 
	print(filtered@units)

	obsPerDay = 1

	mis = -999
	mis@_FillValue = -999

	wave_type = wave

	if (wave.eq."mjo") then
		wavenumber = (/1, 5/)
		period = (/20, 100/)
		depth = (/mis, mis/)
		filtered@long_name = "Madden-Julian Oscillations in "+var
	else if (wave.eq."kelvin") then
		wavenumber = (/1, 14/)
		period = (/2.5, 17/)
		depth = (/8, 90/)
		filtered@long_name = "Kelvin Waves in "+var
	else if (wave.eq."er") then
		wavenumber = (/-10, -1/)
		period = (/9, 72/)
		depth = (/8, 90/)
		filtered@long_name = "Equatorial Rossby Waves in "+var
	else if (wave.eq."mrg") then
		wavenumber = (/-10, -1/)
		period = (/3, 10/)
		depth = (/8, 90/)
		filtered@long_name = "Mixed Rossby-Gravity Waves in "+var
	else if (wave.eq."eig") then
		wavenumber = (/1, 14/)
		period = (/1, 5/)
		depth = (/12, 50/)
		wave_type = "ig0"
		filtered@long_name = "Eastward Inertio Gravity Waves in "+var
	else if (wave.eq."td") then
		wavenumber = (/-20, -6/)
		; period = (/2.5, 10/)
		period = (/2.5, 5/)
		depth = (/mis, 90/)
		wave_type = "td-type"
		filtered@long_name = "Tropical Depression-Type Waves in "+var
	else if (wave.eq."LF") then
		wavenumber = (/-99, 99/)
		; period = (/2.5, 10/)
		period = (/120, 9999/)
		depth = (/mis, mis/)
		wave_type = "LF"
		filtered@long_name = "Low Frequency Variabilities in "+var
	else if (wave.eq."UF") then 
		filtered@long_name = "Unfiltered "+var

	end if
	end if
	end if
	end if
	end if
	end if
	end if
	end if

	if (wave.ne."UF") then
		do y = 0, (dimsizes(lat) - 1)
			filtered(time|:, lat|y, lon|:) = (/kf_filter(anomaly(time|:, lat|y, lon|:), obsPerDay, period(0), period(1), wavenumber(0), wavenumber(1), depth(0), depth(1), wave_type)/)
			print((/lat(y)/))
		end do
	else
		filtered(time|:, lat|:, lon|:) = anomaly(time|:, lat|:, lon|:)
	end if

	printVarSummary(filtered)
	printMinMax(filtered, False)

	print("Writing the output file...")

	g->$var$ = filtered

	print("Closing the output file...")

	; delete(g)
	delete(filtered)
	delete(olr)
	delete(time)

end do

; delete(g)
; system("sync")
; system("sleep 1")

; system("python /g/data/v46/fm6730/script_access_s2/vorticity/filter_vorticity_budget/compress_filter_s2s.py "+folderout+" "+folderout+" "+foutname+" "+foutname)

