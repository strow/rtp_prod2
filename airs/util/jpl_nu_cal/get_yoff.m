function yoff = get_yoff(mtime);
% Inputs: single time in datetime units
% Output: grating model yoffsets (17,180); 17 arrays, 180 orbit phases

persistent betahat_all_post betahat_all_pre

if isempty(betahat_all_post)
   load betahat_nov2013
end

% Set prenov03 and prejan03 by mtime
prenov03 = false;
prejan03 = false;
if mtime < datetime(2003,10,27)   % fix detailed date
   prenov03 = true;
end   
if mtime < datetime(2003,01,10)   % fix detailed date
   prejan03 = true;
end   

% Switch mtime to datenum
mtime = datenum(mtime);

% Post
toff_fit_post = 731905;
% Pre
toff_fit_pre = 731466;
% All
yoff_fit = -14;
% Pre-allocate output
yoff = zeros(17,180);

% Contains allbetahat yoff_fit toff_fit
yoff_fit = -14;
if prenov03
   x = betahat_all_pre;
else
   x = betahat_all_post;
end

for i=1:17
   if ( prenov03 | prejan03);
      yoff(i,:) = rate_eq4(squeeze(x(i,:,1:6)),mtime - toff_fit_pre) +  yoff_fit;
      if ( i == 10 | i == 13 )
%OK for m4a, trying to see if OK for m4b        yoff(i,:) = yoff(i,:) + 0.02;         
        yoff(i,:) = yoff(i,:) - 0.3;         
      end
   else
      if ( i == 10 | i == 13 )
         yoff(i,:) = rate_eq4(squeeze(x(i,:,1:6)),mtime - toff_fit_post) +  yoff_fit;
      else
         yoff(i,:) = rate_eq2(squeeze(x(i,:,1:9)),mtime - toff_fit_post) +  yoff_fit;
         if mtime > datenum(2010,1,20)
            yoff(i,:) = yoff(i,:) + 0.04;
         end
      end
   end
end

% % Test code for this routine
% k=1;
% for i=1:10:4500
%    t = datetime(2002,09,1) + days(i);
%    yoff(k,:,:) = get_yoff(t);
%    time(k) = t;k = k + 1;
% end
% % Then, for exmple,  plot(time,squeeze(yoff(:,:,1)));
