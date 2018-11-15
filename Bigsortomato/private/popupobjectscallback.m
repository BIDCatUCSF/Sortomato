function popupobjectscallback(hObject, ~, guiSortomato)
    % POPUPOBJECTSCALLBACK Selects an Imaris Spots or Surfaces object
    %   Detailed explanation goes here
    %
    %   ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %   license. Please see: http://creativecommons.org/licenses/by/3.0/
    %

    %% Get the selected Surpass object.
    xImarisApp = getappdata(guiSortomato, 'xImarisApp');
    surpassObjects = getappdata(hObject, 'surpassObjects');
    
    listValue = get(hObject, 'Value');
    xObject = surpassObjects(listValue).ImarisObject;
    
    %% Update the status bar.
    statusbar(guiSortomato, 'Getting statistics');
    
    %% Get the statistics from Imaris.
    statStruct = xtgetstats(xImarisApp, xObject, 'ID', 'ReturnUnits', 1);

    %% Find the stats that represent single spots/surfaces and tracks.
    % We store the indices in the stats struct of spot and track stats. This
    % lets us quickly mask to use spot or track stats as selected by users.
    trackStatIdxs = strncmp('Track ', {statStruct.Name}, 6);
    singletStatIdxs = ~trackStatIdxs;
    
    %% Set the data export, graph and stat math callbacks.
    if any(get(guiSortomato, 'Color'))
        fColor = 'k';
        
    else
        fColor = 'w';
        
    end % if
    
    % Update the popup string color to reflect that an object has been
    % selected.
    set(hObject, 'ForegroundColor', fColor)
    
    % Update the export, graph and stat math callbacks.
    pushExportStats = findobj(guiSortomato, 'Tag', 'pushExportStats');
    set(pushExportStats, 'Callback', {@pushexportstatscallback, ...
        xImarisApp, xObject, guiSortomato})
    
    pushGraph = findobj(guiSortomato, 'Tag', 'pushGraph');
    set(pushGraph, 'Callback', {@sortomatograph, statStruct, guiSortomato})
    
    pushGraph3 = findobj(guiSortomato, 'Tag', 'pushGraph3');
    set(pushGraph3, 'Callback', {@sortomatograph3, statStruct, guiSortomato})
    
    pushStatMath = findobj(guiSortomato, 'Tag', 'pushStatMath');
    set(pushStatMath, 'Callback', {@sortomatostatmath, statStruct, guiSortomato})
    
    %% Store the statistics data and selected object as appdata.
    setappdata(guiSortomato, 'statStruct', statStruct);
    setappdata(guiSortomato, 'trackStatIdxs', trackStatIdxs);
    setappdata(guiSortomato, 'singletStatIdxs', singletStatIdxs);
    setappdata(hObject, 'xObject', xObject)
    
    %% Reset the status bar.
    statusbar(guiSortomato, '');
end % popupobjectscallback