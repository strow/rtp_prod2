% Convert ECMWF grib to netcdf

% Assume grib commands are in /usr/local/bin
% Only does 1 directory for now
% Rough speed is 4 days/hour (100 days/day)
% Probably should code to skip file creation is files exist
% L. Strow: June 2, 2013

% To run on maya, instead of /usr/local/bin as the path for the ECMWF
% grib utilities, use /asl/opt/strow/bin.  These utilities were compiled
% on maya, I don't know if they will run on tara.

cd  /asl/data/ecmwf/2014/12
a = dir('UAD*');

tic;
for i=1:length(a)
   % This removes UAD*-1*, UAD*-2*, UAD*-d* files
   if length(a(i).name) == 20

      % Surface part      
      name_out1 = [a(i).name '-1'];
      nc_name_out1 = [a(i).name '-1.nc'];
      % Layer part
      name_out2 = [a(i).name '-2'];
      nc_name_out2 = [a(i).name '-2.nc'];
      % No sure what this is, save anyway, small
      name_out3 = [a(i).name '-d'];
      nc_name_out3 = [a(i).name '-d.nc'];

      if ~exist(nc_name_out1)
         evalstr = ['status = unix(''/asl/opt/strow/bin/grib_copy -w typeOfLevel=surface ' a(i).name ' '  name_out1 ''')']
         eval(evalstr)
         evalstr = ['status = unix(''/asl/opt/strow/bin/grib_to_netcdf -o ' nc_name_out1 ' '  name_out1 ''')']
         eval(evalstr)
         delete(name_out1);
      end
      
      if ~exist(nc_name_out2)
         evalstr = ['status = unix(''/asl/opt/strow/bin/grib_copy -w typeOfLevel=hybrid ' a(i).name ' '  name_out2 ''')']
         eval(evalstr)
         evalstr = ['status = unix(''/asl/opt/strow/bin/grib_to_netcdf -o ' nc_name_out2 ' '  name_out2 ''')']
         eval(evalstr)
         delete(name_out2);
      end

      if ~exist(nc_name_out3)
         evalstr = ['status = unix(''/asl/opt/strow/bin/grib_copy -w typeOfLevel=depthBelowLandLayer ' a(i).name ' '  name_out3 ''')']
         eval(evalstr)
         evalstr = ['status = unix(''/asl/opt/strow/bin/grib_to_netcdf -o ' nc_name_out3 ' '  name_out3 ''')']
         eval(evalstr)
         delete(name_out3)
      end
   
   end
end
toc
