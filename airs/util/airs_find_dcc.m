function [idcc] = airs_find_dcc(head, prof)
%
% Compare brightness temperature computed for test channel
% radiances against DCC threshold. Limit view to obs within
% specified range of equator
%
% canonical test channels: 820.3 cm-1, 960.3, 1231.2
    
   idtestu   = [567; 958; 1520];                % channel IDs for testing
   latmaxdcc = 30;                               % max |rlat| for dcc testing
   btmaxdcc  = 210;                              % max BT (K) for dcc testing
   
   ftest = head.vchan(idtestu);
   rtest = prof.robs1(idtestu,:);
   ibad  = find(rtest < 1E-6);
   rtest(ibad) = NaN;
   btm   = nanmean(real(rad2bt(ftest,rtest)),1);
   clear rtest ftest;
   
   idcc = find(btm <= btmaxdcc & abs(prof.rlat) <= latmaxdcc);

       

