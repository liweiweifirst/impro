;+
; NAME:
;   WRITE_ISEDFIT_PARAMFILE()
;
; PURPOSE:
;   Build the global parameter file for iSEDfit.
;
; INPUTS: 
;   isedfit_dir - full path specifying where all the I/O iSEDfit files
;     should be written, including this parameter file (default
;     PWD=present working directory)   
;   prefix - prefix to assign to output files generated by iSEDfit,
;     including this parameter file (e.g., 'mysample')
;   filterlist - string array list of filters (K-correct compatible
;     .par files) [NFILT]
;
;   zminmax - two-element array specifying the minimum and maximum
;     redshift range to consider in the calculations; ZMINMAX should
;     span the range of redshifts of the sample, as the code will not
;     extrapolate
;   nzz - number of redshifts in the range (ZMINMAX[0],ZMINMAX[1]);
;     this parameter controls the redshift resolution at which the
;     filters are convolved with the models; it should not be too
;     small nor too large (20-50 are good numbers, depending on
;     ZMINMAX) 
;   zlog - set this keyword to distribute redshifts logarithmically in
;     the range (ZMINMAX[0],ZMINMAX[1]) [0=no, 1=yes] (default 0;
;     ignored if USE_REDSHIFT is used) 
;   use_redshift - in lieu of MINZ,MAXZ,NZZ, the user can instead pass
;     the desired model redshift array directly using this parameter;
;     this is useful if there are a small number of objects in the
;     sample spanning a wide range of redshifts (see COMMENTS!); note
;     that this parameter takes precedence over MINZ,MAXZ,NZZ
;
; OPTIONAL INPUTS: 
;   h100 - Hubble constant relative to 100 km/s/Mpc (default 0.7)
;   omega0 - matter density (default 0.3)
;   omegal - vacuum energy density (default 0.7)
;
;   spsmodels - stellar population synthesis models to use (default
;     'fsps_v2.4_miles'); see the documentation for an up-to-date list
;     of available models
;   imf - initial mass function to adopt (default 'chab'=Chabrier);
;     which IMF is available depends on which SPSMODELS are adopted;
;     see the documentation for an up-to-date list of available IMFs
;   redcurve - reddening curve (default 'charlot'=Charlot & Fall); see
;     the documentation for an up-to-date list of available
;     reddening/attenuation curves  
;   igm - include IGM attenuation? [0=no, 1=yes] (default 1); 
;
;   sfhgrid - unique star formation history (SFHgrid) number (default 1)
;   nmodel - number of Monte Carlo realizations of the model
;     parameters (default 10,000)
;   ndraw - random number of random points to draw from the posterior
;     (default 2000)
;   nminphot - require at least NMINPHOT bandpasses with well-measured
;     photometry (i.e., excluding upper limits) in order to fit
;     (default 3)
;   galchunksize - split the sample into GALCHUNKSIZE sized chunks,
;     which is necessary if the sample is very large (default 5000) 
;
;   age - minimum and maximum galaxy age (default [0.1,13]) [Gyr] 
;   tau - minimum and maximum tau value (default [0.01,1.0]) [Gyr or
;     Gyr^-1 if /ONEOVERTAU]
;   Zmetal - minimum and maximum stellar metallicity (default
;     [0.004,0.04]) 
;   AV - Gamma distribution mean and width (default [0.35,2.0]) or
;     minimum and maximum V-band extinction/attenuation if /FLATAV
;     [mag] 
;   mu - 
; 
;   pburst - 
;   interval_pburst - 
;   tburst - 
;   fburst - 
;   dtburst - 
;   trunctau - 
;   fractrunc - 
; 
;   oiiihb - if /NEBULAR then include draw the [OIII]/H-beta emission
;     line ratios from a uniform distribution
;  
;   bursttype - 
;
; KEYWORD PARAMETERS:
;   nebular - include nebular emission lines
;   oneovertau - 
;   delayed - 
;   flatAV - 
;   flatmu - 
;   flatfburst - 
;   flatdtburst - 
;   append - append a new set of parameters to an existing parameter file
;   help - print the documentation to STDOUT
;   clobber - overwrite an existing parameter file
; 
; OUTPUTS: 
;   This code writes a parameter file called
;   ISEDFIT_DIR+PREFIX+'_PARAMETER.PAR' and will also optionally
;   return the PARAMS structure.  
; 
; COMMENTS:
;   Note that USE_REDSHIFT *must* be monotonic (increasing or
;   decreasing), otherwise the interpolations fail. 
;
;   If /APPEND then neither the number of elements in the redshift
;   array nor the number of filters can change, otherwise the
;   structures can't be stacked.
;
; MODIFICATION HISTORY:
;   J. Moustakas, 2012 Sep 19, Siena
;   jm13aug05siena - major update and rewrite; all parameters
;     controlling iSEDfit are now specified here
;
; Copyright (C) 2012-2013, John Moustakas
; 
; This program is free software; you can redistribute it and/or modify 
; it under the terms of the GNU General Public License as published by 
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. 
; 
; This program is distributed in the hope that it will be useful, but 
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details. 
;-

