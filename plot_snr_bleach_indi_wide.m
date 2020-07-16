
% % in vivo data
%cd('\\engnas.bu.edu\research\eng_research_handata\EricLowet\DMD\invivoDMD\')
%cd('\\engnas.bu.edu\research\eng_research_handata\EricLowet\DMD\comp_wide_indi\')

close all;
clear all;

% Use the scripts in the DMD scripts folder
addpath('.');

% in vitro data
cd('\\engnas.bu.edu\research\eng_research_handata\Pierre Fabris\DMD Project\All In Vitro Analysis\');

ses=dir('*.mat');

%%% search for wide
clear findwide
for id=1:length(ses) 
 if   strfind(ses(id).name, 'Wide')>0
     findwide(id)=1;
 else
      findwide(id)=0;
 end
    
end
wideloc=find(findwide);

% Find corresponding individual field
indiloc = [];
for file=1:length(ses)
    if contains(ses(file).name, 'Individual') == 1
        load([ses(file).name]);
        indi_name = allresults.fov_name;

        for id=1:length(ses)
            if contains(ses(id).name, 'Wide') == 1 & contains(ses(id).name, indi_name) == 1           
                % Sanity check
                load([ses(id).name]);
                if strcmp(allresults.fov_name, indi_name) == 1 & strcmp(allresults.type, 'wide') == 1
                    indiloc = [indiloc, file];
                    ['Individual ' ses(file).name]
                    ['Wide Field ' ses(id).name]
                end
            end
        end
    end
end

%% seelct matching ROI
indiB=[];wideB=[]; indiSNR=[]; wideSNR=[]; indiAllB = []; wideAllB = [];
for id=1:length(wideloc)
    widefile=load(ses(wideloc(id)).name);
    indifile=load(ses(indiloc(id)).name);
    clear wrm % ROI centroid
    for id2= 1:length(widefile.allresults.roi)
        [ x y]=find(widefile.allresults.roi{id2});
        wrm(:,id2)= round(mean([x , y]));end
    clear irm
    for id2= 1:length(indifile.allresults.roi)
        [ x y]=find(indifile.allresults.roi{id2});
        irm(:,id2)= round(mean([x , y]));end  
    mROI=[];
    for id3=1:size(irm,2) % matching ROI
        cents=irm(:,id3);
        pxdiff=(sqrt(sum(bsxfun(@minus, wrm, cents).^2)));
    
      wloc=find(pxdiff<8);
      if ~isempty(wloc)
    mROI=[mROI; [ id3 wloc]];end
    end
    
    %%% Put in matrix%%% average
  indiB= [indiB, nanmean(indifile.allresults.bleach(1,mROI(:,1)), 1) ];
  wideB= [wideB, nanmean(widefile.allresults.bleach(1,mROI(:,1)), 1) ]; % Why is it an index of 1?
  
  % Store all of the bleaching values
  indi_temp = indifile.allresults.bleach(:, mROI(:, 1));
  wide_temp = widefile.allresults.bleach(:, mROI(:, 1));
  
  indiAllB = horzcat_pad(indiAllB, indi_temp(:)');
  wideAllB = horzcat_pad(wideAllB, wide_temp(:)');
  %indiAllB = [indiAllB, indifile.allresults.bleach(1, :)] % Was originally mROI(:, 1)
  %wideAllB = [wideAllB, widefile.allresults.bleach(1, :)]
  
  
  clear allIsnr
  for tr=1:size(  indifile.allresults.spike_snr,2)
      for ne=mROI(:,1)' %1:size(  indifile.allresults.spike_snr,1)
   allIsnr(ne,tr)= mean(indifile.allresults.spike_snr{ne,tr});
      end;end
    clear allWsnr
  for tr=1:size(  widefile.allresults.spike_snr,2)
      for ne= mROI(:,1)' %1:size(  widefile.allresults.spike_snr,1)
   allWsnr(ne,tr)= mean(widefile.allresults.spike_snr{ne,tr});
      end;end
    indiSNR= [indiSNR; nanmean(allIsnr,2) ];
    wideSNR= [wideSNR; nanmean(allWsnr,2) ];
  
end


%% PLOT the bleaching average between DMD and Wide Field
figure('COlor','w'),plot(indiB,'r'); hold on,plot(wideB,'k')
legend indi wide
[h,p,ci,stats] = ttest(indiB,wideB)
figure('COlor','w','Position', [ 300 300 200 200])
V1=((1-nanmean(indiB)).*-1).*100;V1s=(std(indiB)./sqrt(length(indiB))).*100;
V2=((1-nanmean(wideB)).*-1).*100;V2s=(std(wideB)./sqrt(length(wideB))).*100;
bar( [ 1 ], [V1],0.7,'FaceColor', [ 0.7 0.2 0.1]) , hold on,bar( [ 2 ], [V2],0.7,'FaceColor', [0.1 0.4 0.7])
set(gca,'Xtick', [ 1 2],'Xticklabel', {'DMD' ; 'Widefield'})
errorbar([ 1 2], [ V1 V2], [V1s V2s],'.k','Linewidth', 2)
axis tight;ylabel('signal reduction %')
xlim([ 0.5 2.5]); %ylim([0  20])
title([ 'Average of signal decay p= ' num2str(p)])

% Violin plots of photobleaching
figure;
violin(horzcat_pad(indiAllB', wideAllB'), 'xlabel', {'DMD', 'Wide Field'}, 'facecolor', [138/255 175/255 201/255]);
ylim([.50 1.10]);
title(['Photobleaching ratios of individual DMD and wide field']);

%figure;
%violin([ -100.*[repmat(1, length(indiAllB), 1) - indiAllB'], -100.*[ repmat(1, length(wideAllB), 1) - wideAllB']], ...
%    'xlabel', {'DMD', 'Wide Field'}, 'facecolor', [138/255 175/255 201/255]);
%title(['Photobleaching decay of individual DMD and wide field']);


% Plot the SNRs
figure('COlor','w'),,plot(indiSNR,'r'); hold on,plot(wideSNR,'k')
legend indi wide
[h,p,ci,stats] = ttest(indiSNR,wideSNR)
figure('COlor','w','Position', [ 300 300 200 200])
V1=nanmean(indiSNR);V1s=std(indiSNR)./sqrt(length(indiSNR));
V2=nanmean(wideSNR);V2s=std(wideSNR)./sqrt(length(indiSNR));
bar( [ 1 ], [V1],0.7,'FaceColor', [ 0.7 0.2 0.1]) , hold on,bar( [ 2 ], [V2],0.7,'FaceColor', [0.1 0.4 0.7])
set(gca,'Xtick', [ 1 2],'Xticklabel', {'DMD' ; 'Widefield'})
errorbar([ 1 2], [ V1 V2], [V1s V2s],'.k','Linewidth', 2)
axis tight;ylabel('Spike SNR')
xlim([ 0.5 2.5]); ylim([3 5])
title([ 'p= ' num2str(p)])

