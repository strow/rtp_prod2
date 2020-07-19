function [f_lm,freq,m_lm,module] = gmodel(temp,yoff,abside);
% function [f_lm,freq,m_lm,module,w_lm,width] = gmodel(temp,yoff,abside);

% function [f_lm,freq,m_lm,module,w_lm,width] = gmodelall4(temp,yoff,abside);
%
% Calculate the AIRS channel center wavenumbers using the "Opt" (A+B)
% grating model of 5 May 2000, or optionally the temperature averaged
% "A" or "B" grating models of 5 August 2009.
%
% Inputs:
%    temp = [1 x 1] Grating spectrometer temperature {K} (eg 155.1325)
%    yoff = [1 x 1] or [17 x 1] Focal plane Y offset {um} (eg -13.5)
%    abside = OPTIONAL [string] "A" or "B".  If not included in call,
%       then use the old Opt grating model.
%
% Outputs:
%    f_lm   = [2378 x 1] frequency using Lockheed Martin ordering {cm^-1}
%    freq   = [2378 x 1] frequency using PGE ordering {cm^-1}
%    m_lm   = [2378 x 1] cell array module name using Lockheed Martin ordering
%    module = [2378 x 1] cell array module names using PGE ordering
%    w_lm   = [2378 x 1] width using Lockheed Martin ordering {cm^-1}
%    width  = [2378 x 1] width using PGE ordering {cm^-1}
%  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Required files:
%        finalgm.mat:             old OPT grating model parameters
%        finalgm_a_avg.mat:       A-side grating model parameters
%        finalgm_b_avg.mat:       B-side grating model parameters
%        sept99_fm_chanlist.txt:  defines jpl channel ordering
%	  
%
%     UPDATES:
%     Version 1:
%     June 16, 2000: (L. Strow)
%        (1) Fixed 1 point in 2^16 error by UMBC in FFT routine to convert
%            interferograms into SRFs.
%        (2) Widths added for convenience.  They are not needed in
%	     the grating model since they are part of the SRF shape.
%	 (3) We no longer read the text file sept99_fm_chanlist.txt
%            in order to get the sort key for turning Lockheed Martin
%            channel ordering into JPL Level 2 channel ordering.  We
%            now read the file called lmtojplind.mat.
%        (4) Changed the definition of the Lockheed Martin ordering
%            to agree with what others are using, basically reversing
%            the channel numbering for M3 and M6.  We are still a
%            little worried about this since our original ordering
%            is how we read the channel from the ObjectStore files.
%        (5) The structure chan has been replaced with the array nu 
%            (see changes to gmfunc.m for reference)
%
%     Version 2:
%     30 August 2000, Scott Hannon:
%        (6) Add yoff to input; rename input and output variables
%        (7) Shift widths with temperature (nominal at T=155.1325 K)
%
%     Version 3:
%     31 July 2009, L. Strow:
%        (8) Added capability to get A/B state frequencies, based on
%         differences between OPT and A/B measurements.
%     For now called gmodelall3, probably overwrite gmodelall2 with
%     this new function in the near future.  Before doing that we should
%     put M11 and M12 final_gm parameters into finalgm_a and finalgm_b
%     since there is no A/B for M11/M12.  The parameters that appear in
%     finalgm_a and finalgm_b for M11/M12 come from differences in the
%     observed parameters for A vs B tests for the other arrays, so it is a
%     measure of the accuracy/stability of the TVAC grating model
%     measurements.
%
%     Version 4:
%     20 October 2009, Scott Hannon:
%        (9) Use temperature [148, 155, 161 K] averaged ("avg") A and B
%        grating models. Allow [17 x 1] yoff.
%
%     Now called gmodel.m
%        03 Feb. 2016, L. Strow
%        Removed widths from output to save time.
%        Put M5 and M12 launch offsets in here so dont' have to do that
%          in the calling program.
%        Flip yoff here, instead of in the calling program.
%        Still need to work on A/B.
%        MUST include abside when calling.  2378 (values 0 to 6)
%
%     Modification for jpl_nu_cal_package
%        24 Mar. 2019, L. Strow
%        Made all data loaded persistent for speed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%========================== Load Static Data Files ===========================
persistent lmtojplind
if isempty(lmtojplind)
   load lmtojplind
end

persistent gma
if isempty(gma)
   gma = load('finalgm_a_avg');
end

persistent gmb
if isempty(gmb)
   gmb = load('finalgm_b_avg');
end

persistent gmboth
if isempty(gmboth)
   gmboth = load('finalgm');
end