function init_paramfile, filterlist=filterlist, prefix=prefix, $
  redshift=redshift
; populate the iSEDfit parameter file with defaults; note that all the
; integers have to be type LONG to avoid issues with the Yanny
; parameter files 

    params = {$
; preliminaries
      prefix:        prefix,$
      h100:             0.7,$
      omega0:           0.3,$
      omegal:           0.7,$
; SPS details
      spsmodels: 'fsps_v2.4_miles',$
      imf:           'chab',$
      redcurve:  'calzetti',$
      igm:               1L,$ ; include IGM attenuation? [1=yes, 0=no]
; number of Monte Carlo models
      sfhgrid:          -1L,$
      nmodel:        10000L,$
      ndraw:          2000L,$
      nminphot:          3L,$
      galchunksize:   5000L,$
; model grid parameters; basic SFH priors
      age:       [0.1,13.0],$ ; range of model ages [Gyr]
      tau:       [0.01,1.0],$ ; [Gyr] or [Gyr^-1] if /ONEOVERTAU
      Zmetal:  [0.004,0.04],$ ; metallicity
      AV:        [0.35,2.0],$ ; Gamma-distribution parameters
      mu:           [0.1,4],$ ; Gamma-distribution parameters
; burst priors
      pburst:           0.0,$ ; burst probability 
      interval_pburst:  2.0,$ ; [Gyr]
      tburst:    [0.1,13.0],$ ; range of burst times [Gyr]
      fburst:    [0.03,4.0],$ ; range of burst mass fraction
      dtburst:   [0.03,0.3],$ ; range of burst width [Gyr]
      trunctau: [-1.0,-1.0],$ ; range of truncation timescale [Gyr]
      fractrunc:        0.0,$ ; fraction of models with truncated SFHs
; emission-line priors
      oiiihb:    [-1.0,1.0],$ ; flat distribution
; additional options      
      nebular:           0L,$ ; no emission lines by default
      oneovertau:        0L,$ ; uniform in tau (not 1/tau) by default
      delayed:           0L,$ ; simple tau by default
      flatAV:            0L,$ ; Gamma distribution by default
      flatmu:            0L,$ ; Gamma distribution by default
      flatfburst:        0L,$ ; log-distributed by default
      flatdtburst:       0L,$ ; log-distributed by default
      bursttype:         1L,$ ; Gaussian burst default
; sample-specific parameters
      use_redshift:      0L,$ ; custom redshift? (for plots)
      zlog:              0L,$ ; zlog? (for plots)
      redshift:    redshift,$
      filterlist: filterlist}
return, params
end    

