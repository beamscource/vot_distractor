function distractor_main
% Experiment script for a response-distractor task.
% Author: Eugen Klein, June 2014

global i;

clear all, close all;

% get the indexes of the poiter devices (mouse)
[mouseIndex] = GetMouseIndices;

%--------------------------------------------------------------------------
% SET DIRECTORIES
%--------------------------------------------------------------------------

% dirMain = ('/home/emalab/DistrEyetracking');
dirMain = pwd;
dirTable = [dirMain '/table/'];
dirText = [dirMain '/txt/'];
dirAudio = [dirMain '/audio/'];
dirFun = [dirMain '/fun/'];
dirEyeTr = [dirMain '/et/'];
cd(dirFun)

%--------------------------------------------------------------------------
% add directories to search path
%--------------------------------------------------------------------------
addpath(dirEyeTr);

%--------------------------------------------------------------------------
% INPUT BOX: PARTICIPANT'S DATA
%--------------------------------------------------------------------------
 
[fileNumber fileName symbolHash id block age sex origin disorders ...
    basRespons] = inputBox(dirTable);

% set seed of random number generator
seed = 3246523+100*str2num(char(id))+str2num(char(block));
rand('twister',seed); % use rng() in later versions
% rng(seed,'twister'); 

%--------------------------------------------------------------------------
% READ THE DISPLAY-INFO TEXTS
%--------------------------------------------------------------------------

[welcomeText taskText symbolText trainingEndText blockBreakFirstText ...
    blockBreakSecondText blockBreakThirdText ...
    expEndText] = readText(dirText, symbolHash);

%--------------------------------------------------------------------------
% LOAD AUDIO DATA
%--------------------------------------------------------------------------
session = cell2mat(block);

if session == '1'
    % get distractor files
    [y_dist] = wavread([dirAudio 'da.wav']);
    dist{1} = y_dist';

    [y_dist] = wavread([dirAudio 'ga.wav']);
    dist{2} = y_dist';
    
elseif session == '2'
    % get distractor files
    [y_dist] = wavread([dirAudio 'ta_norm.wav']);
    dist{1} = y_dist';

    [y_dist] = wavread([dirAudio 'ta_long.wav']);
    dist{2} = y_dist';
else
    fprintf('No session number chosen.\n')
    return
end

[y_dist, frDist] = wavread([dirAudio 'tone.wav']);
dist{3} = y_dist';

% Number of rows == number of channels.
nrchannelsDist = size(dist{1},1);
    
% get marker file
[y_marker, fr_marker] = wavread([dirAudio 'marker.wav']);
marker = y_marker';

%--------------------------------------------------------------------------
% PSYCHPORTAUDIO SET-UP
%--------------------------------------------------------------------------

[distHandle triggerHandle freqTrigg triggerLevel suggestedLatencySecs] = ...
    audioSetup(frDist, nrchannelsDist);

% fill the audio playback buffer with the marker:
PsychPortAudio('FillBuffer', distHandle, marker);

% perform one warmup trial, to get the sound hardware fully up and running,
% performing whatever lazy initialization only happens at real first use.
PsychPortAudio('Start', distHandle, 1);
PsychPortAudio('Stop', distHandle, 1);

%--------------------------------------------------------------------------
% STIMULI STRUCTURE ARRAY FOR THE PRESENTATION
%--------------------------------------------------------------------------

if session == '1'
    [trial stimuliStruct] = structBlock1();
else
    [trial stimuliStruct] = structBlock2();
end

%--------------------------------------------------------------------------
% INITIAL CALIBRATION WITH EYE VIDEO ON SHÙBJECT SCREEN
%--------------------------------------------------------------------------

system('C:\Programme\SR Research\EyeLink\bin\track.exe');

%--------------------------------------------------------------------------
% SCREEN SET-UP
%--------------------------------------------------------------------------

try

[grey black window xCenter yCenter hashWidth hashHeight starsWidth starsHeight ...
    waitFrames ifi] = screenSetup(suggestedLatencySecs, stimuliStruct);

