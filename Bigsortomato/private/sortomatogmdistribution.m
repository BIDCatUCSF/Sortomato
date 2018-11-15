function [ output_args ] = sortomatogmdistribution(guiClusters, structClusters, xObject, hSortomatoBase)
    % SORTOMATOGMDISTRIBUTION Perform Gaussian mixture model cluster analysis
    %   Detailed explanation goes here
    
    %% Parse the inputs.
    sortomatogmdistributionParser = inputParser;
    addRequired(sortomatogmdistributionParser, 'guiClusters', @(arg)ishandle(arg))
    addRequired(sortomatogmdistributionParser, 'structClusters', ...
        @(arg)all(isfield(arg, {'Pos', 'TIdx'})))
    addRequired(sortomatogmdistributionParser, 'xObject')
    addRequired(sortomatogmdistributionParser, 'hSortomatoBase', @(arg)ishandle(arg))
    
    parse(sortomatogmdistributionParser, guiClusters, structClusters, xObject, hSortomatoBase)
    
    %% Get the cluster number.
    editClusters = findobj('Tag', 'editClusters');
    clusterNumber = str2double(get(editClusters, 'String'));
        
    %% Setup the progress bar.
    hStatus = statusbar(guiClusters, 'Evaluating clusters');
    hStatus.ProgressBar.setValue(0)
    hStatus.ProgressBar.setVisible(true)
    hStatus.ProgressBar.setMaximum(length(structClusters))

    %% Setup the cluster evaluation.
    popupCriterion = findobj(guiClusters, 'Tag', 'popupCriterion');
    popupCriterionString = get(popupCriterion, 'String');
    popupCriterionValue = get(popupCriterion, 'Value');
    criterionString = regexprep(popupCriterionString{popupCriterionValue}, '-| ', '');
    
    % Determine the number of clusters to evaluate.
    if strcmp(criterionString, 'Manual')
        % Evaluate the clustering.
        for t = 1:length(structClusters)
            tPos = double(structClusters(t).Pos);

            % Calculate the Gaussian mixture model clusters.
            gmFit = gmdistribution.fit(tPos, clusterNumber);
            structClusters(t).KIdx = cluster(gmFit, tPos);

            % Generate the silhouette values.
            structClusters(t).SilValues = silhouette(tPos, structClusters(t).KIdx);

            % Update the progress bar.
            hStatus.ProgressBar.setValue(t)
        end % for t            
        
    else
        kList = 1:clusterNumber;
        
        % Evaluate the clustering.
        for t = 1:length(structClusters)
            tPos = double(structClusters(t).Pos);

            % Calculate the Gaussian mixture model clusters.
            clusterEvalObj = evalclusters(tPos, 'gmdistribution', criterionString, ...
                'KList', kList);
            structClusters(t).KIdx = clusterEvalObj.OptimalY;

            % Generate the silhouette values.
            structClusters(t).SilValues = silhouette(tPos, structClusters(t).KIdx);

            % Update the progress bar.
            hStatus.ProgressBar.setValue(t)
        end % for t            

    end % if
    
    %% Create the figure to plot the silhouettes.
    [graphGMDistribution, axesGraph] = sortomatoclustersgraph(guiClusters, ...
        clusterNumber, 'Gaussian mixture', length(structClusters), xObject, hSortomatoBase);

    %% Plot the silhouettes for the first time point.
    [~, ~] = silhouette(structClusters(1).Pos, structClusters(1).KIdx);

    %% Format the silhoutte plot.
    % Format the axes.
    if all(get(hSortomatoBase, 'Color') == [0 0 0])
        axColor = 0.75*ones(3, 1);

    else
        axColor = 0.25*ones(3, 1);

    end % if
    
    set(axesGraph, ...
        'Box', 'off', ...
        'Color', 'None', 'FontSize', 12, ...
        'Linewidth', 2, ...
        'Tag', 'axesGraph', ...
        'TickDir', 'Out', ...
        'Units', 'Pixels', ...
        'XColor', axColor, ...
        'YColor', axColor, ...
        'ZColor', axColor)

    % Format and tag the bar plot.
    barSilhouettes = get(axesGraph, 'Children');
    set(barSilhouettes, 'FaceColor', 'flat', 'Tag', 'barSilhouettes')

    patchSilhouettes = get(barSilhouettes, 'Children');
    patchColors = rgb32bittotriplet(xObject.GetColorRGBA);
    set(patchSilhouettes, 'FaceVertexCData', patchColors)
    
    silBaseLine = get(barSilhouettes, 'BaseLine');
    set(silBaseLine, 'Color', axColor)
    
    %% Store the plot data for export.
    setappdata(graphGMDistribution, 'structClusters', structClusters)
    setappdata(graphGMDistribution, 'hSortomatoBase', hSortomatoBase)
    setappdata(graphGMDistribution, 'xObject', xObject)
    xImarisApp = getappdata(hSortomatoBase, 'xImarisApp');
    setappdata(graphGMDistribution, 'xImarisApp', xImarisApp)
end % sortomatogmdistribution

