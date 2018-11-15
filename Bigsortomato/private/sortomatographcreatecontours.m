function hContour = sortomatographcreatecontours(hAxes, xData, yData, contourLevels, contourKernel)
    % SORTOMATOGRAPHCREATECONTOURS Generate contours for the Sortomato graph
    %   Detailed explanation goes here
    
    %% Generate a histogram of the data.
    % Create the raw histogram.
    [xyHist, xyLocs] = hist3([yData, xData], [contourLevels contourLevels]);

    % Smooth the histogram.
    if ~isscalar(contourKernel)
        xyHistSmooth = filter2(contourKernel, padarray(xyHist, [1 1]));
        xyHistSmooth = xyHistSmooth(2:end - 1, 2:end - 1);
        
    else
        xyHistSmooth = xyHist;
        
    end % if

    %% Create the contour plot.
    [~, hContour] = contourf(hAxes, xyLocs{2}, xyLocs{1}, xyHistSmooth, ...
        contourLevels, 'LineColor', 'None');
    set(hContour, 'HitTest', 'off')
    uistack(hContour, 'bottom')

    set(hAxes, 'XLimMode', 'Auto', 'YLimMode', 'Auto')
end % sortomatographcreatecontours