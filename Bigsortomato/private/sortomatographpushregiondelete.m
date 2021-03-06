function sortomatographpushregiondelete(~, ~, hSortomatoGraph, varargin)
    % SORTOMATOGRAPHPUSHREGIONDELETE Delete the selected region
    %   Detailed explanation goes here
    %
    %  �2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %  license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Get the name of the region to delete.
    popupRegions = findobj(hSortomatoGraph, 'Tag', 'popupRegions');
    popupString = get(popupRegions, 'String');
    
    if strcmp(popupString, ' ')
        return
    end % if
    
    if nargin == 4
        rgnDeleteString = varargin{1};
        
    else
        if iscell(popupString)
            popupValue = get(popupRegions, 'Value');
            rgnDeleteString = popupString{popupValue};
                
        else
            rgnDeleteString = popupString;
            
        end % if
        
    end % if
    
    %% Determine the region type, then delete the region from the list.
    axesGraph = findobj(hSortomatoGraph, 'Tag', 'axesGraph');
    regionStruct = getappdata(axesGraph, 'regionStruct');
    nextRegionTag = getappdata(axesGraph, 'nextRegionTag');
    
    switch rgnDeleteString(1:4)
        
        case 'Elli'
            % Find the ellipse to delete.
            typeIdxToDel = strcmp({regionStruct.Ellipse.Name}, rgnDeleteString);

            % Delete the object and remove it from the handles list.
            regionStruct.Ellipse(typeIdxToDel).delete
            validEllipses = [regionStruct.Ellipse.isvalid];
            regionStruct.Ellipse = regionStruct.Ellipse(validEllipses);

            % Reset the index to use for the next ellipse.
            if any(size(regionStruct.Ellipse) == [0 0])
                nextRegionTag(1) = 1;
                
            else
                ellipseTags = cellfun(@str2double, ...
                    regexp({regionStruct.Ellipse.Name}, '\d{1,}', 'Match'));
                nextRegionTag(1) = max(ellipseTags) + 1;
                
            end % if

        case 'Poly'
            % Find the polygon to delete.
            typeIdxToDel = strcmp({regionStruct.Poly.Name}, rgnDeleteString);

            % Delete the object and remove it from the handles list.
            regionStruct.Poly(typeIdxToDel).delete
            validPolys = [regionStruct.Poly.isvalid];
            regionStruct.Poly = regionStruct.Poly(validPolys);

            % Reset the index to use for the next polygon. 
            if any(size(regionStruct.Poly) == [0 0])
                nextRegionTag(2) = 1;
                
            else
                polygonTags = cellfun(@str2double, ...
                    regexp({regionStruct.Poly.Name}, '\d{1,}', 'Match'));
                nextRegionTag(2) = max(polygonTags) + 1;
                
            end % if

        case 'Rect'
            % Find the rectangle to delete.
            typeIdxToDel = strcmp({regionStruct.Rect.Name}, rgnDeleteString);

            % Delete the object and remove it from the handles list.
            regionStruct.Rect(typeIdxToDel).delete
            validRects = [regionStruct.Rect.isvalid];
            regionStruct.Rect = regionStruct.Rect(validRects);

            % Reset the index to use for the next rectangle.
            if any(size(regionStruct.Rect) == [0 0])
                nextRegionTag(3) = 1;
                
            else
                rectangleTags = cellfun(@str2double, ...
                    regexp({regionStruct.Rect.Name}, '\d{1,}', 'Match'));
                nextRegionTag(3) = max(rectangleTags) + 1;
                
            end % if

        case 'Free'
            % Find the freehand region to delete.
            typeIdxToDel = strcmp({regionStruct.Freehand.Name}, rgnDeleteString);

            % Delete the object and remove it from the handles list.
            regionStruct.Freehand(typeIdxToDel).delete
            validFrees = [regionStruct.Freehand.isvalid];
            regionStruct.Freehand = regionStruct.Freehand(validFrees);

            % Reset the index to use for the next freehand region.
            if any(size(regionStruct.Freehand) == [0 0])
                nextRegionTag(4) = 1;
                
            else
                freehandTags = cellfun(@str2double, ...
                    regexp({regionStruct.Freehand.Name}, '\d{1,}', 'Match'));
                nextRegionTag(4) = max(freehandTags) + 1;
                
            end % if

    end % switch

    %% Delete the region from the tag list and update the regions popup.
    rgnDeleteIdx = strcmp(rgnDeleteString, popupString);
    popupString = popupString(~rgnDeleteIdx);
    
    %% Update the regions popup.
    % If the region list is now empty we use a single space for the string.
    if ~isempty(popupString)
        set(popupRegions, 'String', popupString, 'Value', 1)

    else
        set(popupRegions, 'String', ' ', 'Value', 1)

    end % if
    
    %% Update the stored region tracking variables.
    setappdata(axesGraph, 'regionStruct', regionStruct)
    setappdata(axesGraph, 'nextRegionTag', nextRegionTag)
end % sortomatographpushregiondelete