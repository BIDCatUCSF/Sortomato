function sortomatograph3togglerotate(toggleRotate, ~, hSortomatoGraph)
    % SORTOMATOGRAPHTOGGLEHZOOM Toggle interactive axes rotate
    %   Detailed explanation goes here
    
    %% Untoggle the data cursor and pan buttons.
    toggleDataCursor = findobj(hSortomatoGraph, 'Tag', 'toggleDataCursor');
    togglePan = findobj(hSortomatoGraph, 'Tag', 'togglePan');
    toggleZoom = findobj(hSortomatoGraph, 'Tag', 'toggleZoom');
    
    set([toggleDataCursor, togglePan, toggleZoom], 'State', 'off')
    
    %% Toggle rotate.
    if strcmp(get(toggleRotate, 'State'), 'on')
        rotate3d(hSortomatoGraph, 'on')
        
    else
        rotate3d(hSortomatoGraph, 'off')
        
    end % if
end % sortomatograph3togglerotate