%--------------------------------------------------------------------------
% INITIALIZE EYETRACKER (EYELINK)
%--------------------------------------------------------------------------
const.id    = str2num(cell2mat(id));
const.block = str2num(cell2mat(block));
const.bgCol = black;
const.fgCol = grey;
[el, error]=initEyelink(const,window);
if error==el.TERMINATE_KEY
    return
end

% hide cursor
if Eyelink('IsConnected') == el.connected
    HideCursor;
end

% write general info to edf file
Eyelink('Message',['General Info' ])
Eyelink('Message',['Id ' char(id) ' Block ' char(block) ' Condition ' char(basRespons)]);
Eyelink('Message',['Age ' char(age) ' Gender ' char(sex) ' Origin ' char(origin) ' Disorders ' char(disorders)]);
Eyelink('Message',['Seed ' num2str(seed) ' Filename ' char(fileName)])

%--------------------------------------------------------------------------
% FIXATION CROSS SIZE/COORDINATES
%--------------------------------------------------------------------------
[allCoords lineWidthPix] = fixCross();

%--------------------------------------------------------------------------
% WELCOME TEXT
%--------------------------------------------------------------------------

Screen('TextSize', window, 24);

DrawFormattedText(window, double(welcomeText), 'center', 'center', grey, [], [], [], 2);
Screen('Flip', window);
%WaitSecs(3);
KbWait(max(mouseIndex)); % wait for user's input to continue

%--------------------------------------------------------------------------
% TASK TEXT
%--------------------------------------------------------------------------

Screen('TextSize', window, 24);

%DrawFormattedText(window, double(task_text), 100, 'center', grey, [], [], [], 2);
%Screen('Flip', window);
%fprintf('Task description displayed.\n')
%KbWait(max(mouseIndex)); % wait for user's input to continue

%--------------------------------------------------------------------------
% SYMBOL==SYLLABLE TEXT
%--------------------------------------------------------------------------

DrawFormattedText(window, double(symbolText), 'center', 'center', grey, [], [], [], 2);
PsychPortAudio('FillBuffer', distHandle, dist{3});
Screen('Flip', window);
WaitSecs(0.5);

KbWait(max(mouseIndex)); % wait for user's input to continue

% mark the start of the training
PsychPortAudio('Start', distHandle, 1);
Screen('Flip', window);
WaitSecs(1);
PsychPortAudio('Stop', distHandle);

%--------------------------------------------------------------------------
% TRAINING TRIALS LOOP
%--------------------------------------------------------------------------
Eyelink('Message','TrainingStart');

% number of training trials
trainingTrials = 24
%randomization of the array items order by random index permutation
index = randperm(trial);
stimuliStructRand = stimuliStruct(index);

