%% Script for semi-automatic annotation of burst, phonation onset,
% and vowel duration
%
% Script loads chunks of a wav-file containing CV-sylablle responses based
% on the experimental log-file. Sound is filtered before plotting and
% presented along with a spectrogramm. The annotation points are inserted
% via MATLAB'S ginput function. The RTs and VOTs are computed from the
% annotation points. All relevant data is written into an excel file.
%
% Author: Eugen Klein, August, September 2014


%% clean the workspace
clear all; clc; close all;

% Perform basic initialization of the sound driver:
InitializePsychSound;

tic;
%% get the directories and the log file list
dirMain = 'E:\data_master\';
dirLogs = [dirMain 'logs\'];
dirData = [dirMain 'data_processing\data\'];
logList = dir([dirLogs '*.txt']);

% filter specifications for audio
[b1,a1]= butter(6,.02, 'low');
%[b2,a2]= butter(6,.01, 'low');

files = length(logList);
fileNr = 12;

%% outer loop to get the file
while files ~= 0
    
    fprintf('Get and clean data of file %d (%s). \n', fileNr, logList(fileNr).name);
    
    % read the log-file from the experiment
    fileID = fopen([dirLogs logList(fileNr).name]);
    data = textscan(fileID, ...
        '%d %d %s %s %s %s %d %d %.4f %.4f %s %s %s %s %*f %*f %.4f %*s', ...
        'Delimiter',',');      

%     for logs 4 and 5
%       '%d %d %s %s %s %s %d %d %.4f %.4f %s %s %s %s %*f %s', ...
%       'Delimiter',',');
    
    fclose(fileID);
    
    % personal info
    subjectID = {data{1}(1)};
    gender = data{3}(1);
    age = {data{2}(1)};
    origin = data{4}(1);
    
    % trial info
    trialStart = data{9};
    trialBlock = num2cell(data{7});
    trialMark = data{10};
    trialNumber = num2cell(data{08});
    visCue = data{11};
    dist = data{12};
    votStep = data{13};
    soa = data{14};
    
    basRes = data{6}(1);
    trialTotal = length(data{9});
    trialNr = 1;
    
    %% convert visual cue into a syllable response
    if strcmp(basRes, 'ka')
        symbol = '##';
    else
        symbol = '**';
    end
    
    for k = 1:length(visCue)
        if strcmp(visCue(k), symbol)
            response{k} = 'ka';
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
        else
        end
    end
    
    %% determine the distractor condition
    for c = 1:length(dist)
        if strcmp(dist{c}, response{c})
            distCon{c} = 'match';
        elseif strcmp(dist{c}, 'none')
            distCon{c} = 'none';
        elseif strcmp(dist{c}, 'tone')
            distCon{c} = 'tone';
        else
            distCon{c} = 'mismatch';
        end
    end
    
    %% get audio file info
    [a, freqAudio] = wavread([dirMain strtok(logList(fileNr).name, '.') '_1.wav'], 1);
    info = wavread([dirMain strtok(logList(fileNr).name, '.') '_1.wav'], 'size');
    fileLength = info(1)/freqAudio; % in seconds
    fileLength = str2double(sprintf('%.3f', fileLength)); % truncate the number
    pahandle = PsychPortAudio('Open', [], [], 0, freqAudio, 1);
    
    %% loop for analyzing each trial
    % run this section after aborting the script to continue the work
   
    while trialTotal ~= 0
        fprintf('Load trial %d of file %d (%s). \n', trialNr, fileNr, ...
            logList(fileNr).name);
        
        % define different onset points
        onset1 = round((trialMark(trialNr)+.15)*freqAudio);
        onset2 = round((trialMark(trialNr)+.45)*freqAudio);
        onset3 = round((trialMark(trialNr)+.75)*freqAudio);
        onset4 = round((trialMark(trialNr)+1.05)*freqAudio);
        
        % select an onset point for the chunk window
        onset = onset2;
        
        % define different offset points
        offset1 = onset + .65*freqAudio;
        offset2 = onset + .8*freqAudio;
        offset3 = onset + .9*freqAudio;
        
        % select an offset point for the chunk window
        offset = offset1;
        
        audio = wavread([dirMain strtok(logList(fileNr).name, '.') ...
            '_1.wav'], [onset, offset]);
        
        % Fill the audio playback buffer with the audio data:
        PsychPortAudio('FillBuffer', pahandle, audio(:,1)');
        
        %% filter the audio, get the spectrogramm
        audioFilter1 = filtfilt(b1,a1, audio(:,1));
        %audioFilter2 = filtfilt(b2,a2, audio(:,1));
        
        %% plot the data
        figure('Name', [strtok(logList(fileNr).name, '.') ', Trial ' ...
            num2str(trialNr)], 'units', 'normalized', 'outerposition', ...
            [0 0 1 1], 'NumberTitle', 'off');
        subplot(2,1,1), plot(audioFilter1);
        axis tight;
        title(['Response: ' response{trialNr}], ...
            'Color', 'black', 'FontSize', 26, 'FontAngle',  'oblique')
        set(gca,'FontSize',18)
        
        subplot(2,1,2)
        spgrambw(audio(:,1), freqAudio, 'i', 400, 1500, 30);
        %axis tight;
        title('Spectrogram', 'FontSize', 26, 'FontAngle',  'oblique')
        ylabel('Frequency (kHz)','FontSize', 18)
        xlabel('Time (in ms)','FontSize', 18)
        set(gca,'FontSize',18)
%         subplot(3,1,3), spgrambw(audio(:,2), freqAudio, 'i', 400, 1500, 25);
%         % plot(audioFilter2); %  
%         axis tight;
%         title('Distractor', 'FontSize', 14, 'FontAngle',  'oblique')
        
        % play the acoustics of the plotted data
        PsychPortAudio('Start', pahandle, 2, 0, 1);
        
        %fprintf('Total time elapsed: %.2f minutes. \n', timeElap/60);
        % graphical input, n defines the number of points one wants to label
        % ENTER skips a trial without marks and marks it with "NA"
        [markPoints] = ginput(3);
        
        % close all figures
        close all;
        
        %% write output of graphical input to variables
        if markPoints ~= 0
            % get the response's release point
            release = str2double(sprintf('%.4f', markPoints(1))) + onset/freqAudio;
            % get the phonation start
            %phonation = str2double(sprintf('%.4f', markPoints(2))) + onset/freqAudio;
            % compute the response time
            rt = str2double(sprintf('%.3f', release - trialMark(trialNr)));
            % compute the response VOT
            resVot = str2double(sprintf('%.3f', str2double(sprintf('%.4f', markPoints(2))) - ...
                str2double(sprintf('%.4f', markPoints(1)))));
            % compute vowel length
            vowel = str2double(sprintf('%.3f', str2double(sprintf('%.4f', markPoints(3))) - ...
                str2double(sprintf('%.4f', markPoints(2)))));
        else
            release = 'NA';
            %phonation{j} = 'NA';
            resVot = 'NA';
            vowel = 'NA';
            rt = 'NA';
            response{trialNr} = 'NA';
            distCon{trialNr} = 'NA';
            votStep{trialNr} = 'NA';
            soa{trialNr} = 'NA';
        end
                        
        %% write the extracted variables to a xls-file
            if trialNr == 1
                header = {'subject ID' 'gender' 'age' 'origin' 'block' 'trial' ...
                    'response' 'rt' 'response vot' 'vowel length' 'distractor condition' ...
                    'vot step' 'soa' 'release'};
                labels = {subjectID{1} gender{1} age{1} origin{1} trialBlock{trialNr} ...
                    trialNumber{trialNr} response{trialNr} rt resVot vowel distCon{trialNr} votStep{trialNr}...
                    soa{trialNr} release};
                xlswrite([dirData strtok(logList(fileNr).name, '.') '.xlsx'], header, ...
                    sprintf('A%s:N%s', num2str(trialNr),num2str(trialNr)))
                xlswrite([dirData strtok(logList(fileNr).name, '.') '.xlsx'], labels, ...
                    sprintf('A%s:N%s', num2str(trialNr+1),num2str(trialNr+1)))
            else
                labels = {subjectID{1} gender{1} age{1} origin{1} trialBlock{trialNr} ...
                    trialNumber{trialNr} response{trialNr} rt resVot vowel distCon{trialNr} votStep{trialNr}...
                    soa{trialNr} release};
                xlswrite([dirData strtok(logList(fileNr).name, '.') '.xlsx'], labels, ...
                    sprintf('A%s:N%s', num2str(trialNr+1),num2str(trialNr+1)))
            end
        
        % delete procced file from list
        trialTotal = trialTotal - 1;
        % increase trial number
        trialNr = trialNr + 1;
    end
    
    fprintf('Finished file %d from %d. \n', i, length(logList));
    
    % remove procced file from list
    files = files - 1;
    % increase file number
    fileNr = fileNr + 1;
end

timeElap = toc;
fprintf('Finished all files! \n');
fprintf('Total time elapsed: %.2f minutes. \n', timeElap/60);