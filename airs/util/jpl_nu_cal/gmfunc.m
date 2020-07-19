function [nu] = gmfunc(y_cuton,foc_len,quadm,quadoff,side,order,nchan);

% function [chan] = gmfunc(y_cuton,foc_len,side,order,nchan)
% 
% Input:
%     y_cuton = starting position of array
%     foc_len = AIRS focal length
%     side    = side for this array (1 or 2)
%     order   = grating order for this array
%     nchan   = number of detectors in array
%     quadm   = quadratic correction to centers (only ~1-2% max of width)
%     quadoff = wavenumber offset for quadratic calculation
%
% Output:  A structure with two elements
%   
%   nu      : channel center wavenumber
%
% Created by LLS on March 21, 1999
% 
%   June 17, 2000:   gmfunc now just returns a single array containing
%                    the channel center frequencies (nu).
%  
alpha      = [ 0.55278 0.56423 ];
grat_spac  = 77.560;       
det_wid    = 50;       

y  = [ (y_cuton + det_wid/2):det_wid:(y_cuton + (nchan)*det_wid -det_wid/2) ];
nu = (grat_spac/order)*(sin(atan(y/foc_len)) + sin(alpha(side)));
nu = 10000./nu;
nu = nu + quadm.*(nu - quadoff).^2;

return



