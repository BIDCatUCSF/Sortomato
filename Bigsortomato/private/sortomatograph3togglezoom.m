function sortomatograph3togglezoom(toggleZoom, ~, hSortomatoGraph)
    % SORTOMATOGRAPHTOGGLEHZOOM Toggle interactive axes zoom
    %   Detailed explanation goes here
    
    %% Untoggle the data cursor and pan buttons.
    toggleDataCursor = findobj(hSortomatoGraph, 'Tag', 'toggleDataCursor');
    togglePan = findobj(hSortomatoGraph, 'Tag', 'togglePan');
    toggleRotate = findobj(hSortomatoGraph, 'Tag', 'toggleRotate');
    
    set([toggleDataCursor, togglePan, toggleRotate], 'State', 'off')
    
    %% Toggle zoom.
    if strcmp(get(toggleZoom, 'State'), 'on')
        zoom(hSortomatoGraph, 'on')
        
    else
        zoom(hSortomatoGraph, 'off')
        
    end % if
end % sortomatograph3togglezoom