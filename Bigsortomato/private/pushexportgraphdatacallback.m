function pushexportgraphdatacallback(~, ~, hGraph)
    % PUSHEXPORTGRAPHDATACALLBACK Summary of this function goes here
    %   Detailed explanation goes here
    %
    %  ©2010-2013, P. Beemiller. Licensed under a Creative Commmons Attribution
    %  license. Please see: http://creativecommons.org/licenses/by/3.0/
    %
    
    %% Use the Imaris source file and object name to constuct a default file name.
    xImarisApp = getappdata(hGraph, 'xImarisApp');
    [filePath, fileName] = fileparts(char(xImarisApp.GetCurrentFileName));
    
    xObject = getappdata(hGraph, 'xObject');
    
    exportName = [fileName ' - ' char(xObject.GetName) ' Data.xls'];
    
    %% Have the user specify the file information.
    [xlFile, xlFolder] = uiputfile({...
        '*.xls', 'Excel 97-2003 Workbook (.xls)'; 
        '*.xlsx', 'Excel Workbook (.xlsx)'; 
        '*.*', 'All Files' }, ...
        'Save Graph Data', fullfile(filePath, exportName));

    %% If the user doesn't cancel, get the plot data from the graph and write the file.
    if ischar(xlFile)
        switch get(hGraph, 'Tag')

            case 'hSortomatoGraph'
                %% Get the xy plot data.
                statStruct = getappdata(hGraph, 'statStruct');

                axesGraph = findobj(hGraph, 'Tag', 'axesGraph');
                xData = getappdata(axesGraph, 'xData');
                yData = getappdata(axesGraph, 'yData');

                %% If the plot is empty, return.
                if isempty(xData)
                    return
                end % if
                
                %% Get the x and y values and encapsulate the values in cells.
                xCell = num2cell(xData);
                yCell = num2cell(yData);

                %% Get the object IDs.
                % Find the index in the stat struct from the popup selection.
                popupY = findobj(hGraph, 'Tag', 'popupY');
                statIdx = get(popupY, 'Value');

                % Get the IDs from the stat structure.
                xlIDs = statStruct(statIdx).Ids;

                % Convert to a cell.
                xlIDs = num2cell(xlIDs);

                %% Construct a cell array to write to Excel.
                xlCell = cell(length(xCell) + 1, 3);
                xlCell(1, :) = {'ID', ...
                    get(get(axesGraph, 'xlabel'), 'String'), ...
                    get(get(axesGraph, 'ylabel'), 'String')};
                xlCell(2:end, :) = [xlIDs, xCell, yCell];

                %% Write the Excel file.
                xlswrite(fullfile(xlFolder, xlFile), xlCell, 1, 'A1')

            case 'hSortomatoGraph3'
                %% Get the xy plot data.
                statStruct = getappdata(hGraph, 'statStruct');

                axesGraph = findobj(hGraph, 'Tag', 'axesGraph');
                xData = getappdata(axesGraph, 'xData');
                yData = getappdata(axesGraph, 'yData');
                zData = getappdata(axesGraph, 'zData');
                
                %% If the plot is empty, return.
                if isempty(xData)
                    return
                end % if
                
                %% Get the x and y values and encapsulate the values in cells.
                xCell = num2cell(xData);
                yCell = num2cell(yData);
                zCell = num2cell(zData);
                
                %% Get the object IDs.
                % Find the index in the stat struct from the popup selection.
                popupY = findobj(hGraph, 'Tag', 'popupY');
                statIdx = get(popupY, 'Value');

                % Get the IDs from the stat structure.
                xlIDs = statStruct(statIdx).Ids;

                % Convert to a cell.
                xlIDs = num2cell(xlIDs);

                %% Construct a cell array to write to Excel.
                xlCell = cell(length(xCell) + 1, 4);
                xlCell(1, :) = {'ID', ...
                    get(get(axesGraph, 'xlabel'), 'String'), ...
                    get(get(axesGraph, 'ylabel'), 'String'), ...
                    get(get(axesGraph, 'zlabel'), 'String')};
                xlCell(2:end, :) = [xlIDs, xCell, yCell, zCell];

                %% Write the Excel file.
                xlswrite(fullfile(xlFolder, xlFile), xlCell, 1, 'A1')

            case 'graphMSD'
                %% Get the MSD data.
                objectMSD = getappdata(hGraph, 'objectMSD');
                
                %% Create a cell to write to Excel.
                delayNumber = size(objectMSD.msd{1}, 1);
                trackNumber = size(objectMSD.msd, 1);
                xlCell = cell(delayNumber + 1, trackNumber + 4, 3);
                
                %% Add the column information.
                xlCell(1, 1:4, 1) = {...
                    ['dt (' objectMSD.time_units ')']
                    'MSD Mean'
                    'MSD Std. Dev.'
                    'n'};
                
                xlCell(1, 5:end, 1) = num2cell((0:trackNumber - 1) + 1e9);
                
                %% Add the weighted aggregates to the cell.
                msdMean = objectMSD.getMeanMSD;
                xlCell(2:end, 1:4, 1) = num2cell(msdMean);
                
                %% Add the msd series to the cell.
                for r = 1:trackNumber
                    xlCell(2:end, r + 4, 1) = num2cell(objectMSD.msd{r}(:, 2));
                    xlCell(2:end, r + 4, 2) = num2cell(objectMSD.msd{r}(:, 3));
                    xlCell(2:end, r + 4, 3) = num2cell(objectMSD.msd{r}(:, 4));
                end % for r
                
                %% Write the data to the Excel file.
                warning('off', 'MATLAB:xlswrite:AddSheet')
                
                xlswrite(fullfile(xlFolder, xlFile), xlCell(:, :, 1), ...
                    'Mean-squared displacement', 'A1')
                xlswrite(fullfile(xlFolder, xlFile), xlCell(:, :, 2), ...
                    'Track MSD std dev', 'A1')
                xlswrite(fullfile(xlFolder, xlFile), xlCell(:, :, 3), ...
                    'Track MSD n', 'A1')
                
                warning('on', 'MATLAB:xlswrite:AddSheet')
                
            case 'graphTracks'
                %% Get the track data.
                centeredTracks = getappdata(graphTracks, 'centeredTracks');
                
                %% Write the Excel file.
                xlswrite(fullfile(xlFolder, xlFile), centeredTracks, 1, 'A1')
            
            case 'graphKMeans'
                %% Get the cluster data.
                structKMeans = getappdata(hGraph, 'structKMeans');
                
                %% Get the object data.
                objectIDs = vertcat(structKMeans.ID);
                objectParents = vertcat(structKMeans.Parent);
                objectTimes = vertcat(structKMeans.TIdx); 
                clusterNumber = max(structKMeans(1).KIdx);
                
                %% Sort the data into track order.
                [objectParents, trackOrder] = sort(objectParents);
                
                objectIDs = objectIDs(trackOrder);
                objectTimes = objectTimes(trackOrder);
                
                %% Organize the data into a cell.
                xlCell = cell(length(objectIDs) + 2, 6);
                
                sheetLabel = [num2str(clusterNumber) '-k-means clusters'];
                xlCell(1, 1) = {sheetLabel};
                xlCell(2, :) = {'Value', 'Unit', 'Category', 'Time', 'Parent', 'ID'};
                xlCell(3:end, 1) = num2cell(vertcat(structKMeans.KIdx));
                
                if xImarisApp.GetFactory.IsSpots(xObject)
                    xlCell(3:end, 3) = repmat({'Spot'}, size(objectIDs));
                    
                else
                    xlCell(3:end, 3) = repmat({'Surface'}, size(objectIDs));
                    
                end % if
                
                xlCell(3:end, 4) = num2cell(objectTimes);
                xlCell(3:end, 5) = num2cell(objectParents);
                xlCell(3:end, 6) = num2cell(objectIDs);

                %% Write the Excel file.
                warning('off', 'MATLAB:xlswrite:AddSheet')
                
                xlswrite(fullfile(xlFolder, xlFile), xlCell, sheetLabel, 'A1')
                
                warning('on', 'MATLAB:xlswrite:AddSheet')
                
        end % switch
    end % if
end % pushexportgraphdatacallback