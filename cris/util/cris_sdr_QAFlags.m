function [qa] = cris_sdr_QAFlags(pd,pflag);

% function [qa] = cris_sdr_QAFlags(pd,pflag);
%
% Extract bits from CrIS SDR (SCRIS) QA Flags QF1, QF2, QF3, QF4
% and find indices of FOVs without any flags set.
%
% Input:
%     pd       structure of SCRIS file as read with concatsdr_pd.m
%     pflag    OPTIONAL flag to plot QA fields (default=0=no, 1=yes)
%
% Output:
%     qa       structure of uint8 QA flag bits, as described in the
%              SDR Data Format Control Book
%

% Created: 29 Nov 2011, David C Tobin
% Update: 09 Dec 2011, Scott Hannon - tidy up code format; remove
%    unassigned output argument indGood
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 1
   pflag = 0;
end

% QF1_SCAN_CRISSDR  (1 value per scan line)
qa.Data_Gap = bitget(pd.QF1_SCAN_CRISSDR,1);
qa.Timing_Sequence_Error = bitget(pd.QF1_SCAN_CRISSDR,2);
qa.Lambda_Monitored_Quality = bitget(pd.QF1_SCAN_CRISSDR,3);
qa.Invalid_Instrument_Temperatures = bitget(pd.QF1_SCAN_CRISSDR,4);
qa.Excess_Thermal_Drift = bitget(pd.QF1_SCAN_CRISSDR,5);
qa.Neon_Cal_Flag_Set = bitget(pd.QF1_SCAN_CRISSDR,6);


% QF2_CRISSDR (1 value per band(3), FOV(9), and scan line)
qa.Lunar_Intrusion = bitget(pd.QF2_CRISSDR,1)*2^0 + ...
   bitget(pd.QF2_CRISSDR,2)*2^1;


% QF3_CRISSDR (1 value per band(3), FOV(9), FOR(30) and scan line)
qa.SDR_Quality = bitget(pd.QF3_CRISSDR,1)*2^0 + bitget(pd.QF3_CRISSDR,2)*2^1;
qa.Invalid_Geolocation = bitget(pd.QF3_CRISSDR,3);
qa.Invalid_Radiometric_Calibration = bitget(pd.QF3_CRISSDR,4)*2^0 + ...
   bitget(pd.QF3_CRISSDR,5)*2^1;
qa.Invalid_Spectral_Calibration = bitget(pd.QF3_CRISSDR,6)*2^0 + ...
   bitget(pd.QF3_CRISSDR,7)*2^1;
qa.FCE_Correction_Failed = bitget(pd.QF3_CRISSDR,8);


% QF4_CRISSDR (1 value per band(3), FOV(9), FOR(30) and scan line)
qa.Day_Night = bitget(pd.QF4_CRISSDR,1);
qa.Invalid_RDR_Data = bitget(pd.QF4_CRISSDR,2);
qa.Many_FCE_Detection = bitget(pd.QF4_CRISSDR,3);
qa.Bit_Trim_Failed = bitget(pd.QF4_CRISSDR,4);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if pflag

   figure
   colormap([0 .8 0;1 0 0;1 0 1;0 0 1])
   image([qa.Data_Gap qa.Timing_Sequence_Error qa.Lambda_Monitored_Quality ...
      qa.Invalid_Instrument_Temperatures qa.Excess_Thermal_Drift ...
      qa.Neon_Cal_Flag_Set squeeze(qa.Lunar_Intrusion(1,5,:))])
   set(gca,'XTick',1:7,'XTickLabel',{'Data Gap','Timing Sequence Error',...
      'Lambda Monitored Quality','Invalid Instrument Temperatures',...
      'Excess Thermal Drift','Neon Cal Flag Set','Lunar Intrusion'})
   set(gca,'Pos',[.25 .35 .5 .5]);pos = get(gca,'Pos'); ...
      rotateXLabels(gca,90);set(gca,'Pos',pos)
   colorbar('ver')


   figure
   colormap([0 .8 0;1 0 0;1 0 1])
   subplot(3,3,1);
   image(squeeze(qa.SDR_Quality(1,5,:,:))');...
      title({'SDR Quality','Good/Degraded/Invalid'}) %'
   subplot(3,3,2);
   image(squeeze(qa.Invalid_Geolocation(1,5,:,:))');...
   title({'Invalid Geolocation','False/True'}) %'
   subplot(3,3,3);
   image(squeeze(qa.Invalid_Radiometric_Calibration(1,5,:,:))');...
      title({'Invalid Rad Cal','Good/Degraded/Invalid'}) %'
   subplot(3,3,4);
   image(squeeze(qa.Invalid_Spectral_Calibration(1,5,:,:))');...
      title({'Invalid Spectral Cal','Good/Degraded/Invalid'}) %'
   subplot(3,3,5);
   image(squeeze(qa.FCE_Correction_Failed(1,5,:,:))');...
      title({'FCE Corr Failed','False/True'}) %'
   subplot(3,3,6);
   image(squeeze(qa.Day_Night(1,5,:,:))');title({'Day / Night','0/1'}) %'
   subplot(3,3,7);
   image(squeeze(qa.Invalid_RDR_Data(1,5,:,:))');...
      title({'Invalid RDR Data','False/True'}) %'
   subplot(3,3,8);
   image(squeeze(qa.Many_FCE_Detection(1,5,:,:))');...
      title({'Many FCEs Detected','False/True'}) %'
   pos = get(gca,'Pos');h=colorbar('hor');set(gca,'Pos',pos);...
      pos = get(h,'Pos');set(h,'Pos',[pos(1) pos(2)-.1 pos(3:4)])
   subplot(3,3,9);
   image(squeeze(qa.Bit_Trim_Failed(1,5,:,:))');...
      title({'Bit Trim Failed','False/True'}) %'
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% end of function %%%