%set font size for the visual cue
Screen('TextSize', window, 78);
nCal=100; % counter - last calibration
for i = 1:trainingTrials
    nCal=nCal+1;
    
    if i == 1
        fprintf('Training started.\n')
    else
    end
    
    % fill the audio playback buffer with the marker:
    PsychPortAudio('FillBuffer', distHandle, marker);
    
    % play marker to mark start of trial
    PsychPortAudio('Start', distHandle, 1);
    
    % fixation check
    [fix,nCal]=fixationCheck(const,el,window,nCal,i,xCenter,yCenter);
    
    % draw the fixation cross
    Screen('DrawLines', window, allCoords, lineWidthPix, grey, [xCenter yCenter]);
    
    % display fixation cross
    [vblCross, crossOnset] = Screen('Flip', window);
    
    % prepare visual cue
    if stimuliStructRand(i).resSymbol == '##'
        Screen('TextSize', window, 38);
        Screen('DrawText', window, stimuliStructRand(i).resSymbol, ... 
        xCenter-hashWidth/2, yCenter-hashHeight/2);
    else
        Screen('TextSize', window, 76);
        Screen('DrawText', window, stimuliStructRand(i).resSymbol, ... 
        xCenter-starsWidth/2, yCenter-(1*starsHeight/3));
    end
    Screen('TextSize', window, 24);
    
    % play marker
    PsychPortAudio('Start', distHandle, 1, crossOnset + waitFrames * ifi, 0);
    
    % display visual cue    
    [vblCue, cueOnset] = Screen('Flip', window, vblCross + (waitFrames - 0.5) * ifi);
    Screen('FillRect', window, black);
    
    % Spin-Wait until hw reports the first sample is played...
    offset = 0;
    while offset == 0
        status = PsychPortAudio('GetStatus', distHandle);
        offset = status.PositionSecs;
        plat = status.PredictedLatency;
        fprintf('Predicted Latency: %6.6f msecs.\n', plat*1000);
        if offset>0
            break;
        end
        WaitSecs('YieldSecs', 0.001);
    end
    markerOnset = status.StartTime;
    
    %stop marker
    %PsychPortAudio('Stop', pa_handle);
    
    fprintf('Screen    expects visual onset at %6.6f secs.\n', cueOnset);
    fprintf('PortAudio expects audio onset  at %6.6f secs.\n', markerOnset);
    fprintf('Expected audio-visual delay    is %6.6f msecs.\n', (markerOnset - cueOnset)*1000.0);
    
    if session == '1'
        % fill the audio playback buffer with the distractor:
        switch stimuliStructRand(i).distCon 
            case 'da'
                PsychPortAudio('FillBuffer', distHandle, dist{1});
            case 'ga'
                PsychPortAudio('FillBuffer', distHandle, dist{2});
            case 't' % tone condition
                PsychPortAudio('FillBuffer', distHandle, dist{3});  
        end
    else
    % fill the audio playback buffer with the distractor:
        switch stimuliStructRand(i).distCon 
            case 'ta_norm'
                PsychPortAudio('FillBuffer', distHandle, dist{1});
            case 'ta_long'
                PsychPortAudio('FillBuffer', distHandle, dist{2});
            case 't' % tone condition
                PsychPortAudio('FillBuffer', distHandle, dist{3});    
        end
    end
    
    % play distractor
    if i > trainingTrials/3
        % check if there is a distractor
        if stimuliStructRand(i).distCon ~= 'n'
            PsychPortAudio('Start', distHandle, 1, ...
                cueOnset + stimuliStructRand(i).SOA, 0);
        else
        end
    else
    end
    
    [responseOnset] = voiceTrigger(triggerHandle, freqTrigg, triggerLevel);
    
    % clear screen once response is detected
    Screen('Flip', window);
    
    % time for the answer: seconds
    WaitSecs(1.5); 
        
    % stop distractor
    if stimuliStructRand(i).distCon ~= 'n'
        PsychPortAudio('Stop', distHandle);
    else
    end
        
end
Eyelink('Message','TrainingEnd');

%--------------------------------------------------------------------------
% TRAINING FINISHED TEXT
%--------------------------------------------------------------------------

%set font size for the info texts
Screen('TextSize', window, 24);

DrawFormattedText(window, double(trainingEndText), 'center', 'center', grey, [], [], [], 2);
Screen('Flip', window);
fprintf('Training finished.\n')
KbWait(max(mouseIndex)); % wait for user's input to continue
        
%--------------------------------------------------------------------------
% SYMBOL==SYLLABLE TEXT FOR EXPERIMENT
%--------------------------------------------------------------------------

DrawFormattedText(window, double(symbolText), 'center', 'center', grey, [], [], [], 2);
PsychPortAudio('FillBuffer', distHandle, dist{3});
Screen('Flip', window);
WaitSecs(0.5);
KbWait(max(mouseIndex)); % wait for user's input to continue

% mark the start of the experiment
PsychPortAudio('Start', distHandle, 1);
startRecord = GetSecs;
Screen('Flip', window);
fprintf('1 second left until the start of experiment.\n')
WaitSecs(1);
PsychPortAudio('Stop', distHandle);

