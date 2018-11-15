function [ output_args ] = sortomatokmeans(guiClusters, structClusters, xObject, hSortomatoBase)
    % SORTOMATOKMEANS Perform k-means cluster analysis
    %   Detailed explanation goes here
    
    %% Parse the inputs.
    sortomatokmeansParser = inputParser;
    addRequired(sortomatokmeansParser, 'guiClusters', @(arg)ishandle(arg))
    addRequired(sortomatokmeansParser, 'structClusters', ...
        @(arg)all(isfield(arg, {'Pos', 'TIdx'})))
    addRequired(sortomatokmeansParser, 'xObject')
    addRequired(sortomatokmeansParser, 'hSortomatoBase', @(arg)ishandle(arg))
    
    parse(sortomatokmeansParser, guiClusters, structClusters, xObject, hSortomatoBase)
    
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

            % Calculate the k-means clusters.
            structClusters(t).KIdx = kmeans(tPos, clusterNumber);

            % Generate the silhouette values.
            structClusters(t).SilValues = silhouette(tPos, structClusters(t).KIdx);

            % Update the progress bar.
            hStatus.ProgressBar.setValue(t)
        end % for t            

    else
        kList = 1:clusterNumber;
        
        % Evaluate the clustering.
        for t = 1:length(structClusters)
            tPos = structClusters(t).Pos;

            % Calculate the k-means clustering.
            clusterEvalObj = evalclusters(double(tPos), 'kmeans', criterionString, ...
                'KList', kList);
            structClusters(t).KIdx = clusterEvalObj.OptimalY;

            % Generate the silhouette values.
            structClusters(t).SilValues = silhouette(tPos, structClusters(t).KIdx);

            % Update the progress bar.
            hStatus.ProgressBar.setValue(t)
        end % for t            

    end % if
    
    %% Create the figure to plot the silhouettes.
    [graphKMeans, axesGraph] = sortomatoclustersgraph(guiClusters, ...
        clusterNumber, 'kmeans', length(structClusters), xObject, hSortomatoBase);

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
    setappdata(graphKMeans, 'structClusters', structClusters)
    setappdata(graphKMeans, 'hSortomatoBase', hSortomatoBase)
    setappdata(graphKMeans, 'xObject', xObject)
    xImarisApp = getappdata(hSortomatoBase, 'xImarisApp');
    setappdata(graphKMeans, 'xImarisApp', xImarisApp)  
end % sortomatokmeans

