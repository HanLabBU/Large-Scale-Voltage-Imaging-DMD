
% % in vivo data
%cd('\\engnas.bu.edu\research\eng_research_handata\EricLowet\DMD\invivoDMD\')
%cd('\\engnas.bu.edu\research\eng_research_handata\EricLowet\DMD\comp_wide_indi\')
clc;
close all;
clear all;
 
% Use the scripts in the DMD scripts folder
addpath('.');
addpath(genpath('~/handata_server/EricLowet/Scripts/'));

% in vitro data
cd('~/handata_server/Pierre Fabris/DMD Project/All In Vitro Analysis/');

% Folder to save figures
%save_fig_path = '\\engnas.bu.edu\research\eng_research_handata\Pierre Fabris\DMD Project\Data Fi226 - 67 (NaNs) = gures\';
save_fig_path = '~/handata_server/Pierre Fabris/DMD Project/Data Figures/';

% Ignore the first trial across each FOV for photobleaching estimation
ignore_first = 1;
% Ignore the 2nd trial of 24
ignore_24 = 1;

% Original Sampling Frequency
sample_frequency = 500; % Hz

ses=dir('*.mat');

%% TODO set which FOV file to create the quantile quantile plot
find_fov = 'Culture 7';

%%% search for the wide
clear wideloc
for id=1:length(ses) 
    if contains(ses(id).name, 'Wide') == 1 && contains(ses(id).name, find_fov) == 1
        wideloc = id;
        break;
    end
end

% Find corresponding individual field
clear indiloc
for id=1:length(ses)
    if contains(ses(id).name, 'Individual') == 1 && contains(ses(id).name, find_fov) == 1
        indiloc = id;
        break;
    end
end

% Plan for this is to just concatenate all of the detrended traces together from 
% each trial and then plot the quantile-quantile for each neuron of each trial
% Loop through each FOV and corresponding condition file

% Load respective condition data
widefile=load(ses(wideloc).name);
indifile=load(ses(indiloc).name);  

% Sanity check that I got the same condition data

if indifile.allresults.fov_name ~= widefile.allresults.fov_name
    disp('File data do not match!!');
end

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

% Detrend and concatenate all of the neuron's traces
indi_detrend_trace = [];
wide_detrend_trace = [];
for i=1:length(mROI(:, 1))
    
    neuron_trace = [];
    for tr=2  %1:length(indifile.allresults.trial)
        trace = indifile.allresults.trial{tr}.traces(:, i);
        
        % Perform the detrend similar to that in the spike detect code
        trace = trace - fastsmooth(trace, 1000, 1, 1);
        trace = trace - fastsmooth(trace, 30, 1, 1);
        
        neuron_trace = [neuron_trace; trace];
    end

    indi_detrend_trace = cat(1, indi_detrend_trace, neuron_trace);
    
    neuron_trace = [];
    for tr=2 %1:length(widefile.allresults.trial)
        trace = widefile.allresults.trial{tr}.traces(:, i);
        
        % Perform the detrend similar to that in the spike detect code
        trace = trace - fastsmooth(trace, 1000, 1, 1);
        trace = trace - fastsmooth(trace, 30, 1, 1);
        
        neuron_trace = [neuron_trace; trace];
    end
    
    wide_detrend_trace = cat(1, wide_detrend_trace, neuron_trace);

    figure('Position', [0 0 2000 1500]);
    subplot(2,2,1);
    qqplot(indi_detrend_trace);
    title('Individual');
    subplot(2,2,2);
    qqplot(wide_detrend_trace);
    title('Wide field');
    subplot(2,2,3)
    plot(indi_detrend_trace);
    title('Indi Detrended trace');
    subplot(2,2,4)
    plot(wide_detrend_trace);
    title('Wide Detrended trace');
end

% Publish as a pdf