fc = 1:17;
gm = fliplr(fc);

yoff = yoff(gm);

% Standard temperature 
t_std = 155.1325;
delta_t = temp - t_std;

% Temperature dependence of y_cuton's
yoffslope = 2.20813;  % microns/K

% Load smoothed widths
% load widths

% Grating order and side
% module  1a 2a 1b 2b 4a 4b  3 4c 4d  5  6  7  8  9 10 11 12
order  = [11 10 10  9  6  6  6  5  5  4  4  4  4  3  3  3  3];
side   = [ 1  2  1  2  2  2  1  2  2  2  2  1  1  2  2  1  1];

% Array channel ordering using Lockheed-Martin indexing
% Note: M3 and M6 are the revised LM ordering
a = { ...
   '1a'       0     117    2552    2677 ;
   '2a'     248     363    2432    2555 ;
   '1b'     118     247    2309    2434 ;
   '2b'     364     513    2169    2312 ;
   '4a'     706     809    1540    1614 ;
   '4b'     810     915    1460    1527 ;
   '3'      514     705    1337    1443 ;
   '4c'     916    1009    1283    1339 ;
   '4d'    1010    1115    1216    1273 ;
   '5'     1116    1274    1055    1136 ;
   '6'     1275    1441     973    1046 ;
   '7'     1442    1608     910     974 ;
   '8'     1609    1769     851     904 ;
   '9'     1770    1936     788     852 ;
   '10'    1937    2103     727     782 ;
   '11'    2104    2247     687     729 ;
   '12'    2248    2377     649     682 ;
    };

mod_list         = {a{:,1}};
first_chans      = [a{:,2}];
last_chans       = [a{:,3}];
approx_min_freqs = [a{:,4}];
approx_max_freqs = [a{:,5}];

nchans = 1 + abs(last_chans - first_chans)';

% Fix launch offsets, these must be subtracted out in betahat analysis! Check!
yoff(10) = yoff(10) + 3.0;
yoff(17) = yoff(17) - 1.5;

% Declare output arrays
f_lm = zeros(2378,1);
w_lm = zeros(2378,1);
freq = zeros(2378,1);
width= zeros(2378,1);

% Loop through modules
for m=1:17

   y = yoff(m) + gmboth.y_cuton(m) + delta_t*yoffslope;
   nuboth = gmfunc(y, gmboth.focal_length(m), gmboth.quadm(m), gmboth.quadoff(m),side(m), order(m), nchans(m));

   y = yoff(m) + gma.y_cuton(m) + delta_t*yoffslope;
   nua = gmfunc(y, gma.focal_length(m), gma.quadm(m), gma.quadoff(m),side(m), order(m), nchans(m));

   y = yoff(m) + gmb.y_cuton(m) + delta_t*yoffslope;
   nub = gmfunc(y, gmb.focal_length(m), gmb.quadm(m), gmb.quadoff(m),side(m), order(m), nchans(m));
   
   newind = first_chans(m)+1:last_chans(m)+1;

% % Adjust widths for temperature
%    if (abs(delta_t) > 1E-6 | abs(yoff(m)) > 1E-6)
% % Calc standard freqs & widths
%       y_std  = y_cuton(m);
%       nu_std = gmfunc(y_std, focal_length(m), quadm(m), quadoff(m), ...
%                       side(m), order(m), nchans(m));
%       w_std = widthavg(m).w;
%       %
% % Polynomial fit of standard witdhs
%       warning off
%       coef = polyfit(nu_std, w_std, 3);
%       warning on
%       %
% % Calc shifted widths
%       w = polyval(coef,nu);
%    else
%       w = widthavg(m).w;
%    end
   f_lm_both(newind) = nuboth;
   f_lm_a(newind) = nua;
   f_lm_b(newind) = nub;
   m_lm(newind) = mod_list(m);
%    w_lm(newind) = w;
end  


% Sort the Lockheed indexes
[junk,ind]  = sort(lmtojplind);

% load up frequencies in JPL order
freq_both(ind) = f_lm_both;
freq_a(ind) = f_lm_a;
freq_b(ind) = f_lm_b;

% 0 = A+B, 1 = A, 2 = B
abw = mod(abside,3);
freq(abw == 0) = freq_both(abw == 0);
freq(abw == 1) = freq_a(abw == 1);
freq(abw == 2) = freq_b(abw == 2);

% load up widths in JPL order
% width(ind) = w_lm;

% load up Module ID's (M1b, M4d, etc.) in JPL order
module(ind)= m_lm;
m_lm       = m_lm';
module     = module';

return

