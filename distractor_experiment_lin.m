function distractor_experiment_lin (debug)
% distractor_experiment ([debug = 0])
% 
% If debug argument set to 1, only 5 trials will be performed in 3 blocks;
% training trials will be reduced to 4. Experimental window opens in a
% non-full screen mode. (Non-full screen mode causes MATLAB to crash in
% Linux.)
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

debug=0;

% get the indexes of the poiter devices (mouse)
[mouseIndex] = GetMouseIndices;

%--------------------------------------------------------------------------
% SET DIRECTORIES
%--------------------------------------------------------------------------

directory=cd('/home/emalab/Distractor_experiment/');
directory_data='/home/emalab/Distractor_experiment/data/';
directory_texts='/home/emalab/Distractor_experiment/texts/';
directory_stimuli='/home/emalab/Distractor_experiment/stimuli/';

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

% read the task text file
task = fopen([directory_texts 'task.m'], 'rt');
    if task==-1
        error('Could not open task.m file.');
    end
    
task_text = '';
    while ~feof(task)
        task_text = [task_text, fgets(welcome)];
    end
fclose(task);

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

% read text about a block break
block_break_first = fopen([directory_texts 'block_break_1.m'], 'rt');
    if  block_break_first == -1
        error('Could not open block_break_1.m file.');
    end
    
block_break_first_text = '';
    while ~feof(block_break_first)
        block_break_first_text = [block_break_first_text, fgets(block_break_first)];
    end
fclose(block_break_first);

% read text about a block break
block_break_second = fopen([directory_texts 'block_break_2.m'], 'rt');
    if  block_break_second==-1
        error('Could not open block_break_2.m file.');
    end
    
block_break_second_text = '';
    while ~feof(block_break_second)
        block_break_second_text = [block_break_second_text, fgets(block_break_second)];
    end
fclose(block_break_second);

% read text about a block break
block_break_third = fopen([directory_texts 'block_break_3.m'], 'rt');
    if  block_break_third==-1
        error('Could not open block_break_3.m file.');
    end
    
block_break_third_text = '';
    while ~feof(block_break_third)
        block_break_third_text = [block_break_third_text, fgets(block_break_third)];
    end
fclose(block_break_third);
    
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
dist_length=13;
for i = 1:dist_length
    [y_dist{i}, fr_dist] = wavread([directory_stimuli 'dist_' num2str(i) '.wav']);
    dist{i} = y_dist{i}';
    % Number of rows == number of channels.
    nrchannels_dist = size(dist{i},1);
end    

% get marker file
[y_marker, fr_marker] = wavread([directory_stimuli 'marker.wav']);
marker = y_marker';
nrchannels_marker = size(marker,1); % Number of rows == number of channels.

%--------------------------------------------------------------------------
% STIMULI STRUCTURE ARRAY FOR THE PRESENTATION
%--------------------------------------------------------------------------

% response symbols
symbol=[{'##'},{'**'}];
sym_leng=length(symbol);

% distractor syllable
dist_type=[{'ka'},{'ta'}];
type_leng=length(dist_type);

% VOT steps from 45 to 120 in 15-msces steps
dist_step=[{'n'} {'t'} {45, 60, 75, 90, 105, 120}];
step_leng=length(dist_step);

% SOA conditions
soa=[0.1, 0.2];
soa_leng=length(soa);

% symbol list: 32 repetitions
symbol_list=repmat(symbol, 1, 32);

% distractor type list: 16 repetitions + 16 repetitions flipped
distype_list=repmat(dist_type, 1, 16);
distype_list=[distype_list, fliplr(distype_list)];

% distractor step list: (2 repetitions + 2 flipped repetitions) * 2
vot_list=repmat(dist_step, 1, 2);
vot_list=[vot_list, fliplr(vot_list)];
vot_list=repmat(vot_list, 1, 2);

% SOA list: (2 repetitions = 2 flipped repetitions) * 8
soa_list=repmat(soa, 1, 2);
soa_list=[soa_list, fliplr(soa_list)];
soa_list=repmat(soa_list, 1, 8);

% stimuli structure array with 64 structures containing each 4 fields:
% Response_symbol, Dis_type, VOT, SOA
for i=1:length(symbol_list)
    stimuli_struct(i) = struct('Response_symbol', symbol_list(i), ...
        'Distractor_type', distype_list(i), 'VOT', vot_list(i), ...
        'SOA', soa_list(i));
