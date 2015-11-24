% Digital Signal Processing (Fall 2015)
% Project 2: Predict whether a male/female is speaking in the mp3 file
% By: Tyler Olivieri; Devin Trejo; Robert Irwin

% If generating a noisy figure download a function below:
% Download gen devGenerate_SineN here:
% https://github.com/dtrejod/myMatlabFn/blob/master/Stocastics/devGenerate_SineN.m

%%
clear; clc; close all;
% --------------------
% - Input parameters - 
% --------------------
% Expect frequency for male female
%
fMale = 125;
fFemale = 200;

% Below comment in/out whether you are importing a signal or creating a
% test signal
%
% - - - - - - - - - - - - Import Signal - - - - - - - - - - - - - - - - - 
% Read in speech signals
%
nameSig = 'clinton.mp3';
[sig, fs] = audioread(nameSig);

% Signals are mono so we remove the second channel 
%
sig = sig(:,1);

% - - - - - - - - - - Create a noisy signal - - - - - - - - - - - - - - - 
% fs = 44.1E3; % Specify Sample Frequency
% nameSig = 'Generated noisy sine'; % Name for label on plots
% Use custom function to generate noisy sine wave
%

% sig = devGenerate_SineN(1,125,10,fs,-100);
% sig = sig + devGenerate_SineN(1,162,10,fs,-30);
% sig = sig + devGenerate_SineN(3,80,10,fs,-50);
% sig = sig + devGenerate_SineN(1,100,10,fs,-10);
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

% -------------------------------------------------
% - Below Everything is Automatically Calculated  - 
% -------------------------------------------------
% Create a time vector
%
samL = length(sig);
t = linspace(0,samL/fs,samL);

% Plot time signal
%
figure(); plot(t, sig)
xlabel('time (secs)'); title(nameSig);

% Low pass the signal
%
lowp = designfilt('lowpassiir', 'FilterOrder', 20, 'PassbandFrequency', 250,...
     'PassbandRipple', .2, 'SampleRate', fs);
sig = filter(lowp, sig);

% Frame and window Parameters. We round to nearest divisble by two number
%
% Window = Analysis window to consider
% Frame  = How often we compute whose talking
%
wdur_a = 2*round(fs/2); % Window Size every tenth of a second
fdur_a = 2*round(wdur_a/20); % Window devided by 

% Our window/frame analysis variables
%
sig_wbuf = zeros(1, wdur_a); % Intialize our window to all zeros. 
num_frames = 1+round(samL / fdur_a); % Find number of frames that fit in 
                                     % buffer
Rt = zeros(length(sig),1); % Intialize a zero for autocorrelation

% Loop over the entire signal
%
for i = 1:num_frames
%for i = num_frames/2:num_frames/2+5 % Uncomment to see only 5 frames
    % generate the pointers for how we will move through the data signal.
    % the center tells us where our frame is located and the ptr and right
    % indicate the reach of our window around that frame
    %
    n_center = (i - 1) * fdur_a + (fdur_a / 2);
    n_left = n_center - (wdur_a / 2);
    n_right = n_left + wdur_a ;
    
    % when the pointers exceed the index of the input data we won't be
    % adding enough samples to fill the full window. to solve this zero
    % stuffing will occur to ensure the buffer is always full of the same
    % number of samples
    %
    if( (n_left < 0) || (n_right > samL) )
        sig_wbuf = zeros(1, wdur_a);
    end
    % transfer the data to this buffer:
    %   note that this is really expensive computationally
    %
    for j = 1:wdur_a
        index = n_left + (j - 1);
        if ((index > 0) && (index <= samL))
            sig_wbuf(j) = sig(index);
        end
    end
    
    % Print the analysis window time frame we are currenlty looking at
    % to the console. 
    %
    fprintf('From time = %d -> %d\n', ...
        (n_left+wdur_a)/fs, (n_right+wdur_a)/fs);
    
    % Compute Autocorrelation for current window
    %
    [Rt, ~, ~] = autocorr(sig_wbuf,wdur_a -1);
    
    % Compute the FFT
    %
    %figure();
    NFFT = 2^nextpow2(wdur_a);
    X = fft(Rt, NFFT)/wdur_a;
    FTM = abs(X(1:NFFT/2+1)); % Truncate FFT to only fs/2
    f = fs/2*linspace(0,1,NFFT/2+1); % Create f vector
    
    % Plot PSD
    %
    %figure()
    %plot(f, FTM); xlim([0 1E3]); 
    %grid on; xlabel('Frequency (Hz)'); 
    
    % Find fundamental frequency by looking at the maximum value in our 
    % power spectral density. 
    %
    f0_indx = find(FTM==(max(max(FTM))));
    f0(i) = f(f0_indx);
    
    % Print the current fundamental frequency in the observable range to
    % the console
    %
    disp(f0(i))
end

avg_f0 = mean(f0);
figure()
plot(f0)
hold on
plot(xlim, [1 1]*fMale, '--'); plot(xlim, [1 1]*fFemale, '--'); grid on
plot(xlim, [1 1]*avg_f0, '--');
legend([nameSig ' F_0'], 'Male F_0', 'Female F_0', [nameSig '_a_v_g F_0']);
ylabel('Hertz');
ylim([0 500])
avg_f0