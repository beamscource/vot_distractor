clear all;

directory_stimuli='/home/emalab/Distractor_experiment/stimuli/ka/';

PsychPortAudio('Verbosity', 10);

% Perform basic initialization of the sound driver:
InitializePsychSound(1);
freq = 44100;
suggestedLatencySecs=0.542;

% Generate some beep sound 1000 Hz, 0.1 secs, 50% amplitude:
%mynoise(1,:) = 0.5 * MakeBeep(1000, 0.1, freq);
%mynoise(2,:) = mynoise(1,:);

% get DISTRACTOR files
% length of the distractor stimuli list (with tone)
dist_length=10;
for i = 1:1
    [y_dist{i}, fr_dist] = wavread([directory_stimuli 'ka_' num2str(i) '.wav']);
    dist{i} = y_dist{i}';
    % Number of rows == number of channels.
    nrchannels_dist = size(dist{i},1);
end 

% prepare distractor playback        
% open playback channels
for i = 1:1
    dist_handle(i) = PsychPortAudio('Open', [], [], 0, fr_dist, nrchannels_dist, [], suggestedLatencySecs);
    % fill the audio playback buffer with the distractor:
    PsychPortAudio('FillBuffer', dist_handle(i), dist{i});
end

%dist_handle = PsychPortAudio('Open', [], [], 2, fr_dist, nrchannels, [], suggestedLatencySecs);

% open Screen
%width = 980;
%height = 700;
w = Screen('OpenWindow', 0, [255 255 255]) %, [0 0 width height]);

ifi = Screen('GetFlipInterval', w);

waitframes = ceil(suggestedLatencySecs / ifi) + 1;

Priority(MaxPriority(w));

for i=1:160
    % This flip clears the display to black and returns timestamp of black onset:
    % It also triggers start of audio recording by the DataPixx, if it is
    % used, so the DataPixx gets some lead-time before actual audio onset.
    
    [vbl1 visonset1]= Screen('Flip', w);
    

    % Prepare black white transition:
    Screen('FillRect', w, 255);
    %Screen('DrawingFinished', w);
    
    % Fill the audio playback buffer with the DISTRACTOR:
    %PsychPortAudio('FillBuffer', dist_handle, cell2mat(dist(i)));    
    
    [sound_onset] = PsychPortAudio('Start', dist_handle(1), 1, visonset1 + waitframes * ifi, 0);
    
    % Ok, the next flip will do a black-white transition...
    [vbl visual_onset] = Screen('Flip', w, vbl1 + (waitframes - 0.5) * ifi);
    
    % Stop playback:
    PsychPortAudio('Stop', dist_handle(1), 1);
    
    % testing BURST and visual cue synchronization 
    delay(i)=(visual_onset - sound_onset);
end

%plot delay
figure
bar(delay)
ylabel('\delta(delay) [ms]')
xlabel('Trial number')
title('Visual to sound delay')

Screen('CloseAll')