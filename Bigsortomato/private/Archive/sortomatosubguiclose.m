function sortomatosubguiclose(hObject, ~, hSortomatoBase)
    % SORTOMATOSUBGUICLOSE Close a Sortimzer sub-GUI
    %   SORTOMATOSUBGUICLOSE is a template function to close a GUI figure
    %   and removes its handle from the list of running GUIs stored as
    %   appdata in the sortomatobase GUI. It is not called by any
    %   functions in the sortomato.
    
    %% Remove the GUI's handle from the base's GUI children and delete.
    guiChildren = getappdata(hSortomatoBase, 'guiChildren');

    guiIdx = guiChildren == hObject;
    guiChildren = guiChildren(~guiIdx);
    setappdata(hSortomatoBase, 'guiChildren', guiChildren)
    delete(hObject);
end % sortomatosubguiclose