%--------------------------------------------------------------------------
% BEFORE THE LOOP
%--------------------------------------------------------------------------
Eyelink('Message','ExperimentStart %d %d',const.id,const.block);  
fprintf('Experiment started.\n')
  
%randomization of the array items order by random index permutation
index=randperm(trial);
stimuliStructRand=stimuliStruct(index);
    
%set font size for the visual cue
Screen('TextSize', window, 78);

%--------------------------------------------------------------------------    
% INNER TRIAL LOOP
%--------------------------------------------------------------------------
nCal=100; % counter - last calibration
for i = 1:trial
    % counter - last calibration
    nCal=nCal+1;
    
    % mark zero-plot time in data file
    Eyelink('Message','SYNCTIME');
    
    % fill the audio playback buffer with the marker:
    PsychPortAudio('FillBuffer', distHandle, marker);
    
    % play marker to mark start of trial
    start = GetSecs;
    PsychPortAudio('Start', distHandle, 1);
    Eyelink('Message','TrialStart %s %d',num2str(start + suggestedLatencySecs,'%6.6f'),i);    

    % fixation check
    [fix,nCal]=fixationCheck(const,el,window,nCal,i,xCenter,yCenter);
    
    % draw the fixation cross
    Screen('DrawLines', window, allCoords, lineWidthPix, grey, [xCenter yCenter]);
    
    % display fixation cross
    [vblCross, crossOnset] = Screen('Flip', window);
    Eyelink('Message','FixCrossOnset %s %d',num2str(crossOnset,'%6.6f'),i);    
    
    % prepare visual cue
    if stimuliStructRand(i).resSymbol == '##'
        Screen('TextSize', window, 38);
        Screen('DrawText', window, stimuliStructRand(i).resSymbol, ... 
        xCenter-hashWidth/2, yCenter-hashHeight/2);
    else
        Screen('TextSize', window, 76);
        Screen('DrawText', window, stimuliStructRand(i).resSymbol, ... 
        xCenter-starsWidth/2, yCenter-(1*starsHeight/3));
    end
    Screen('TextSize', window, 24);
    
    % play marker
    PsychPortAudio('Start', distHandle, 1, crossOnset + waitFrames * ifi, 0);
    Eyelink('Message','PlayMarker %s %d',num2str(crossOnset + waitFrames * ifi,'%6.6f'),i);    
    
    % display visual cue    
    [vblCue, cueOnset] = Screen('Flip', window, vblCross + (waitFrames - 0.5) * ifi);
    Eyelink('Message','VisualCueOnset %s %d',num2str(cueOnset,'%6.6f'),i);    
    Screen('FillRect', window, black);
    
    % Spin-Wait until hw reports the first sample is played...
    offset = 0;
    while offset == 0
        status = PsychPortAudio('GetStatus', distHandle);
        offset = status.PositionSecs;
        plat = status.PredictedLatency;
        %fprintf('Predicted Latency: %6.6f msecs.\n', plat*1000);
        if offset>0
            break;
        end
        WaitSecs('YieldSecs', 0.001);
    end
    Eyelink('Message','AudioOnset %s PredictedLatency %d %d',...
        num2str(status.StartTime,'%6.6f'),num2str(round(plat*1000),'%3.5f'),i);
    audioOnset = status.StartTime;
    
   if session == '1'
        % fill the audio playback buffer with the distractor:
        switch stimuliStructRand(i).distCon 
            case 'da'
                PsychPortAudio('FillBuffer', distHandle, dist{1});
            case 'ga'
                PsychPortAudio('FillBuffer', distHandle, dist{2});
            case 't' % tone condition
                PsychPortAudio('FillBuffer', distHandle, dist{3});  
        end
    else
    % fill the audio playback buffer with the distractor:
        switch stimuliStructRand(i).distCon 
            case 'ta_norm'
                PsychPortAudio('FillBuffer', distHandle, dist{1});
            case 'ta_long'
                PsychPortAudio('FillBuffer', distHandle, dist{2});
            case 't' % tone condition
                PsychPortAudio('FillBuffer', distHandle, dist{3});    
        end
    end
        
    % play distractor
    % check if there is a distractor
    if stimuliStructRand(i).distCon ~= 'n'
        PsychPortAudio('Start', distHandle, 1, ...
            cueOnset + stimuliStructRand(i).SOA, 0);
        Eyelink('Message','PlayDistractor 1 %s %d',num2str(cueOnset + stimuliStructRand(i).SOA,'%6.6f'),i);
    else
        Eyelink('Message','PlayDistractor 0 0 %d',i);
    end
        
    [responseOnset] = voiceTrigger(triggerHandle, freqTrigg, triggerLevel);
    Eyelink('Message','ResponseOnset %s %d',num2str(responseOnset,'%6.6f'),i);
                
    % clear screen once response is detected
    Screen('Flip', window);
    
    % time for the answer: seconds
    WaitSecs(2.0);
    
    % stop distractor
    if stimuliStructRand(i).distCon ~= 'n'
        PsychPortAudio('Stop', distHandle);
    else
    end
              
