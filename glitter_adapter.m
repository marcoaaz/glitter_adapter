%Written by Marco A. Acevedo Zamora, QUT (21-Aug-2022) for Charlotte Allen
%See video for explanation.

%% Root folder
clear 
clc
close all
all_fig = findall(0, 'type', 'figure');
close(all_fig)

workingDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\charlotte_test';
cd(workingDir)

scriptDir1 = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts';
addpath(scriptDir1)

sourceDir = fullfile(workingDir, 'process');
destName = 'output_option2';
destDir = fullfile(sourceDir, destName);
mkdir(destDir)

%% Import

fileNames = GetFileNames(sourceDir, '.csv');
fileNames' %select accordingly

%Spectra
fileName1 = fullfile(sourceDir, fileNames{1});
opts1 = detectImportOptions(fileName1, 'VariableNamingRule', 'preserve', 'Delimiter', ',');
opts1.DataLines = [5, Inf];
opts1.VariableNamesLine = 4;
spectraFile = readtable(fileName1, opts1);
columnNames = spectraFile.Properties.VariableNames;

%File header
str = fileread(fileName1);
index1 = strfind(str, char(13)); %find new lines
header_line1 = str(1:(index1(1)-1)); %parse header
header_line2 = str((index1(1)+2):(index1(2)-1));
header_line3 = str((index1(2)+2):(index1(3)-1));

%Laser log
fileName2 = fullfile(sourceDir, fileNames{2});
opts2 = detectImportOptions(fileName2, 'VariableNamingRule','preserve', 'Delimiter', ',');
opts2.DataLines = [2, Inf];
opts2.VariableNamesLine = 1;
laserFile = readtable(fileName2, opts2);

%% Align

x = seconds(spectraFile.("Time [Sec]"));
y = spectraFile.("Si29");
% A1 = unique(y); %increasing order
% max_val = A1(end-3); %4th maximum
max_val = min(y(isoutlier(y, 'percentiles', [0 99.9])));
y(y>max_val) = max_val;
y = rescale(y, 0, 1);

x_laser_original = laserFile.("Timestamp"); %datetime
startTime = x_laser_original(1); 
x_laser = x_laser_original - startTime; %duration
x_laser1 = x_laser';

laserStatus = laserFile.("Laser State");
y_laser = strcmp(laserStatus, 'On');%logical
y_laser1 = y_laser';
%names (2 intervals before)
laserComment = laserFile.Comment([y_laser(3:end); false; false]);

n_stamps = length(y_laser);
n_on_stamps = sum(y_laser);

k = 0;
m = 0;
on_centre = duration(strings([1, n_on_stamps])); %pre-allocate
for i = 1:n_stamps
    k = k + 1;
    
    if y_laser1(k) == 1
        m = m + 1;

        x_temp = x_laser1(k); %start
        x_temp_post = x_laser1(k+1); %end
        
        %option 1: centered at 'On' trigger
%         on_centre(m) = x_temp; %option 1: required in PowerPoint (Charlotte)
        
        %option 2: centered at interval 
        on_centre(m) = (x_temp + x_temp_post)/2; 

        %prettyfing digital signal (like Iolite interface drag menu)
        x_laser1 = [x_laser1(1:k), x_temp, x_temp_post, x_laser1(k+1:end)];
        y_laser1 = [y_laser1(1:k-1), 0, 1, 1, y_laser1(k+1:end)];
        k = k + 2;
        
    else

    end
end

alignData.x = x;
alignData.y = y;
alignData.x_laser = x_laser1;
alignData.y_laser = y_laser1;

%GUI
delay_slider(alignData, 300)

%% Subsetting 

t_requested = 60; %interval in seconds

%aligned times
x_new = x - seconds(sliderValue) + startTime; %spectra timing
on_centre_time = on_centre + startTime; %laser on midpoints

spectra_subset = cell(1, n_on_stamps);
starting_times = cell(1, n_on_stamps);
for ii = 1:n_on_stamps
    temp_centre = on_centre_time(ii);
    temp_lower = temp_centre - seconds(t_requested/2);
    temp_upper = temp_centre + seconds(t_requested/2);
    
    idx = (x_new > temp_lower) & (x_new < temp_upper);
    temp_table = spectraFile(idx, :);    

    time_stagnant = 0.3215 + temp_table.("Time [Sec]") - temp_table.("Time [Sec]")(1);
    temp_table.("Time [Sec]") = time_stagnant; %replace

    %ensuring #rows=192 (use with Option 2?)
%     if size(temp_table, 1) > 192
%         temp_table(193:end, :) = [];
%     end

    spectra_subset{ii} = temp_table;
    starting_times{ii} = temp_lower;
end

%% Saving
delete(destDir) %avoid overwritting
mkdir(destDir)

for k = 1:n_on_stamps
    
    %line 1
    header_changing = strsplit(header_line1, '\');
    header_changing_last = header_changing{end};
    expression1 = '\d[-](?<old_name>.*)[.][d]';
    between_idx1 = regexp(header_changing_last, expression1, 'tokenExtents');

    update_txt = strcat(header_changing_last(1:between_idx1{1}(1)-1), ...
        laserComment{k}, ...
        header_changing_last(between_idx1{1}(2)+1:end));
    
    folderName_temp = update_txt; %folder name
    fileName_temp = strrep(update_txt, '.d', '.csv'); %file name
    batchName_temp = strrep(folderName_temp, '.d', '.b'); %batch name
    header_changing{end} = update_txt; %switching header
    
    %line 3
    line1_txt = strjoin(header_changing, '\'); %switching item
    
    time_temp = starting_times{k};
    time_temp.Format = 'dd/MM/uuuu HH:mm:ss'; %switching time
    
    text_changing = header_line3;
    expression2 = ':\s(?<old_date>.*)\s[u]';
    between_idx2 = regexp(text_changing, expression2, 'tokenExtents');
    update_txt = strcat(text_changing(1:between_idx2{1}(1)-1), {' '}, ...
        string(time_temp), ...
        text_changing(between_idx2{1}(2)+1:end));
    
    expression3 = '[h]\s(?<old_batch>.*)';
    between_idx3 = regexp(text_changing, expression3, 'tokenExtents');
    
    line3_txt = strcat(text_changing(1:between_idx3{1}(1)-1), {' '}, ...
        string(batchName_temp), ...
        text_changing(between_idx3{1}(2)+1:end));
    
    %Formatting
    headerlines = {line1_txt;
                   header_line2;
                   line3_txt
                   };
    
    subFolderDest = fullfile(sourceDir, destName, folderName_temp);
    mkdir(subFolderDest)
    fileDest = fullfile(subFolderDest, fileName_temp);

    %Saving
    fid = fopen(fileDest, 'wt');    
    for m = 1:numel(headerlines)
       fprintf(fid, '%s\n', headerlines{m});
    end
    fclose(fid);    
    
    writecell(columnNames, fileDest, "WriteMode", 'append', 'Delimiter', ',')
    writetable(spectra_subset{k}, fileDest, 'WriteMode', 'append', 'Delimiter', ',')
end

%%
% fileNames'
% {header_line1; header_line2; header_line3}