pro write_isedfit_paramfile, params=params, isedfit_dir=isedfit_dir, prefix=prefix, $
  filterlist=filterlist, zminmax=zminmax, nzz=nzz, zlog=zlog, use_redshift=use_redshift, $
  h100=h100, omega0=omega0, omegal=omegal, spsmodels=spsmodels, imf=imf, redcurve=redcurve, $
  igm=igm, sfhgrid=sfhgrid, nmodel=nmodel, ndraw=ndraw, nminphot=nminphot, galchunksize=galchunksize, $
  age=age, tau=tau, Zmetal=Zmetal, AV=AV, mu=mu, pburst=pburst, interval_pburst=interval_pburst, $
  tburst=tburst, fburst=fburst, dtburst=dtburst, trunctau=trunctau, fractrunc=fractrunc, $
  oiiihb=oiiihb, nebular=nebular, oneovertau=oneovertau, delayed=delayed, $
  flatAV=flatAV, flatmu=flatmu, flatfburst=flatfburst, flatdtburst=flatdtburst, $
  bursttype=bursttype, append=append, help=help, clobber=clobber

    if keyword_set(help) then begin
       doc_library, 'write_isedfit_paramfile'
       return
    endif
    
; check for the required parameters
    if n_elements(prefix) eq 0 then begin
       splog, 'PREFIX must be specified'
       return
    endif

    if n_elements(isedfit_dir) eq 0 then isedfit_dir = get_pwd()
    isedfit_paramfile = isedfit_dir+'/'+prefix+'_paramfile.par'

    if n_elements(filterlist) eq 0 then begin
       splog, 'FILTERLIST must be specified'
       return
    endif

; build the redshift array    
    nzz_user = n_elements(use_redshift)
    if nzz_user eq 0 then begin
       if n_elements(zminmax) eq 0 or n_elements(nzz) eq 0 then begin
          splog, 'Redshift parameters ZMINMAX and NZZ must be specified!' 
          return
       endif else begin
          if nzz le 0 then message, 'NZZ must be greater than zero!'
          if n_elements(zminmax) ne 2 then message, 'ZMINMAX must be a 2-element array!'
          if im_double(zminmax[0]) gt im_double(zminmax[1]) then $
            message, 'MINZ must be less than MAXZ!'
          if im_double(zminmax[0]) eq im_double(zminmax[1]) then $
            redshift = zminmax[0] else $
              redshift = range(zminmax[0],zminmax[1],nzz,log=keyword_set(zlog))
       endelse
    endif else begin
       redshift = use_redshift
    endelse
    
; initialize the parameter structure    
    params = init_paramfile(filterlist=filterlist,prefix=prefix,$
      redshift=redshift)
    params.use_redshift = nzz_user gt 0
    params.zlog = keyword_set(zlog)

; --------------------
; cosmology    
    if n_elements(h100) ne 0 then params.h100 = h100
    if n_elements(omega0) ne 0 then params.omega0 = omega0
    if n_elements(omegal) ne 0 then params.omegal = omegal

; --------------------
; SPS parameters
    if n_elements(spsmodels) ne 0 then params.spsmodels = spsmodels
    if n_elements(imf) ne 0 then params.imf = imf
    if n_elements(redcurve) ne 0 then params.redcurve = strlowcase(strtrim(redcurve,2))
    if n_elements(igm) ne 0 then params.igm = keyword_set(igm)
    case params.redcurve of
       'none': 
       'calzetti': 
       'charlot': 
       'odonnell': 
       'smc': 
       else: message, 'Reddening curve '+params.redcurve+' not currently supported!'
    endcase

; --------------------
; SFH priors
    if n_elements(nmodel) ne 0 then params.nmodel = nmodel
    if n_elements(ndraw) ne 0 then params.ndraw = ndraw
    if n_elements(nminphot) ne 0 then params.nminphot = nminphot
    if n_elements(galchunksize) ne 0 then params.galchunksize = galchunksize

