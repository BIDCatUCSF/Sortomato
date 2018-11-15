function pushexportstatscallback(~, ~, xImarisApp, xObject, guiSortomato)
    % PUSHEXPORTSTATSCALLBACK Export selected statistics from the Sortomato
    %   SORTOMATOEXPORTSTATS is a wrapper for the xtexportstats function.
    %   Type help xtexportstats for more information.
    %
    %   �2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %   license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Get the stat struct.
    statStruct = getappdata(guiSortomato, 'statStruct');
    
    %% Call the xtexportstats function.
    if all(get(guiSortomato, 'Color') == [0 0 0])
        bColor = 'k';
        
    else
        bColor = 'w';
        
    end % if
        
    xtexportstats(statStruct, xImarisApp, xObject, guiSortomato, 'Color', bColor)
end % pushexportstatscallback

