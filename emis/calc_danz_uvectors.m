% calc_danz_uvectors
%
% Compute top 10 singular vectors for Dan Zhou's 1-year climatology

% Max number of singular vectors
nv = 10;

% Pre-declare so all 12 months in single arrays
s = zeros(12,nv,nv);
u = zeros(12,8461,nv);

% Data location and names, in *month* order for interpolation
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

for fni = 1:12
   fni
   [emis,e] = read_danz(fullfile(fnh,fn(fni).name));
   % Use land only for best u vectors, Dan says use e.tskin > 50
   gi    = find( e.landflag == 1 & e.tskin > 50);
   emis  = emis(:,gi);
   % Now use this highly variable channel to sort emissivity for subset selection
   [b,i] = sort(emis(1742,:));
   % Do svd on this subset, somewhat arbitrary, more samples where
   % variability is high (lower emissivities)
   bi    = [1:20:10000 10000:100:length(b)];
   emis  = emis(:,bi);
   % Subtract off mean for each month, then mean of these for global
   mean_emis(fni,:) = nanmean(emis,2);
   [~ , nobs] = size(emis);
   for i = 1:nobs
      emis(:,i) = emis(:,i) - mean_emis(fni,:)';
   end
   [u(fni,:,:),s(fni,:,:),v(fni).v]=svds(emis,10);
end

save u_vectors_danz  u s v mean_emis

% The next code was so simple I did by hand, but I should write a 
% code up to do it.
% 
% Re-SVD the set of 12 months by 10 vectors/month u-vectors, keep top 10
% Save in u_vector_global along with 12 month mean of mean_emis