; basic SFH
    if n_elements(age) ne 0 then begin
       if n_elements(age) ne 2 then message, 'AGE must be a 2-element array!'
       params.age = age
    endif
    if n_elements(tau) ne 0 then begin
       if n_elements(tau) ne 2 then message, 'TAU must be a 2-element array!'
       params.tau = tau
    endif
    if n_elements(Zmetal) ne 0 then begin
       if n_elements(Zmetal) ne 2 then message, 'Zmetal must be a 2-element array!'
       params.Zmetal = Zmetal
    endif
    if n_elements(AV) ne 0 then begin
       if n_elements(AV) ne 2 then message, 'AV must be a 2-element array!'
       params.AV = AV
    endif
    if n_elements(mu) ne 0 then begin
       if n_elements(mu) ne 2 then message, 'MU must be a 2-element array!'
       params.mu = mu
    endif

; burst parameters    
    if n_elements(pburst) ne 0 then params.pburst = pburst
    if n_elements(interval_pburst) ne 0 then params.interval_pburst = interval_pburst
    if n_elements(tburst) ne 0 then begin
       if n_elements(tburst) ne 2 then message, 'TBURST must be a 2-element array!'
       params.tburst = tburst
    endif else params.tburst = params.age ; note!
    if n_elements(fburst) ne 0 then begin
       if n_elements(fburst) ne 2 then message, 'FBURST must be a 2-element array!'
       params.fburst = fburst
    endif
    if n_elements(dtburst) ne 0 then begin
       if n_elements(dtburst) ne 2 then message, 'DTBURST must be a 2-element array!'
       params.dtburst = dtburst
    endif
    if n_elements(trunctau) ne 0 then begin
       if n_elements(trunctau) ne 2 then message, 'TRUNCTAU must be a 2-element array!'
       params.trunctau = trunctau
    endif
    if n_elements(fractrunc) ne 0 then params.fractrunc = fractrunc

; nebular emission lines    
    params.nebular = keyword_set(nebular)
    if n_elements(oiiihb) ne 0 then begin
       if n_elements(oiiihb) ne 2 then message, 'OIIIHB must be a 2-element array!'
       params.oiiihb = oiiihb
    endif
    
; additional options
    if keyword_set(oneovertau) then begin
       params.oneovertau = 1
       if min(params.tau) le 0 then message, 'When using /ONEOVERTAU, TAU must be greater than zero!'
    endif
    params.delayed = keyword_set(delayed)
    if params.delayed and params.oneovertau then $
      message, 'DELAYED and ONEOVERTAU may not work well together; choose one!'
    params.flatAV = keyword_set(flatAV)
    params.flatmu = keyword_set(flatmu)
    params.flatfburst = keyword_set(flatfburst)
    params.flatdtburst = keyword_set(flatdtburst)
    if n_elements(bursttype) ne 0 then params.bursttype = bursttype

; overwrite or append?  assign unique SFHGRID numbers
    if keyword_set(append) then begin
       if file_test(isedfit_paramfile) eq 0 then begin
          splog, 'Parameter file '+isedfit_paramfile+' does not exist; unable to APPEND.'
          return
       endif
       splog, 'Appending to '+isedfit_paramfile
       params1 = yanny_readone(isedfit_paramfile)
       if n_elements(sfhgrid) eq 0 then params.sfhgrid = max(params1.sfhgrid)+1 else $
         params.sfhgrid = sfhgrid
       params = [params1,params]
    endif else begin
       if n_elements(sfhgrid) eq 0 then params.sfhgrid = 1 else $
         params.sfhgrid = sfhgrid
    endelse

    uu = uniq(params.sfhgrid,sort(params.sfhgrid))
    if n_elements(uu) ne n_elements(params) then message, $
      'SFHGRID numbers must be unique'

    if im_file_test(isedfit_paramfile,clobber=keyword_set(clobber) or $
      keyword_set(append)) then return

; write out
    hdr = ['# iSEDfit parameter file generated by WRITE_ISEDFIT_PARAMFILE on '+im_today()]
    splog, 'Writing '+isedfit_paramfile
    yanny_write, isedfit_paramfile, ptr_new(params), $
      stnames='ISEDFITPARAMS', /align, hdr=hdr

return
end
