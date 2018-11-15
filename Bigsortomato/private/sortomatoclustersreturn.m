function sortomatoclustersreturn(~, ~, graphClusters, clusterNumber, clusterAlgorithm)
    % SORTOMATOCLUSTERSRETURN Transfer cluster memberships to Imaris
    %   Detailed explanation goes here
    
    %% Get the object cluster data.
    xImarisApp = getappdata(graphClusters, 'xImarisApp');
    
    structClusters = getappdata(graphClusters, 'structClusters');
    xObject = getappdata(graphClusters, 'xObject');
    
    % Organize the object cluster data.
    objectIdxs = vertcat(structClusters.ID);
    objectKIdxs = vertcat(structClusters.KIdx);
    objectTimes = vertcat(structClusters.TIdx);
    
    %% Transfer the cluster memberships to Imaris.
    % Create the stat name list.
    clustersNames = repmat({[num2str(clusterNumber)  '-' clusterAlgorithm ' clusters']}, size(objectIdxs));

    % Create the unit list.
    imarisUnits = '';
    clustersUnits = repmat({imarisUnits}, size(objectIdxs)); 

    % Assemble the factors cell array.
    clustersFactors = cell(3, length(objectIdxs));

    % Set the Category.
    if xImarisApp.GetFactory.IsSpots(xObject)
        clustersFactors(1, :) = repmat({'Spot'}, size(objectIdxs));

    else
        clustersFactors(1, :) = repmat({'Surface'}, size(objectIdxs));

    end % if

    % Set the Collection to an empty string.
    clustersFactors(2, :) = repmat({''}, size(objectIdxs));

    % Set the time.
    clustersFactors(3, :) = num2cell(objectTimes + 1);

    % Convert the time points to strings...
    clustersFactors(3, :) = cellfun(@num2str, clustersFactors(3, :), ...
        'UniformOutput', 0);

    % Create the factor names.
    clustersFactorNames = {'Category'; 'Collection'; 'Time'};

    % Send the stats to Imaris.
    xObject.AddStatistics(clustersNames, objectKIdxs, clustersUnits, ...
        clustersFactors, clustersFactorNames, objectIdxs)
end % sortomatoclustersreturn