%--------------------------------------------------------------------------
% STORE TRIAL DATA
%--------------------------------------------------------------------------

    % trial id
    trialId = num2cell(i)';
    
    % visual cue
    visualCue = cellstr(stimuliStructRand(i).resSymbol)';
    
    % distractor syllable
    distractor = cellstr(stimuliStructRand(i).distCon)';
    
    % SOA condition
    SOA = num2cell(stimuliStructRand(i).SOA)';
    
    % response time (RT) in sec
    rtSec = num2cell(responseOnset - cueOnset)';
    
    % response time (RT) in msec
    rt = num2cell((responseOnset - cueOnset)*1000.0)';
    
    % start of the response
    release = num2cell(responseOnset - startRecord)';
    
    % start of the trial
    trialStart = num2cell(start - startRecord)';
    
    % marker
    markerStamp = num2cell(cueOnset - startRecord)';
    
    % delay between visual cue and marker
    if (audioOnset - cueOnset)*1000.0 > 0.01
        ca.stack.lineueMarkerDelay = cellstr('missed')';
    else
        cueMarkerDelay = cellstr('hit')';
    end

    Eyelink('Message','TrialSummary RT %s SOA %s visCue %s Distractor %s CueMarkerDelay %s %d',...
        num2str(cell2mat(rt),'%3.0f'),num2str(1000*cell2mat(SOA),'%3.0f'),char(visualCue),char(distractor),char(cueMarkerDelay),i);
        
    % combine all column vectors to one big array
    dataFrame=[id block age sex origin disorders basRespons trialId ...
        trialStart markerStamp visualCue distractor SOA rtSec ...
        release rt cueMarkerDelay];
    
    % append to the participant's txt file
    cellwrite(fileName, dataFrame);

    % trial end
    Eyelink('Message','TrialEnd %d',i);
end % end of the TRIAL LOOP
Eyelink('Message','ExperimentEnd');

%--------------------------------------------------------------------------
% SESSION END TEXT
%--------------------------------------------------------------------------

Screen('TextSize', window, 24);


%draw and display text
DrawFormattedText(window, double(expEndText), 'center', 'center', grey, [], [], [], 2);
Screen('Flip', window); % display "You're done!"
fprintf('Experiment finished. Push any button to close everything.\n')

KbWait;

Screen('CloseAll');
PsychPortAudio('Close');

%--------------------------------------------------------------------------
% check data txt contents
%--------------------------------------------------------------------------

data = fileread(fileName);
if ~isempty(data)
    fprintf ('Data was saved under %s, %s! \n', dirTable, fileName)
else
    fprintf('Screwed up! Couldn''t save data! Check data_frame on \n the console manually. \n')
end

catch
    Screen('CloseAll')
    rethrow(lasterror)
    a=lasterror
end

%--------------------------------------------------------------------------
% CLEAN UP: QUIT EYELINK, REMOVE PATHES ETC.
%--------------------------------------------------------------------------
reddUp;
rmpath(dirEyeTr);