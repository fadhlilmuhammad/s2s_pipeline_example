load "/g/data/v46/fm6730/script_access_s2/s2s_utils.ncl"
load "/g/data/v46/fm6730/script_access_s2/wkSpaceTime_mod.ncl"


; e=getenv("ens")
e = e
; var=getenv("var")
; varname = var
; varname=getenv("varname")
; e="e01"
; var="adv_q"
; varname="adv_q"
nint = 277

; e="e01"

print("cleaning up... ")
; system ("rm /g/data/v46/fm6730/data/access_s2/"+varname+"/"+e+"/da_"+var+"_19810101_"+e+"_remap.nc")
; system ("rm /g/data/v46/fm6730/data/access_s2/"+varname+"/"+e+"/da_"+var+"_20181231_"+e+"_remap.nc")
; system ("rm /g/data/v46/fm6730/data/access_s2/"+varname+"/"+e+"/da_"+var+"_20181230_"+e+"_remap.nc")

folder = "/scratch/v46/fm6730/data/access_s2/integrated/vorticity/"+e+"/"

nens   = 3

files = systemfunc("ls "+folder+"*_"+e+"_remap.nc")
f = addfiles(files,"r")
n = dimsizes(files)
; print(files)

print("making files")
; nint   =

vars=(/"vr"/)
; vars=(/"vrD", "fD"/)


print("processing variable "+var)
do i = 0, n-1, 3;dsizes-1
x_all = new((/dimsizes(vars), nens, nint, dimsizes(f[0]->lat), dimsizes(f[0]->lon)/), float, -999.)

do m = 0, dimsizes(vars)-1
  var = vars(m)
  varname = var
  ; print("ke-"+files(i+2))
  x1     = f[i]->$var$(:,:,:)
  x2     = f[i+1]->$var$(:,:,:)
  x3     = f[i+2]->$var$(:,:,:)
  x_all(m,:,:,:,:)      = time_lag_ens_access_s2(x1,x2,x3, toint(nint))
end do 
;;NAMING THE OUTFILE
  nfields = str_fields_count(files(i+2), "/")

  ;print(nfields)
  field = dimsizes(nfields)
  subStrings = str_get_field(files(i+2), 9, "/")
  ;print(subStrings)
  outname = subStrings

  print(outname)
 printVarSummary(x_all)

  dirout = "/scratch/v46/fm6730/data/access_s2/integrated/vorticity/"+e+"_tlag_long/"
  system("mkdir -p "+ dirout)
  filo   = "tlag_"+outname

  setfileoption("nc","Format","NetCDF4Classic")
  system("rm "+dirout+filo)
  print("outputting files....")
  fnc = addfile(dirout+filo, "c")

  do m = 0, dimsizes(vars)-1
    var = vars(m)
    varname = var
  fnc->$var$ = x_all(m,:,:,:,:);(time|:,lat|:,lon|:,time_lag|:)
    
  end do

delete(x1)
delete(x2)
delete(x3)

delete(x_all)
end do

; print("removing unneeded files...")
