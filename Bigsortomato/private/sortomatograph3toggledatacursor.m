function sortomatograph3toggledatacursor(toggleDataCursor, ~, hSortomatoGraph)
    % SORTOMATOGRAPHTOGGLEDATACURSOR Toggle interactive axes data cursor
    %   Detailed explanation goes here
    
    %% Untoggle the zoom and pan buttons.
    toggleZoom = findobj(hSortomatoGraph, 'Tag', 'toggleZoom');
    togglePan = findobj(hSortomatoGraph, 'Tag', 'togglePan');
    toggleRotate = findobj(hSortomatoGraph, 'Tag', 'toggleRotate');
    
    set([toggleZoom, togglePan, toggleRotate], 'State', 'off')
    
    %% Toggle data cursor.
    if strcmp(get(toggleDataCursor, 'State'), 'on')
        datacursormode(hSortomatoGraph, 'on')
        
    else
        datacursormode(hSortomatoGraph, 'off')
        
    end % if
end % sortomatograph3toggledatacursor

