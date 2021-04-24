%% Script for the automatic annotation of burst and phonation onsets
% Script loads chunks of a wav-file containing CV-sylablle responses. A
% Gamma-filterbank is applied to the signal. A smoothed envolope is
% calculated for % the high-frequency (app. consonant) and the
% low-frequency (vowel) part of the signal. In both evelope signals the
% enegy onset is found by means of a defined threshold value.
% Author: Eugen Klein, August, September 2014

tic;
%% clean the workspace
clear all; clc; close all;

%% get the directory and the file list
dirMain = 'E:\data_records\';
dirData = [dirMain 'logs\'];
dirGrids = [dirMain 'grids\'];
%txtList = dir([dirTxt '*.txt']);

txtList = dir([dirData '*.txt']);

%% outer for-loop to get the file
for i = 5:length(txtList)
    
    % read the txt-file
    fileID = fopen([dirData txtList(i).name]);
    data = textscan(fileID, ...
        '%d %d %s %s %s %s %d %d %.4f %.4f %s %s %s %.1f %*f %*f %.4f %*s', ...
        'Delimiter', ',');
    trialStart = data{9};
    trialBlock = [0; data{7}(1:256); 0; ...
        data{7}(257:512); 0; data{7}(513:768); ...
        0; data{7}(769:end)];
    trialMark = [0; data{10}(1:256); 0; ...
        data{10}(257:512); 0; data{10}(513:768); ...
        0; data{10}(769:end)];
    trialNumber = [0; data{08}(1:256); 0; ...
        data{08}(257:512); 0; data{08}(513:768); ...
        0; data{08}(769:end)];
    visCue = ['e'; data{11}(1:256); 'e'; ...
        data{11}(257:512); 'e'; data{11}(513:768); ...
        'e'; data{11}(769:end)];
    dist = ['e'; data{12}(1:256); 'e'; ...
        data{12}(257:512); 'e'; data{12}(513:768); ...
        'e'; data{12}(769:end)];
    votStep = ['e'; data{13}(1:256); 'e'; ...
        data{13}(257:512); 'e'; data{13}(513:768); ...
        'e'; data{13}(769:end)];
    basRes = data{6}(1);
    trialTotal = length(data{9});
    
    %% convert visual cue into a syllable response
    if strcmp(basRes, 'ka')
        symbol = '##';
    else
        symbol = '**';
    end
    
    for k = 1:length(visCue)
        if strcmp(visCue(k), symbol)
            response{k} = 'ka';
        elseif strcmp(visCue(k), 'e')
            response{k} = 'break';
        else
            response{k} = 'ta';
        end
    end
    
    %% clean distractor conditions
    for d = 1:length(votStep)
        if strcmp(votStep{d}, 'n')
            dist{d} = 'none';
            votStep{d} = '';
        elseif strcmp(votStep{d}, 't')
            dist{d} = 'tone';
            votStep{d} = '';
        elseif strcmp(votStep{d}, 'e')
            dist{d} = '';
            votStep{d} = '';
        end
    end
    
    %% get audio file info
    info = wavread([dirMain strtok(txtList(i).name, '.') '_1.wav'], 'size');
    fileLength = info(1)/44100; % in seconds
    fileLength = str2double(sprintf('%.3f', fileLength)); % round the number
    
    %% for-loop for analyzing each trial
    mirverbose(0);
    mirwaitbar(0);
    
    % allocate for speed
    release = zeros(1,1024);
    phonation = zeros(1,1024);
    
    for j = 1:trialTotal
        
        % load audio data into audio objects
        if j ~= trialTotal && j ~= 257 && j ~= 514 && j ~= 771
            audio = miraudio([dirMain strtok(txtList(i).name, '.') '_1.wav'], ...
                'Extract', trialStart(j), trialStart(j+1)-0.1, 'Channel', 1, 'Mono', 0, 'Normal');
        elseif j == trialTotal
            audio = miraudio([dirMain strtok(txtList(i).name, '.') '_1.wav'], ...
                'Extract', trialStart(j), fileLength-0.1, 'Channel', 1, 'Mono', 0, 'Normal');
        else
            audio = miraudio([dirMain strtok(txtList(i).name, '.') '_1.wav'], ...
                'Extract', trialStart(j), trialStart(j)+4, 'Channel', 1, 'Mono', 0, 'Normal');
        end
        
        % get spectral channels into variables
        fprintf('Compute trial %d of file %d. \n', j, i);
        
        burst = mirfilterbank(audio, 'Channel', 9);
        phon = mirfilterbank(audio, 'Channel', 2);
        
        %get an envelope of each channel with smoothing
        burstEnvel = mirenvelope(burst, 'Smooth', 2000, 'Normal');
        phonEnvel = mirenvelope(phon, 'Smooth', 2000, 'Normal');
        
        % pick the peaks nearest to the trial onset
        phonPeak = mirpeaks(phon, 'Threshold', 0.8, ...
            'Nearest', trialStart(j))
        %phonPeak = mirpeaks(phonEnvel, 'Threshold', 0.6, ...
        %    'Nearest', trialStart(j));
        
        % get the phonation start
        phonation(j) = mirgetdata(phonPeak);
        
        % peak 100 ms before the phonation
        burstPeak = mirpeaks(burst, 'Pref', phonation(j)-0.1, 'Threshold', 1, ...
            'Nearest', trialStart(j))
        % burstPeak = mirpeaks(burstEnvel, 'Pref', phonation(j)-0.1, ...
        %    'Nearest', trialStart(j));
    
        % get the release point
        release(j) = mirgetdata(burstPeak);
        clc; WaitSecs(1); close all;
    end
    
    % add values for breaks
    trialBounds = [0; trialStart(1:256); trialStart(256)+3; ...
        trialStart(257:512); trialStart(512)+3; trialStart(513:768); ...
        trialStart(768)+3; trialStart(769:end)];
    release = [0 release(1:256) release(256)+3 ...
        release(257:512) release(512)+3 release(513:768) ...
        release(768)+3 release(769:end)];
    phonation = [0 phonation(1:256) phonation(256)+3 ...
        phonation(257:512) phonation(512)+3 phonation(513:768) ...
        phonation(768)+3 phonation(769:end)];
    trialTotal = length(trialNumber);
    
    %% witing output to TextGrid
    
    fprintf('Writing Praat text grid file. \n');
    
    % create a textgrid-file
    fid = fopen([dirGrids strtok(txtList(i).name, '.') '_test.TextGrid'],'a');
    
    % write header
    fprintf(fid,'File type = \"ooTextFile\"\n');
    fprintf(fid,'Object class = \"TextGrid\"\n\n');
    fprintf(fid,'xmin = %.1f\n', 0.0);
    fprintf(fid,'xmax = %.3f\n', fileLength);
    fprintf(fid,'tiers? <exists>\n');
    % tiers for marker / release / phonation / trial / distractor / distractor condition
    fprintf(fid,'size = 8\n');
    fprintf(fid,'item []:\n');
    
    %% print marker tier
    
    fprintf('Writing marker tier. \n');
    
    fprintf(fid,'  item [1]:\n');
    fprintf(fid,'       class = \"TextTier\"\n');
    fprintf(fid,'       name = \"marker\"\n');
    fprintf(fid,'       xmin = %.1f\n', 0.0);
    fprintf(fid,'       xmax = %.3f\n', fileLength);
    fprintf(fid,'       points: size = %d\n', trialTotal-4);
    
    for t=1:length(trialMark)
        if t == 1 || t == 258 || t == 515 || t == 772
        else
            fprintf(fid, '       points[%d]:\n', t); % interval indices start at 1
            fprintf(fid, '           number = %.3f\n', trialMark(t));
            fprintf(fid, '           mark = \"\"\n');
        end
    end
    
    %% print release tier
    
    fprintf('Writing release tier. \n');
    
    fprintf(fid,'  item [2]:\n');
    fprintf(fid,'       class = \"TextTier\"\n');
    fprintf(fid,'       name = \"release\"\n');
    fprintf(fid,'       xmin = %.1f\n', 0.0);
    fprintf(fid,'       xmax = %.3f\n', fileLength);
    fprintf(fid,'       points: size = %d\n', trialTotal-4);
    
    for t=1:length(release)
        if t == 1 || t == 258 || t == 515 || t == 772
        else
        fprintf(fid, '       points[%d]:\n', t); % interval indices start at 1
        fprintf(fid, '           number = %.3f\n', release(t));
        fprintf(fid, '           mark = \"\"\n');
        end
    end
    
    %% print phonation tier
    
    fprintf('Writing phonation tier. \n');
    
    fprintf(fid,'  item [3]:\n');
    fprintf(fid,'       class = \"TextTier\"\n');
    fprintf(fid,'       name = \"phonation\"\n');
    fprintf(fid,'       xmin = %.1f\n', 0.0);
    fprintf(fid,'       xmax = %.3f\n', fileLength);
    fprintf(fid,'       points: size = %d\n', trialTotal-4);
    
    for t=1:length(phonation)
        if t == 1 || t == 258 || t == 515 || t == 772
        else
        fprintf(fid, '       points[%d] :\n', t); % interval indices start at 1
        fprintf(fid, '           number = %.3f\n', phonation(t));
        fprintf(fid, '           mark = \"\"\n');
        end
    end
    
    %% print trial tier
    
    fprintf('Writing trial tier. \n');
    
    fprintf(fid,'  item [4]:\n');
    fprintf(fid,'       class = \"IntervalTier\"\n');
    fprintf(fid,'       name = \"trial\"\n');
    fprintf(fid,'       xmin = %.1f\n', 0.0);
    fprintf(fid,'       xmax = %.3f\n', fileLength);
    fprintf(fid,'       intervals: size = %d\n', trialTotal);
    
    for t=1:length(trialBounds)
        
        if t == trialTotal
            fprintf(fid, '       intervals[%d] :\n', t);
            fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
            fprintf(fid, '           xmax = %.3f\n', trialBounds(t)+3);
            fprintf(fid, '           text = \"%d\"\n', trialNumber(t));
        else
            fprintf(fid, '       intervals[%d] :\n', t);
            fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
            fprintf(fid, '           xmax = %.3f\n', trialBounds(t+1));
            fprintf(fid, '           text = \"%d\"\n', trialNumber(t));
        end
    end
    
    %% print response tier
    
    fprintf('Writing response tier. \n');
    
    fprintf(fid,'  item [5]:\n');
    fprintf(fid,'       class = \"IntervalTier\"\n');
    fprintf(fid,'       name = \"response\"\n');
    fprintf(fid,'       xmin = %.1f\n', 0.0);
    fprintf(fid,'       xmax = %.3f\n', fileLength);
    fprintf(fid,'       intervals: size = %d\n', trialTotal);
    
    for t=1:length(trialBounds)
        
        if t == trialTotal
            fprintf(fid, '       intervals[%d] :\n', t);
            fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
            fprintf(fid, '           xmax = %.3f\n', trialBounds(t)+3);
            fprintf(fid, '           text = \"%s\"\n', response{t});
        else
            fprintf(fid, '       intervals[%d] :\n', t);
            fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
            fprintf(fid, '           xmax = %.3f\n', trialBounds(t+1));
            fprintf(fid, '           text = \"%s\"\n', response{t});
        end
    end
    
    %% print vot step tier with ms as text
    
    fprintf('Writing VOT step tier. \n');
    
    fprintf(fid,'  item [6]:\n');
    fprintf(fid,'       class = \"IntervalTier\"\n');
    fprintf(fid,'       name = \"vot step\"\n');
    fprintf(fid,'       xmin = %.1f\n', 0.0);
    fprintf(fid,'       xmax = %.3f\n', fileLength);
    fprintf(fid,'       intervals: size = %d\n', trialTotal);
    
    for t=1:length(trialBounds)
        if t == trialTotal
            fprintf(fid, '       intervals[%d] :\n', t);
            fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
            fprintf(fid, '           xmax = %.3f\n', trialBounds(t)+3);
            fprintf(fid, '           text = \"%s\"\n', votStep{t});
        else
            fprintf(fid, '       intervals[%d] :\n', t);
            fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
            fprintf(fid, '           xmax = %.3f\n', trialBounds(t+1));
            fprintf(fid, '           text = \"%s\"\n', votStep{t});
        end
    end
        %% print distractor tier with distractor syllable as text
        
        fprintf('Writing distractor tier. \n');
        
        fprintf(fid,'  item [7]:\n');
        fprintf(fid,'       class = \"IntervalTier\"\n');
        fprintf(fid,'       name = \"distractor\"\n');
        fprintf(fid,'       xmin = %.1f\n', 0.0);
        fprintf(fid,'       xmax = %.3f\n', fileLength);
        fprintf(fid,'       intervals: size = %d\n', trialTotal);
        
        for t=1:length(trialBounds)
            if t == trialTotal
                fprintf(fid, '       intervals[%d] :\n', t);
                fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
                fprintf(fid, '           xmax = %.3f\n', trialBounds(t)+3);
                fprintf(fid, '           text = \"%s\"\n', dist{t});
            else
                fprintf(fid, '       intervals[%d] :\n', t);
                fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
                fprintf(fid, '           xmax = %.3f\n', trialBounds(t+1));
                fprintf(fid, '           text = \"%s\"\n', dist{t});
            end
        end
        
    %% print block tier
    
    fprintf('Writing block tier. \n');
    
    fprintf(fid,'  item [8]:\n');
    fprintf(fid,'       class = \"IntervalTier\"\n');
    fprintf(fid,'       name = \"trial\"\n');
    fprintf(fid,'       xmin = %.1f\n', 0.0);
    fprintf(fid,'       xmax = %.3f\n', fileLength);
    fprintf(fid,'       intervals: size = %d\n', 9);
    
    for t=1:256:length(trialBounds)
        
        if t == trialTotal
            fprintf(fid, '       intervals[%d] :\n', t);
            fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
            fprintf(fid, '           xmax = %.3f\n', trialBounds(t)+3);
            fprintf(fid, '           text = \"%d\"\n', trialBlock(t));
        else
            fprintf(fid, '       intervals[%d] :\n', t);
            fprintf(fid, '           xmin = %.3f\n', trialBounds(t));
            fprintf(fid, '           xmax = %.3f\n', trialBounds(t+1));
            fprintf(fid, '           text = \"%d\"\n', trialBlock(t));
        end
    end
    
    fclose(fid);
    clc;
    fprintf('Finished file %d from %d. \n', i, length(txtList));
    
end

timeElap = toc;
fprintf('Finished all files! \n');
fprintf('Total time elapsed: %.2f minutes. \n', timeElap/60);