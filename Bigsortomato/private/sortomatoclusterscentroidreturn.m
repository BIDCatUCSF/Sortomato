function sortomatoclusterscentroidreturn(~, ~, graphKMeans, clusterNumber, clusterAlgorithm)
    % SORTOMATOCLUSTERSCENTROIDRETURN Transfer cluster centroids to Imaris
    %   Detailed explanation goes here
    
    %% Get the Imaris objects and centroid data.
    xImarisApp = getappdata(graphKMeans, 'xImarisApp');
    xObject = getappdata(graphKMeans, 'xObject');
    
    structClusters = getappdata(graphKMeans, 'structClusters');

    %% Calculate the cluster centroids.
    structCentroids(1:length(structClusters)) = struct('Pos', [], 'TIdx', []);
    for t = 1:length(structClusters)
        tClusterCount = max(structClusters(t).KIdx);
        structCentroids(t).Pos = zeros(tClusterCount, 3);
        for k = 1:tClusterCount
            kPos = structClusters(t).Pos(structClusters(t).KIdx == k);
            structCentroids(t).Pos(k, :) = mean(kPos);
        end % for k
        
        structCentroids(t).TIdx = t*ones(tClusterCount, 1);
    end % for t
    
    %% Create the position and time index lists.
    centroidPos = vertcat(structCentroids.Pos);
    centroidTimes = vertcat(structCentroids(t).TIdx) - 1;
    
    %% Generate a radius to use for the spots.
    if xImarisApp.GetFactory.IsSpots(xObject)
        objectRadii = xObject.GetRadii;
        
    else
        surfaceCount = xObject.GetNumberOfSurfaces;
        
        objectRadii = zeros(surfaceCount, 1);
        for s = 1:surfaceCount
            sVertices = xObject.GetVertices(s - 1);
            sCentroid = xObject.GetCenterOfMass(s - 1);
            
            sCtoVs = bsxfun(@minus, sVertices, sCentroid);
            objectRadii(s) = mean(sqrt(sum(sCtoVs.^2, 2)));
        end % for s
        
    end % if
    
    centroidRadii = repmat(mean(objectRadii), size(centroidTimes));
    
    %% Create an XT Spots object and add it to the Surpass scene.
    centroidSpots = xImarisApp.GetFactory.CreateSpots;
    
    centroidSpots.Set(centroidPos, centroidTimes, centroidRadii)
    centroidSpots.SetName([num2str(clusterNumber) '-' clusterAlgorithm ' cluster centroids'])
    
    xImarisApp.GetSurpassScene.AddChild(centroidSpots, -1)
end % sortomatoclusterscentroidreturn

