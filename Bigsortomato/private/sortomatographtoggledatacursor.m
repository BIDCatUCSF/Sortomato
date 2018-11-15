function sortomatographtoggledatacursor(toggleDataCursor, ~, hSortomatoGraph)
    % SORTOMATOGRAPHTOGGLEDATACURSOR Toggle interactive axes data cursor
    %   Detailed explanation goes here
    
    %% Untoggle the zoom and pan buttons.
    toggleZoom = findobj(hSortomatoGraph, 'Tag', 'toggleZoom');
    togglePan = findobj(hSortomatoGraph, 'Tag', 'togglePan');
    
    set([toggleZoom, togglePan], 'State', 'off')
    
    %% Toggle data cursor.
    if strcmp(get(toggleDataCursor, 'State'), 'on')
        datacursormode(hSortomatoGraph, 'on')
        
    else
        datacursormode(hSortomatoGraph, 'off')
        
    end % if
end % sortomatographtoggledatacursor