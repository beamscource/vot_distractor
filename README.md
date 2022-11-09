## vot_distractor
Matlab code controlling experimental flow of a dual-task speech-production study https://www.internationalphoneticassociation.org/icphs-proceedings/ICPhS2015/Papers/ICPHS0455.pdf

Although a Windows and a Linux version of the script is included, during set-up tests I discovered that the presentation of audio stimuli might vary by +/- 10 msec on Windows machines. This effectively rendered the reaction time data collected on a Windows machine unusable. Hence, the final experiment was conducted on a Linux Ubuntu laptop with an audio playback variance of +/- 1 msec.

From technical standpoint, it was a battle to synchronise screen refresh rates with the playback onset of auditory stimuli. Part of the code implements a voice key. For this functionality I relied heavily on the free PsychtoolBox (http://psychtoolbox.org/). You can find helpful example code for testing audio playback latency here https://code.google.com/archive/p/asf/wikis/TutorialTimingAudio.wiki

**The code was written in the period between February and April 2014.** This is one of my first bigger coding projects and I would have approached several things differently today. First of all, now I would use Python instead of Matlab.

### Data annotation
Response onset times (RTs) and voice-onset times (VOTs) were annotated manually using Matlab's ginput() function. The annotation script loads chunks of a wav-recording from an experimental session. To focus on the window which contains participants response, the script operates with a log file provided by the experimental distractor script.

For each trial, the sound signal is filtered and the wave form is then presented along with a spectrogram. The RTs and VOTs are computed from the manual annotation points. All relevant data is written into an excel file ready to be processed for statistical analysis.

There is also an first attempt to implement a completely automatic version of the annotation script. The main idea was to identify salient landmarks based on auditory energy bursts and the zero-crossings rate. This part of the code relies on the free MIRtoolbox (https://www.jyu.fi/hytk/fi/laitokset/mutku/en/research/materials/mirtoolbox). The idea was abandoned due to lack of time but was eventually realized in follow-up research https://ieeexplore.ieee.org/document/7905803 The code for this can be found at https://github.com/srkuberski/cdp/tree/current/apps/klein

### Study background
On each trial of the experiment, participants are presented with one of two symbols (## or **) and have to response as fast as possible by uttering a corresponding syllable (ta or ka). While a participant is initiating their voice response, an audio distractor is played over headphones, essentially slowing down the response. One research question was whether phonetic congruency between the response and the distractor would result in weaker slowdown.

An addition to the distractor paradigm was the inclusion of varying VOTs for the distractor stimuli, which allowed to investigate whether participants would accommodate their own VOT in reaction to the distractor. **You can read on the results of the study in more detail in my master's thesis** https://www.researchgate.net/publication/288841117_Perceptuo-motor_accommodation_of_voice-onset_time_during_a_dual-task_of_speaking_while_listening
