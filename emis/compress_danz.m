% compress_danz.m
%
% Compress DanZ's emissivities (quicker than his approach)
% Run this code after generating global u basis vectors

load ../iasi/iasi_f

% Get global basis u vectors, and 12-month mean offset
<<<<<<< HEAD
load Data/u_vector_global  % u and em
=======
load Data/u_vector_global;  % u and em
>>>>>>> 745bffd9f4821a4a94d4a22981e3b1966e67695e

% Data location and names
fnh = 'DanZ_data';
fn(1).name =  'IASI_FEMI_CLIMATOLOGY_01_2008-2013.bin';
fn(2).name =  'IASI_FEMI_CLIMATOLOGY_02_2008-2013.bin';
fn(3).name =  'IASI_FEMI_CLIMATOLOGY_03_2008-2013.bin';
fn(4).name =  'IASI_FEMI_CLIMATOLOGY_04_2008-2013.bin';
fn(5).name =  'IASI_FEMI_CLIMATOLOGY_05_2008-2013.bin';
fn(6).name =  'IASI_FEMI_CLIMATOLOGY_06_2007-2012.bin';
fn(7).name =  'IASI_FEMI_CLIMATOLOGY_07_2007-2012.bin';
fn(8).name =  'IASI_FEMI_CLIMATOLOGY_08_2007-2012.bin';
fn(9).name =  'IASI_FEMI_CLIMATOLOGY_09_2007-2012.bin';
fn(10).name = 'IASI_FEMI_CLIMATOLOGY_10_2007-2012.bin';
fn(11).name = 'IASI_FEMI_CLIMATOLOGY_11_2007-2012.bin';
fn(12).name = 'IASI_FEMI_CLIMATOLOGY_12_2007-2012.bin';

ci_all = zeros(12,10,259200);

for fni=1:12
   fni
   clear emis
   [emis,e] = read_danz(fullfile(fnh,fn(fni).name));
% Get rid of bad data, a/c to Dan, and I found bad data for landflag >1
   gi = find( e.landflag > 1 | e.tskin <= 50);
% Set bad data locations to emis = 0.98, a reasonable value
   emis(:,gi) = 0.98;
% Subtract off mean and compress into ci_all   
   for i=1:(2*360*2*180);
      emis(:,i) = emis(:,i) - em;
   end
   ci_all(fni,:,:) = u'* emis;
% If want to look at reconstruction accuracy, do the following per month
%    cal_emis = u*ci;
%    % Now add back in mean emissivity
%    for i=1:length(gi)
%       cal_emis(:,i) = cal_emis(:,i)+em;
%    end
%    bias = emis - cal_emis;  % Examine bias
end

% Save a vew extra variables
landflag = e.landflag;
lat = e.lat;
lon = e.lon;
spres = e.spres;

%save ci_all_no_nan ci_all landflag lat lon spres

