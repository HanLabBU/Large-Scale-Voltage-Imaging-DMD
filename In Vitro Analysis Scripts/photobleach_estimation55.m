% Takes trial traces and calculates the percent change in
% intensity between the first n points and the n 100 points

% Author: Pierre Fabris

% Arguments: 
% traces - all of the traces in a given trial
% n - the number of points at the beginning or end of trace to calculate
% the intensity ratio
%
% Returns an array of all the photobleach ratios
function [result] = photobleach_estimation(traces, n)
    photo_bleach_ratio = [];
  
    % Loop through each neuron
    for i=1:size(traces, 2)
            trace = traces(:, i);
            
            % Apply median filter to filter out spikes
            % This filter is not changing much of the overall plots
            trace = medfilt1(trace, 51);
            if ~any(isnan(trace))
            init_mean_intensity = nanmean(trace(1:n)) -767.7;
            last_mean_intensity = nanmean(trace(end-n:end)) -767.7;
            
            [fitval, fitgood]=traces_photo_fit( trace);
            
            if fitval(2) >= fitval(4)
              xx=fitval;
              fitval(1:2)= fitval(3:4);
              fitval(3:4)= xx(1:2);
            end
                
            photo_bleach_ratio = [photo_bleach_ratio; [last_mean_intensity/init_mean_intensity,fitval(1),fitval(2),fitval(3),fitval(4),fitgood]];
            
            end
            
    end
    
    result = photo_bleach_ratio;
    
end
