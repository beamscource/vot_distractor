function distractor_experiment_win (debug)
% distractor_experiment ([debug = 0])
% 
% If debug argument set to 1, only 5 trials will be performed in 3 blocks;
% training trials will be reduced to 4. Experimental window opens in a
% non-full screen mode.
%
% Experiment script for a response-distractor task (with incrementaly
% increasing VOT values of the distractors).
%
% Script written for the MSc project "Phonetic accommodation
% of VOT in a response-distractor task"
% Author: Eugen Klein, February 2014, Update: March 2014, April 2014

clear all;
close all;

% check for optional debug argument
if nargin < 1 
    debug = 0;
else
    debug = 1;
end

% get the index of the USB device (mouse)
[mouseIndex] = GetMouseIndices('masterPointer');

%--------------------------------------------------------------------------
% SET DIRECTORIES
%--------------------------------------------------------------------------

directory=cd('E:\Distractor_experiment\');
directory_data='E:\Distractor_experiment\data\';
directory_texts='E:\Distractor_experiment\texts\';
directory_stimuli='E:\Distractor_experiment\stimuli\';

%--------------------------------------------------------------------------
% INPUT BOX: PARTICIPANT'S DATA
%--------------------------------------------------------------------------

% do not overwrite a file which is already in place
overwrite='N';
% participant's info
id=input('Participant''s ID number: ', 's');

% check if a text file for that ID already exists and create it else
while exist([directory_data 'participant_' num2str(id) '.txt'], 'file') && ...
        overwrite == 'N'
  overwrite=input('File already in place! Overwrite? (Y/N): ', 's');
    if overwrite == 'N'
      id=input('Chose new ID. Participant''s ID number: ', 's');
    else
    end
end

file_number=id;

% create a new txt-file for participant's data
file_name = [directory_data 'participant_' sprintf(id) '.txt'];
txt_file = fopen(file_name, 'w+');

age=input('Participant''s age: ', 's');
sex=input('Participant''s sex (m/w): ', 's');
origin=input('Participant''s birth region (Bundesland): ', 's');
disorders=input('History of speech/hearing disorders? (yes/no): ', 's');
b_response=input('Which syllable corresponds to ##? (ka/ta): ', 's');
symbol_hash=b_response;

% convert the scalar input to cells
id=cellstr(id); age=cellstr(age); sex=cellstr(sex); origin=cellstr(origin); ...
disorders=cellstr(disorders); b_response=cellstr(b_response);

% transpose participant's info to column vectors
id=id'; age=age'; sex=sex'; origin=origin'; disorders=disorders'; ...
b_response=b_response';

%--------------------------------------------------------------------------
% READ THE DISPLAY-INFO TEXTS
%--------------------------------------------------------------------------

% read the welcome text file
welcome = fopen([directory_texts 'welcome.m'], 'rt');
    if welcome==-1
        error('Could not open welcome.m file.');
    end
    
welcome_text = '';
    while ~feof(welcome)
        welcome_text = [welcome_text, fgets(welcome)];
    end
fclose(welcome);

% read the text file for response_cue combination depending on b_response
if symbol_hash == 'ta';
    symbol = fopen([directory_texts 'hash_cue.m'], 'rt');
    if symbol==-1
        error('Could not open hash_cue.m file.');
    end
else    
    symbol = fopen([directory_texts 'stars_cue.m'], 'rt');
    if symbol==-1
        error('Could not open stars_cue.m file.');
    end
end    
    
symbol_text = '';
    while ~feof(symbol)
        symbol_text = [symbol_text, fgets(symbol)];
    end
fclose(symbol);

% read get ready text
get_ready = fopen([directory_texts 'get_ready.m'], 'rt');
    if get_ready==-1
       error('Could not open get_ready.m file.');
    end
    
get_ready_text = '';
    while ~feof(get_ready)
        get_ready_text = [get_ready_text, fgets(get_ready)];
    end
fclose(get_ready);

% read training ends text
training_end = fopen([directory_texts 'training_end.m'], 'rt');
    if training_end==-1
        error('Could not open training_end.m file.');
    end
    
training_end_text = '';
    while ~feof(training_end)
        training_end_text = [training_end_text, fgets(training_end)];
    end
fclose(training_end);

% read start experiment text
start_exp = fopen([directory_texts 'start_exp.m'], 'rt');
    if start_exp==-1
        error('Could not open start_exp.m file.');
    end
    
start_exp_text = '';
    while ~feof(start_exp)
        start_exp_text = [start_exp_text, fgets(start_exp)];
    end
fclose(start_exp);

% read text about a block break
block_break = fopen([directory_texts 'block_break.m'], 'rt');
    if  block_break==-1
        error('Could not open block_break.m file.');
    end
    
block_break_text = '';
    while ~feof(block_break)
        block_break_text = [block_break_text, fgets(block_break)];
    end
fclose(block_break);
    
% read text about last block of the experiment
last_block = fopen([directory_texts 'last_block.m'], 'rt');
    if  last_block==-1
        error('Could not open last_block.m file.');
    end
    
last_block_text = '';
    while ~feof(last_block)
        last_block_text = [last_block_text, fgets(last_block)];
    end
fclose(last_block);

% read text about next block of the experiment
next_block = fopen([directory_texts 'next_block.m'], 'rt');
    if  next_block==-1
        error('Could not open next_block.m file.');
    end
    
next_block_text = '';
    while ~feof(next_block)
        next_block_text = [next_block_text, fgets(next_block)];
    end
fclose(next_block);
        
% read text about the of the experiment
exp_end = fopen([directory_texts 'end_exp.m'], 'rt');
    if  exp_end==-1
        error('Could not open end_exp.m file.');
    end
    
exp_end_text = '';
    while ~feof(exp_end)
        exp_end_text = [exp_end_text, fgets(exp_end)];
    end
fclose(exp_end);

%--------------------------------------------------------------------------
% LOAD AUDIO DATA
%--------------------------------------------------------------------------

% get distractor files
% length of the distractor stimuli list (with tone)
dist_length=10;
for i = 1:dist_length
    [y_dist{i}, fr_dist] = wavread([directory_stimuli 'dist_' num2str(i) '.wav']);
    dist{i} = y_dist{i}';
    % Number of rows == number of channels.
    nrchannels_dist = size(dist{i},1);
end    

% get beep file
[y_beep, fr_beep] = wavread('E:\Distractor_experiment\stimuli\beep.wav');
beep = y_beep';
nrchannels_beep = size(beep,1); % Number of rows == number of channels.

%--------------------------------------------------------------------------
% STIMULI STRUCTURE ARRAY FOR THE PRESENTATION
%--------------------------------------------------------------------------

% response symbols
symbol=[{'##'},{'**'}]; % 2
symbol_dist_comb=repmat(symbol, 1, dist_length); % 10 x 2 = 20
symbol_dist_comb=[symbol_dist_comb, fliplr(symbol_dist_comb)]; % 20 x 2

% VOT steps from 40 to 120 in 10-msces steps
dist_step=[{'t'} {40,50,60,70,80,90,100,110,120}];

% number of repetitions for each distractor/response combination per block
nb_repetitions=4;

% SOA conditions
soa=[0.1, 0.2];
% get SOA conditions to the length of 40 x nb_repetition
soa_list=repmat(soa, 1,(length(symbol_dist_comb)*nb_repetitions)/2);
soa_list=[soa_list, zeros(1,4)];

% get the repetitions of response x distractor x SOA combination
responsesym_list=repmat(symbol_dist_comb, 1, nb_repetitions);
ressymlist_length=length(responsesym_list);
responsesym_list=[responsesym_list, repmat(symbol, 1, 2)];

% distractor step array
dist_list=repmat(dist_step, 1, ressymlist_length/dist_length);
dist_list=[dist_list, repmat({'n'},1,4)];
length_dl=length(dist_list);

% stimuli structure array with 44 structures containing each 3 elements:
% Response_symbol, Distractor, SOA
for i=1:length_dl
    stimuli_struct(i) = struct('Response_symbol', responsesym_list(i), ...
        'Distractor', dist_list(i), 'SOA', soa_list(i));
end

%number of the stimuli items contained in the stimuli array
trial=length(stimuli_struct);

%--------------------------------------------------------------------------
% PSYCHPORTAUDIO SET-UP
%--------------------------------------------------------------------------

% audio driver latency
suggestedLatencySecs = 0.542;

% initialize driver; request low-latency preinit:
InitializePsychSound(1);

if debug == 1
    PsychPortAudio('Verbosity', 10);
end

% force GetSecs and WaitSecs into memory to avoid latency later on:
GetSecs;
WaitSecs(0.1);

% prepare distractor playback        
% open playback channels
dist_handle = PsychPortAudio('Open', [], [], 0, fr_dist, nrchannels_dist, [], ...
    suggestedLatencySecs);

% prepare beep playback        
% open playback channel
beep_handle = PsychPortAudio('Open', [], [], 0, fr_beep, nrchannels_beep, [], ...
    suggestedLatencySecs);
% fill the audio playback buffer with the beep:
PsychPortAudio('FillBuffer', beep_handle, beep);

% prepare the voice trigger (low-latency mode (=2);
% only one handle possible in mode 2
freq = 44100;
% set voice trigger level
triggerlevel = 0.1;
% open audio channel for voice trigger
trigger_handle = PsychPortAudio('Open', [], 2, 2, freq, 2, [], 0.02);

% perform one warmup trial, to get the sound hardware fully up and running,
% performing whatever lazy initialization only happens at real first use.
PsychPortAudio('Start', beep_handle, 1);
PsychPortAudio('Stop', beep_handle, 1);

%--------------------------------------------------------------------------
% SCREEN SET-UP
%--------------------------------------------------------------------------

try

Priority(2); %priotize PTB

gpuPerformance = 10; % highest GPU performance
PsychGPUControl('SetGPUPerformance', gpuPerformance);

% colors for the screen
black = [0 0 0];
%white = [255 255 255];
grey = [204 204 204];

% get the id of the 'highest' useable screen
screen_id = max(Screen('Screens'));

if debug == 1
    % open Screen at the following size
    width = 980;
    height = 700;
    [window, windowRect] = Screen('OpenWindow', screen_id, grey, [0 0 width height]);
    Screen('Preference', 'Verbosity', 10);
else
    % open full screen
    [window, windowRect] = Screen('OpenWindow', screen_id, grey);
end

% get center coordinates of the screen
[xCenter, yCenter] = RectCenter(windowRect);

% inter flip interval (refresh rate)
ifi = Screen('GetFlipInterval', window); 

% number of frames within 2*audio driver latency
waitframes = ceil((suggestedLatencySecs*2) / ifi) + 1;

% select specific text font, style and size for the text/cue
Screen('TextFont',window, 'Arial');
Screen('TextSize',window, 54);
% Screen('TextStyle', window, 2);

% get the x/y dimensions of the visual cue ##
hash_width = RectWidth(Screen('TextBounds',window, ...
    stimuli_struct(1).Response_symbol));
hash_height = RectHeight(Screen('TextBounds',window, ...
    stimuli_struct(1).Response_symbol));

% get the x/y dimensions of the visual cue **
stars_width = RectWidth(Screen('TextBounds',window, ...
    stimuli_struct(2).Response_symbol));
stars_height = RectHeight(Screen('TextBounds',window, ...
    stimuli_struct(2).Response_symbol));

%--------------------------------------------------------------------------
% FIXATION CROSS SIZE/COORDINATES
%--------------------------------------------------------------------------

% size of the arms of the fixation cross
fixCrossDimPix = 15;

% line width for the fixation cross
lineWidthPix = 5;

% coordinates for two lines of the cross
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

%--------------------------------------------------------------------------
% WELCOME TEXT
%--------------------------------------------------------------------------

Screen('TextSize',window, 24);

DrawFormattedText(window, welcome_text, 'center', 'center', [], [], [], [], 2);
Screen('Flip', window);
KbWait(mouseIndex); % wait for user's input to continue

%--------------------------------------------------------------------------
% SYMBOL==SYLLABLE TEXT
%--------------------------------------------------------------------------

DrawFormattedText(window, symbol_text, 'center', 'center', [], [], [], [], 2);
Screen('Flip', window);
WaitSecs(0.5);
KbWait(mouseIndex); % wait for user's input to continue

%--------------------------------------------------------------------------
% GET READY TEXT
%--------------------------------------------------------------------------

DrawFormattedText(window, get_ready_text, 'center', 'center', [], [], [], [], 2);
Screen('Flip', window); % display "Bereite Dich vor!"
WaitSecs(1);

%--------------------------------------------------------------------------
% TRAINING TRIALS LOOP
%--------------------------------------------------------------------------

if debug == 1
    % number of training trials
    training_trials = 4; 
else
    % number of training trials
    training_trials = 8; 
end

% preallocating variables
training_rt  = zeros(1,training_trials);

%set font size for the visual cue
Screen('TextSize', window, 54);

for i = 1:training_trials
    
    %randomization of the array items order by random index permutation
    index=randperm(trial);
    stimuli_struct=stimuli_struct(index);
    
    % draw the fixation cross
    Screen('DrawLines', window, allCoords, lineWidthPix, black, [xCenter yCenter]);
        
    % fill the audio playback buffer with the distractor:
    switch stimuli_struct(i).Distractor % choose VOT condition
        case 't' % tone condition
            PsychPortAudio('FillBuffer', dist_handle, dist{1});
        case 40
            PsychPortAudio('FillBuffer', dist_handle, dist{2});
        case 50
            PsychPortAudio('FillBuffer', dist_handle, dist{3});
        case 60
            PsychPortAudio('FillBuffer', dist_handle, dist{4});
        case 70
            PsychPortAudio('FillBuffer', dist_handle, dist{5});
        case 80
            PsychPortAudio('FillBuffer', dist_handle, dist{6});
        case 90
            PsychPortAudio('FillBuffer', dist_handle, dist{7});
        case 100
            PsychPortAudio('FillBuffer', dist_handle, dist{8});
        case 110
            PsychPortAudio('FillBuffer', dist_handle, dist{9});
        case 120
            PsychPortAudio('FillBuffer', dist_handle, dist{10});
        otherwise
    end
    
    % display fixation cross
    [vbl, cross_onset] = Screen('Flip', window);
    
    % prepare visual cue
    if stimuli_struct(i).Response_symbol == '##'
        Screen('DrawText',window, stimuli_struct(i).Response_symbol, ... 
        xCenter-hash_width/2, yCenter-hash_height/2);
    else
        Screen('DrawText',window, stimuli_struct(i).Response_symbol, ... 
        xCenter-stars_width/2, yCenter-stars_height/2);
    end
                    
    % play distractor
    if i > training_trials/2
        % check if there is a distractor
        if stimuli_struct(i).Distractor ~= 'n'
            dist_onset = PsychPortAudio('Start', dist_handle, 1, ...
                cross_onset + waitframes * ifi + stimuli_struct(i).SOA, 0);
        else
            dist_onset=0;
        end
    else
        dist_onset=0;
    end
    
    % play beep
    beep_onset = PsychPortAudio('Start', beep_handle, 1, ...
        cross_onset + waitframes * ifi, 0);
    
    % display visual cue    
    cue_onset = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    Screen('FillRect', window, grey);
        
    % set voice capture level    
    level = 0;
    % start the audio capturing for VOICE TRIGGER with a buffer of 
    % 10 seconds
    PsychPortAudio('GetAudioData', trigger_handle, 10);
    PsychPortAudio('Start', trigger_handle, 0, 0, 1);
    
    % repeat as long as below trigger-threshold:
    while level < triggerlevel
        % fetch current audiodata:
        [audiodata, offset, overflow, tCaptureStart] = ...
            PsychPortAudio('GetAudioData', trigger_handle);
        % compute maximum signal amplitude in this chunk of data:
        if ~isempty(audiodata)
            level = max(abs(audiodata(1,:)));
        else
            level = 0;
        end
        
        % below trigger-threshold?
        if level < triggerlevel
            % wait for five milliseconds before next scan:
            WaitSecs(0.005);
        end
    end
    
    % Ok, last fetched chunk was above threshold!
    % find exact location of first above threshold sample.
    idx = min(find(abs(audiodata(1,:)) >= triggerlevel));
    % compute absolute event time for the response:
    response_onset = tCaptureStart + ((offset + idx - 1) / freq);
    % stop sound capture:
    PsychPortAudio('Stop', trigger_handle);
    % fetch all remaining audio data out of the buffer - 
    % needs to be empty before next trial:
    PsychPortAudio('GetAudioData', trigger_handle);
    % stop beep
    PsychPortAudio('Stop', beep_handle);
            
    % display white screen once response is detected
    Screen('Flip', window);
    % stop distractor
    if dist_onset ~= 0
        PsychPortAudio('Stop', dist_handle);
    else
    end
    
    % time for the answer: 1 second
    WaitSecs(1); 
        
    % get training response time
    training_rt(i)=(response_onset - cue_onset)*1000;
end

% mean reference time for the feedback after the first experimental block
reference_rt=mean(training_rt);

%--------------------------------------------------------------------------
% TRAINING FINISHED TEXT
%--------------------------------------------------------------------------

%set font size for the info texts
Screen('TextSize', window, 24);

DrawFormattedText(window, training_end_text, 'center', 'center', [], [], [], [], 2);
Screen('Flip', window);
KbWait(mouseIndex); % wait for user's input to continue
        
%--------------------------------------------------------------------------
% EXPERIMENT STARTING TEXT
%--------------------------------------------------------------------------

DrawFormattedText(window, start_exp_text, 'center', 'center', [], [], [], [], 2);
Screen('Flip', window);
WaitSecs(1);

%--------------------------------------------------------------------------
% SYMBOL==SYLLABLE TEXT FOR EXPERIMENT
%--------------------------------------------------------------------------

DrawFormattedText(window, symbol_text, 'center', 'center', [], [], [], [], 2);
Screen('Flip', window);
KbWait(mouseIndex); % wait for user's input to continue

%--------------------------------------------------------------------------
% GET READY TEXT
%--------------------------------------------------------------------------

DrawFormattedText(window, get_ready_text, 'center', 'center', [], [], [], [], 2);
Screen('Flip', window);
WaitSecs(1);

%--------------------------------------------------------------------------
% OUTER BLOCK LOOP
%--------------------------------------------------------------------------

if debug == 1
    % number of blocks for the experiment
    block=3;
    % number of test trials (for debbuging)
    trial=5;
    
    % prelocating variables for synchronization data
    cue_beep = zeros(1);
    beep_dist = zeros(1);
    cue_dist = zeros(1);
    cross_cue = zeros(1);
else
    block=4;
    % trial=length(stimuli_struct); as defined in line 243
end

% create variables for trial data
trial_id = cell(1);
visual_cue = cell(1);
vot_step = cell(1);
SOA = cell(1);
rt = cell(1);
cue_beep_delay = cell(1);
cue_dist_delay = cell(1);
block_id=cell(1);
    
% transpose all trial data vectors 
trial_id=trial_id'; visual_cue=visual_cue'; vot_step=vot_step'; SOA=SOA'; ...
rt=rt'; cue_beep_delay=cue_beep_delay'; cue_dist_delay=cue_dist_delay'; ...
block_id=block_id';
   
for j=1:block 
    %randomization of the array items order by random index permutation
    index=randperm(trial);
    stimuli_struct=stimuli_struct(index);
    
    %set font size for the visual cue
    Screen('TextSize', window, 54);
    
    % INNER TRIAL LOOP
    for i=1:trial
    
    % draw the fixation cross
    Screen('DrawLines', window, allCoords, lineWidthPix, black, [xCenter yCenter]);
    
    % fill the audio playback buffer with the distractor:
    switch stimuli_struct(i).Distractor % choose VOT step
        case 't' % tone condition
            PsychPortAudio('FillBuffer', dist_handle, dist{1});
        case 40
            PsychPortAudio('FillBuffer', dist_handle, dist{2});
        case 50
            PsychPortAudio('FillBuffer', dist_handle, dist{3});
        case 60
            PsychPortAudio('FillBuffer', dist_handle, dist{4});
        case 70
            PsychPortAudio('FillBuffer', dist_handle, dist{5});
        case 80
            PsychPortAudio('FillBuffer', dist_handle, dist{6});
        case 90
            PsychPortAudio('FillBuffer', dist_handle, dist{7});
        case 100
            PsychPortAudio('FillBuffer', dist_handle, dist{8});
        case 110
            PsychPortAudio('FillBuffer', dist_handle, dist{9});
        case 120
            PsychPortAudio('FillBuffer', dist_handle, dist{10});
        otherwise
    end
    
    % display the fixation cross
    [vbl, cross_onset] = Screen('Flip', window);
    
    % prepare visual cue
    if stimuli_struct(i).Response_symbol == '##'
        Screen('DrawText',window, stimuli_struct(i).Response_symbol, ... 
        xCenter-hash_width/2, yCenter-hash_height/2);
    else
        Screen('DrawText',window, stimuli_struct(i).Response_symbol, ... 
        xCenter-stars_width/2, yCenter-stars_height/2);
    end
                    
    % play distractor                
    % check if there is a distractor
    if stimuli_struct(i).Distractor ~= 'n'
        [dist_onset]= PsychPortAudio('Start', dist_handle, 1, ...
        cross_onset + waitframes * ifi + stimuli_struct(i).SOA, 0);
    else
        dist_onset=0;
    end
    
    % play beep
    [beep_onset] = PsychPortAudio('Start', beep_handle, 1, ...
        cross_onset + waitframes * ifi, 0);
    
    % display visual cue    
    [cue_onset] = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    % prepare grey transition
    Screen('FillRect', window, grey);
        
    % set voice capture level    
    level = 0;
    % start the audio capturing for voice trigger with a buffer of 
    % 10 seconds
    PsychPortAudio('GetAudioData', trigger_handle, 10);
    PsychPortAudio('Start', trigger_handle, 0, 0, 1);
    
    % repeat as long as below trigger-threshold:
    while level < triggerlevel
        % fetch current audiodata:
        [audiodata, offset, overflow, tCaptureStart] = ...
            PsychPortAudio('GetAudioData', trigger_handle);
        % compute maximum signal amplitude in this chunk of data:
        if ~isempty(audiodata)
            level = max(abs(audiodata(1,:)));
        else
            level = 0;
        end
        
        % below trigger-threshold?
        if level < triggerlevel
            % wait for five milliseconds before next scan:
            WaitSecs(0.005);
        end
    end
    
    % Ok, last fetched chunk was above threshold!
    % find exact location of first above threshold sample.
    idx = min(find(abs(audiodata(1,:)) >= triggerlevel));
    % compute absolute event time for the response:
    response_onset = tCaptureStart + ((offset + idx - 1) / freq);
    % stop sound capture:
    PsychPortAudio('Stop', trigger_handle);
    % fetch all remaining audio data out of the buffer - 
    % needs to be empty before next trial:
    PsychPortAudio('GetAudioData', trigger_handle);
    % stop beep
    PsychPortAudio('Stop', beep_handle);
            
    % display white screen once response is detected
    Screen('Flip', window);
    % stop distractor
    if dist_onset ~= 0
        PsychPortAudio('Stop', dist_handle);
    else
    end
    
    % time for the answer: 1 second
    WaitSecs(1); 
        
%--------------------------------------------------------------------------
% STORE TRIAL DATA
%--------------------------------------------------------------------------

    % block id
    block_id=num2cell(j);
    % trial id
    trial_id=num2cell(i);
    % visual cue
    visual_cue=cellstr(stimuli_struct(i).Response_symbol);
    % which distractor
    vot_step=num2cell(stimuli_struct(i).Distractor);
    % SOA condition
    SOA=num2cell(stimuli_struct(i).SOA);
    % response time (RT)
    rt=num2cell((response_onset - cue_onset)*1000);
    % delay between visual cue and beep
    cue_beep_delay=num2cell((cue_onset - beep_onset)*1000);
    % delay between visual cue and distractor
    cue_dist_delay=num2cell((cue_onset - dist_onset)*1000);
    
    % combine all column vectors to one big array
    data_frame=[id age sex origin disorders b_response block_id trial_id ...
        visual_cue vot_step SOA rt cue_beep_delay cue_dist_delay];

    % append to the participant's txt file
    cellwrite(file_name, data_frame);
    
    if debug == 1
%--------------------------------------------------------------------------
% STORE DATA FOR AUDIO-VIDEO SYNCHRONIZATION TESTS
%--------------------------------------------------------------------------

    % testing beep and visual cue synchronization 
    cue_beep(i)=(cue_onset - beep_onset)*1000;

    % testing distractor and beep synchronization
    % check for no-distractor conditions
    if stimuli_struct(i).Distractor ~= 'n'
        beep_dist(i)=(dist_onset - beep_onset)*1000;    
    else
        beep_dist(i)=0;
    end

    % testing distractor and cue synchronization
    % check for no-distractor conditions
    if stimuli_struct(i).Distractor ~= 'n'
        cue_dist(i)=(dist_onset - cue_onset)*1000;    
    else
        cue_dist(i)=0;
    end
    
    % testing fixation cross and visual cue synchronization
    cross_cue(i)=(cue_onset - cross_onset);
    else
    end
    end % end of the INNER TRIAL LOOP

    if debug == 1
%--------------------------------------------------------------------------
% AUDIO-VIDEO SYNCHRONIZATION PLOTS
%--------------------------------------------------------------------------

    %plot distractor delay to cue onset
    figure
    bar(cue_dist)
    ylabel('\delta(Visual cue to Distractor delay) [ms]')
    xlabel('Trial number')
    title('Distractor to visual cue delay')
    
    % plot beep delay to visual cue onset
    figure
    bar(cue_beep)
    ylabel('\delta(Beep to visual cue delay) [ms]')
    xlabel('Trial number')
    title('Beep to visual cue delay')

    % plot visual cue to fixation cross delay
    figure
    bar(cross_cue)
    ylabel('\delta(Fixation cross to visual cue delay) [ms]')
    xlabel('Trial number')
    title('Visual cue to fixation cross delay')
    
    %plot distractor delay to beep onset
    figure
    bar(beep_dist)
    ylabel('\delta(Beep to distractor delay) [ms]')
    xlabel('Trial number')
    title('Distractor to beep delay')

    else
    end
%--------------------------------------------------------------------------
% BLOCK END TEXT
%--------------------------------------------------------------------------

Screen('TextSize', window, 24);

if j < block
    % draw and display text
    DrawFormattedText(window, block_break_text, 'center', 'center', [], [], [], [], 2);
    Screen('Flip', window);
    KbWait(mouseIndex); % wait for user's input to continue

% -------------------------------------------------------------------------    
% LAST/NEXT BLOCK TEXT    
% -------------------------------------------------------------------------

if j == block-1
    % draw and display text
    DrawFormattedText(window, last_block_text, 'center', 'center', [], [], [], [], 2);
    Screen('Flip', window); % display "Get ready for the last block!"
    WaitSecs(2);
else
    % draw and display text
    DrawFormattedText(window, next_block_text, 'center', 'center', [], [], [], [], 2);
    Screen('Flip', window); % display "Get ready for the next block!"
    WaitSecs(2);
end
    
% -------------------------------------------------------------------------
% EXPERIMENT END TEXT    
% -------------------------------------------------------------------------

else    
    %draw and display text
    DrawFormattedText(window, exp_end_text, 'center', 'center', [], [], [], [], 2);
    Screen('Flip', window); % display "You're done!"
end
end % end of the OUTER BLOCK LOOP

KbWait(mouseIndex);

Screen('CloseAll');
PsychPortAudio('Close');

%--------------------------------------------------------------------------
% check data txt contents
%--------------------------------------------------------------------------

data = fileread([directory_data 'participant_' num2str(file_number) '.txt']);
if ~isempty(data)
    fprintf ('Data was saved under %s, %s! \n', directory_data, file_name)
else
    fprintf('Screwed up! Couldn''t save data! Check data_frame on \n the console manually. \n')
end

catch
    Screen('CloseAll')
    rethrow(lasterror)
end