end

% number of repetitions for each distractor/response combination per block
repeat=4;

% repeat the basic trial matrix for x repetitions
stimuli_struct=repmat(stimuli_struct, 1, repeat);

%number of the stimuli items contained in the stimuli array
trial=length(stimuli_struct);

%--------------------------------------------------------------------------
% PSYCHPORTAUDIO SET-UP
%--------------------------------------------------------------------------

% audio driver latency
suggestedLatencySecs = 0.054;

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
pa_handle = PsychPortAudio('Open', [], [], 0, fr_dist, nrchannels_dist, [], ...
    suggestedLatencySecs);

% prepare the voice trigger (low-latency mode (=2);
% only one handle possible in mode 2
freq = 44100;
% set voice trigger level
triggerlevel = 0.1;
% open audio channel for voice trigger
trigger_handle = PsychPortAudio('Open', [], 2, 2, freq, 2, [], 0.02);

% fill the audio playback buffer with the marker:
PsychPortAudio('FillBuffer', pa_handle, marker);

% perform one warmup trial, to get the sound hardware fully up and running,
% performing whatever lazy initialization only happens at real first use.
PsychPortAudio('Start', pa_handle, 1);
PsychPortAudio('Stop', pa_handle, 1);

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
screen_id = 0; %max(Screen('Screens'));

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

% number of frames for cross display
waitframes = ceil((suggestedLatencySecs + 0.45) / ifi) + 1;

% select specific text font, style and size for the text/cue
Screen('TextFont',window, 'Arial');
Screen('TextSize',window, 78);
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

Screen('TextSize',window, 34);

DrawFormattedText(window, double(welcome_text), 'center', 'center', [], [], [], [], 2);
Screen('Flip', window);
WaitSecs(3);

%--------------------------------------------------------------------------
% TASK TEXT
%--------------------------------------------------------------------------

Screen('TextSize',window, 24);

DrawFormattedText(window, double(task_text), 100, 'center', [], [], [], [], 2);
Screen('Flip', window);
fprintf('Task description displayed.\n')
KbWait(max(mouseIndex)); % wait for user's input to continue

%--------------------------------------------------------------------------
% SYMBOL==SYLLABLE TEXT
%--------------------------------------------------------------------------

DrawFormattedText(window, double(symbol_text), 'center', 'center', [], [], [], [], 2);
PsychPortAudio('FillBuffer', pa_handle, dist{13});
Screen('Flip', window);
WaitSecs(0.5);

KbWait(max(mouseIndex)); % wait for user's input to continue

% mark the start of the experiment
PsychPortAudio('Start', pa_handle, 1);
start_record = GetSecs;
Screen('Flip', window);
WaitSecs(1);
PsychPortAudio('Stop', pa_handle);

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

%randomization of the array items order by random index permutation
index=randperm(trial);
stimuli_struct_rand=stimuli_struct(index);

%set font size for the visual cue
Screen('TextSize', window, 78);

for i = 1:training_trials
    
    if i == 1
        fprintf('Training started.\n')
    else
    end
    
    % fill the audio playback buffer with the marker:
    PsychPortAudio('FillBuffer', pa_handle, marker);
    
    % play marker to mark start of trial
    PsychPortAudio('Start', pa_handle, 1);
    
    % draw the fixation cross
    Screen('DrawLines', window, allCoords, lineWidthPix, black, [xCenter yCenter]);
    
    % display fixation cross
    [vbl_cross, cross_onset] = Screen('Flip', window);
    
    % prepare visual cue
    if stimuli_struct_rand(i).Response_symbol == '##'
        Screen('DrawText', window, stimuli_struct_rand(i).Response_symbol, ... 
        xCenter-hash_width/2, yCenter-hash_height/2);
    else
        Screen('DrawText', window, stimuli_struct_rand(i).Response_symbol, ... 
        xCenter-stars_width/2, yCenter-stars_height/2);
    end
    
    % play marker
    PsychPortAudio('Start', pa_handle, 1, cross_onset + waitframes * ifi, 0);
    
    % display visual cue    
    [vbl_cue, cue_onset] = Screen('Flip', window, vbl_cross + (waitframes - 0.5) * ifi);
    Screen('FillRect', window, grey);
    
    % Spin-Wait until hw reports the first sample is played...
    offset = 0;
    while offset == 0
        status = PsychPortAudio('GetStatus', pa_handle);
        offset = status.PositionSecs;
        plat = status.PredictedLatency;
        fprintf('Predicted Latency: %6.6f msecs.\n', plat*1000);
        if offset>0
            break;
        end
        WaitSecs('YieldSecs', 0.001);
    end
    marker_onset = status.StartTime;
    
    %stop marker
    %PsychPortAudio('Stop', pa_handle);
    
    fprintf('Screen    expects visual onset at %6.6f secs.\n', cue_onset);
    fprintf('PortAudio expects audio onset  at %6.6f secs.\n', marker_onset);
    fprintf('Expected audio-visual delay    is %6.6f msecs.\n', (marker_onset - cue_onset)*1000.0);
    
    % fill the audio playback buffer with the distractor:
    if stimuli_struct_rand(i).Distractor_type == 'ka'
    switch stimuli_struct_rand(i).VOT % choose VOT condition
        case 't' % tone condition
            PsychPortAudio('FillBuffer', pa_handle, dist{13});
        case 45
            PsychPortAudio('FillBuffer', pa_handle, dist{1});
        case 60
            PsychPortAudio('FillBuffer', pa_handle, dist{2});
        case 75
            PsychPortAudio('FillBuffer', pa_handle, dist{3});
        case 90
            PsychPortAudio('FillBuffer', pa_handle, dist{4});
        case 105
            PsychPortAudio('FillBuffer', pa_handle, dist{5});
        case 120
            PsychPortAudio('FillBuffer', pa_handle, dist{6});
        otherwise
    end
    else
    switch stimuli_struct_rand(i).VOT % choose VOT condition
        case 't' % tone condition
            PsychPortAudio('FillBuffer', pa_handle, dist{13});
        case 45
            PsychPortAudio('FillBuffer', pa_handle, dist{7});
        case 60
            PsychPortAudio('FillBuffer', pa_handle, dist{8});
        case 75
            PsychPortAudio('FillBuffer', pa_handle, dist{9});
        case 90
            PsychPortAudio('FillBuffer', pa_handle, dist{10});
        case 105
            PsychPortAudio('FillBuffer', pa_handle, dist{11});
        case 120
            PsychPortAudio('FillBuffer', pa_handle, dist{12});
        otherwise
    end
    end
        
    % play distractor
    if i > training_trials/2
        % check if there is a distractor
        if stimuli_struct_rand(i).VOT ~= 'n'
            PsychPortAudio('Start', pa_handle, 1, ...
                cue_onset + stimuli_struct_rand(i).SOA, 0);
        else
        end
    else
    end
    
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
                
    % clear screen once response is detected
    Screen('Flip', window);
    
    % time for the answer: seconds
    WaitSecs(0.8); 
        
    % stop distractor
    if stimuli_struct_rand(i).VOT ~= 'n'
        PsychPortAudio('Stop', pa_handle);
    else
    end
    
    % get training response time
    % training_rt(i)=(response_onset - cue_onset)*1000.0;
end

% mean reference time for the feedback after the first experimental block
% reference_rt=mean(training_rt);

%--------------------------------------------------------------------------
% TRAINING FINISHED TEXT
%--------------------------------------------------------------------------

%set font size for the info texts
Screen('TextSize', window, 24);

DrawFormattedText(window, double(training_end_text), 'center', 'center', [], [], [], [], 2);
Screen('Flip', window);
fprintf('Training finished.\n')
KbWait(max(mouseIndex)); % wait for user's input to continue
        
%--------------------------------------------------------------------------
% SYMBOL==SYLLABLE TEXT FOR EXPERIMENT
%--------------------------------------------------------------------------

DrawFormattedText(window, double(symbol_text), 'center', 'center', [], [], [], [], 2);
Screen('Flip', window);
WaitSecs(0.5);
KbWait(max(mouseIndex)); % wait for user's input to continue
Screen('Flip', window);
fprintf('1 second left until the start of experiment.\n')
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
    cue_marker = zeros(1);
else
    block=4;
    % trial=length(stimuli_struct); as defined in line 243
end

% create variables for trial data
trial_id = cell(1);
visual_cue = cell(1);
distactor = cell(1);
vot_step = cell(1);
SOA = cell(1);
rt = cell(1);
cue_marker_delay = cell(1);
block_id=cell(1);
trial_start=cell(1);
marker_stamp=cell(1);
    
% transpose all trial data vectors 
trial_id=trial_id'; visual_cue=visual_cue'; distactor=distactor'; ...
vot_step=vot_step'; SOA=SOA'; rt=rt'; cue_marker_delay=cue_marker_delay'; ...
block_id=block_id'; trial_start=trial_start'; marker_stamp=marker_stamp';
   
for j=1:block 
    
    if j == 1
        fprintf('Experiment started.\n')
    else
        fprintf('Next block started.\n')
    end
    
    %randomization of the array items order by random index permutation
    index=randperm(trial);
    stimuli_struct_rand=stimuli_struct(index);
    
    %set font size for the visual cue
    Screen('TextSize', window, 78);
    
    % INNER TRIAL LOOP
    for i=1:trial
    
    % fill the audio playback buffer with the marker:
    PsychPortAudio('FillBuffer', pa_handle, marker);
    
    % play marker to mark start of trial
    PsychPortAudio('Start', pa_handle, 1);
    start = GetSecs;
    
    % draw the fixation cross
    Screen('DrawLines', window, allCoords, lineWidthPix, black, [xCenter yCenter]);
    
    % display fixation cross
    [vbl_cross, cross_onset] = Screen('Flip', window);
    
    % prepare visual cue
    if stimuli_struct_rand(i).Response_symbol == '##'
        Screen('DrawText', window, stimuli_struct_rand(i).Response_symbol, ... 
        xCenter-hash_width/2, yCenter-hash_height/2);
    else
        Screen('DrawText', window, stimuli_struct_rand(i).Response_symbol, ... 
        xCenter-stars_width/2, yCenter-stars_height/2);
    end
    
    % play marker
    PsychPortAudio('Start', pa_handle, 1, cross_onset + waitframes * ifi, 0);
    
    % display visual cue    
    [vbl_cue, cue_onset] = Screen('Flip', window, vbl_cross + (waitframes - 0.5) * ifi);
    Screen('FillRect', window, grey);
    
    % Spin-Wait until hw reports the first sample is played...
    offset = 0;
    while offset == 0
        status = PsychPortAudio('GetStatus', pa_handle);
        offset = status.PositionSecs;
        plat = status.PredictedLatency;
        %fprintf('Predicted Latency: %6.6f msecs.\n', plat*1000);
        if offset>0
            break;
        end
        WaitSecs('YieldSecs', 0.001);
    end
    marker_onset = status.StartTime;
    
    %stop marker
    %PsychPortAudio('Stop', pa_handle);
    
    %fprintf('Screen    expects visual onset at %6.6f secs.\n', cue_onset);
    %fprintf('PortAudio expects audio onset  at %6.6f secs.\n', marker_onset);
    %fprintf('Expected audio-visual delay    is %6.6f msecs.\n', (marker_onset - cue_onset)*1000.0);
    
    % fill the audio playback buffer with the distractor:
    if stimuli_struct_rand(i).Distractor_type == 'ka'
    switch stimuli_struct_rand(i).VOT % choose VOT condition
        case 't' % tone condition
            PsychPortAudio('FillBuffer', pa_handle, dist{13});
        case 45
            PsychPortAudio('FillBuffer', pa_handle, dist{1});
        case 60
            PsychPortAudio('FillBuffer', pa_handle, dist{2});
        case 75
            PsychPortAudio('FillBuffer', pa_handle, dist{3});
        case 90
            PsychPortAudio('FillBuffer', pa_handle, dist{4});
        case 105
            PsychPortAudio('FillBuffer', pa_handle, dist{5});
        case 120
            PsychPortAudio('FillBuffer', pa_handle, dist{6});
        otherwise
    end
    else
    switch stimuli_struct_rand(i).VOT % choose VOT condition
        case 't' % tone condition
            PsychPortAudio('FillBuffer', pa_handle, dist{13});
        case 45
            PsychPortAudio('FillBuffer', pa_handle, dist{7});
        case 60
            PsychPortAudio('FillBuffer', pa_handle, dist{8});
        case 75
            PsychPortAudio('FillBuffer', pa_handle, dist{9});
        case 90
            PsychPortAudio('FillBuffer', pa_handle, dist{10});
        case 105
            PsychPortAudio('FillBuffer', pa_handle, dist{11});
        case 120
            PsychPortAudio('FillBuffer', pa_handle, dist{12});
        otherwise
    end
    end
        
    % play distractor
    % check if there is a distractor
    if stimuli_struct_rand(i).VOT ~= 'n'
        PsychPortAudio('Start', pa_handle, 1, ...
            cue_onset + stimuli_struct_rand(i).SOA, 0);
    else
    end
        
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
                
    % clear screen once response is detected
    Screen('Flip', window);
        
    % time for the answer: seconds
    WaitSecs(0.8);
    
    % stop distractor
    if stimuli_struct_rand(i).VOT ~= 'n'
        PsychPortAudio('Stop', pa_handle);
    else
    end
              
%--------------------------------------------------------------------------
% STORE TRIAL DATA
%--------------------------------------------------------------------------

    % block id
    block_id=num2cell(j);
    % trial id
    trial_id=num2cell(i);
    % visual cue
    visual_cue=cellstr(stimuli_struct_rand(i).Response_symbol);
    % distractor syllable
    distractor=cellstr(stimuli_struct_rand(i).Distractor_type);
    % which vot
    vot_step=num2cell(stimuli_struct_rand(i).VOT);
    % SOA condition
    SOA=num2cell(stimuli_struct_rand(i).SOA);
    % response time (RT)
    rt=num2cell((response_onset - cue_onset)*1000.0);
    % start of the trial
    trial_start=num2cell(start-start_record);
    % marker
    marker_stamp=num2cell(marker_onset-start_record);
    % delay between visual cue and marker
    if (marker_onset - cue_onset)*1000.0 > 0.01
        cue_marker_delay=cellstr('missed');
    else
        cue_marker_delay=cellstr('hit');
    end
    
    % combine all column vectors to one big array
    data_frame=[id age sex origin disorders b_response block_id trial_id ...
        trial_start marker_stamp visual_cue distractor vot_step SOA rt cue_marker_delay];

    % append to the participant's txt file
    cellwrite(file_name, data_frame);
    
%--------------------------------------------------------------------------
% STORE DATA FOR AUDIO-VIDEO SYNCHRONIZATION TESTS
%--------------------------------------------------------------------------

    if debug == 1
    
    % testing marker and visual cue synchronization 
    cue_marker(i)=(cue_onset - marker_onset)*1000.0;
   
    else
    end
    end % end of the INNER TRIAL LOOP

%--------------------------------------------------------------------------
% AUDIO-VIDEO SYNCHRONIZATION PLOTS
%--------------------------------------------------------------------------
    
    if debug == 1
   
    % plot marker delay to visual cue onset
    figure
    bar(cue_marker)
    ylabel('\delta(Beep to visual cue delay) [ms]')
    xlabel('Trial number')
    title('Beep to visual cue delay')

    else
    end
    
%--------------------------------------------------------------------------
% BLOCK END TEXT
%--------------------------------------------------------------------------

Screen('TextSize', window, 24);

if j == 1
    % draw and display text
    DrawFormattedText(window, double(block_break_first_text), 'center', 'center', [], [], [], [], 2);
    Screen('Flip', window);
    fprintf('Block finished. Pause?\n')
    KbWait(max(mouseIndex)); % wait for user's input to continue

elseif j == 2
    DrawFormattedText(window, double(block_break_second_text), 'center', 'center', [], [], [], [], 2);
    Screen('Flip', window);
    fprintf('Block finished. Pause?\n')
    KbWait(max(mouseIndex)); % wait for user's input to continue

elseif j == 3
    DrawFormattedText(window, double(block_break_third_text), 'center', 'center', [], [], [], [], 2);    
    Screen('Flip', window);
    fprintf('Block finished. Pause?\n')
    KbWait(max(mouseIndex)); % wait for user's input to continue

% -------------------------------------------------------------------------
% EXPERIMENT END TEXT    
% -------------------------------------------------------------------------

else    
    %draw and display text
    DrawFormattedText(window, double(exp_end_text), 'center', 'center', [], [], [], [], 2);
    Screen('Flip', window); % display "You're done!"
    fprintf('Experiment finished. Push any button to close everything.\n')
end
    
%--------------------------------------------------------------------------
% SYMBOL==SYLLABLE TEXT
%--------------------------------------------------------------------------

if j < block
    DrawFormattedText(window, double(symbol_text), 'center', 'center', [], [], [], [], 2);
    Screen('Flip', window);
    WaitSecs(0.5);
    KbWait(max(mouseIndex)); % wait for user's input to continue
end
end % end of the OUTER BLOCK LOOP

KbWait;

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