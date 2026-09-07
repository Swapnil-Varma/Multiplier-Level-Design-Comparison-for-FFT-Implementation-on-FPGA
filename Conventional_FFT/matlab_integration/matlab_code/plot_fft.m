% ============================================================
% plot_fft.m
%
% 8-Point Conventional FFT
% Verilog/Vivado FFT Output -> MATLAB
%
% Features:
%   1. Read fft_output.csv
%   2. Calculate magnitude and phase
%   3. Convert FFT bins to frequency
%   4. Compare Hardware FFT with MATLAB FFT
%   5. Calculate numerical error
%   6. Plot frequency-domain spectrum
%   7. Plot single-sided spectrum
%
% Fixed Point Format: Q1.15
% ============================================================

clc;
clear;
close all;

%% ============================================================
% PARAMETERS
% =============================================================

N = 8;

% Sampling frequency
%
% Change this value according to your project.
%
% Example:
% Fs = 8000 means sampling frequency = 8 kHz

Fs = 8000;             % Hz


%% ============================================================
% READ VERILOG FFT CSV FILE
% =============================================================

filename = 'fft_output.csv';

if ~isfile(filename)
    error('fft_output.csv was not found. Put it in the MATLAB Current Folder.');
end

data = readtable(filename);


%% ============================================================
% EXTRACT HARDWARE FFT DATA
% =============================================================

k  = data.Bin;
Re = data.Real;
Im = data.Imaginary;


% Make sure data is column vector

k  = k(:);
Re = Re(:);
Im = Im(:);


%% ============================================================
% CHECK FFT SIZE
% =============================================================

if length(k) ~= N
    error('Expected %d FFT outputs, but CSV contains %d outputs.', ...
          N, length(k));
end


%% ============================================================
% CREATE COMPLEX HARDWARE FFT OUTPUT
% =============================================================

X_hw = Re + 1i * Im;


%% ============================================================
% CALCULATE MAGNITUDE AND PHASE
% =============================================================

Magnitude_hw = abs(X_hw);

Phase_hw = angle(X_hw);


%% ============================================================
% FREQUENCY AXIS
% =============================================================

Frequency = k * Fs / N;

Frequency_resolution = Fs / N;


%% ============================================================
% DISPLAY HARDWARE FFT OUTPUT
% =============================================================

disp(' ');
disp('============================================================');
disp('             VERILOG FFT FREQUENCY DOMAIN OUTPUT');
disp('============================================================');

fprintf('\n');
fprintf('FFT Size              = %d\n', N);
fprintf('Sampling Frequency    = %.2f Hz\n', Fs);
fprintf('Frequency Resolution  = %.2f Hz\n', Frequency_resolution);

fprintf('\n');
fprintf('------------------------------------------------------------');
fprintf('\n');
fprintf('Bin\tFrequency\tReal\t\tImaginary\tMagnitude');
fprintf('\n');
fprintf('------------------------------------------------------------');
fprintf('\n');

for n = 1:N

    fprintf('%d\t%.2f Hz\t%.6f\t%.6f\t%.6f\n', ...
        k(n), ...
        Frequency(n), ...
        Re(n), ...
        Im(n), ...
        Magnitude_hw(n));

end

fprintf('------------------------------------------------------------\n');


%% ============================================================
% EXACT Q1.15 INPUT USED BY VERILOG
% ============================================================
%
% Verilog input:
%
% x0 = 16'h0CCD
% x1 = 16'h199A
% x2 = 16'hF333
% x3 = 16'h1333
% x4 = 16'hE666
% x5 = 16'h0666
% x6 = 16'h2000
% x7 = 16'hECCD
%
% Convert these exact fixed-point values to decimal.
% =============================================================

x_q15 = [ ...
    hex2dec('0CCD'), ...
    hex2dec('199A'), ...
    hex2dec('F333'), ...
    hex2dec('1333'), ...
    hex2dec('E666'), ...
    hex2dec('0666'), ...
    hex2dec('2000'), ...
    hex2dec('ECCD') ...
    ];


%% ============================================================
% CONVERT UNSIGNED 16-BIT TO SIGNED 16-BIT
% =============================================================

x_q15(x_q15 >= 32768) = ...
    x_q15(x_q15 >= 32768) - 65536;


%% ============================================================
% CONVERT Q1.15 TO DECIMAL
% =============================================================

x = x_q15 / 32768;


%% ============================================================
% DISPLAY ACTUAL HARDWARE INPUT
% =============================================================

disp(' ');
disp('============================================================');
disp('                 VERILOG INPUT SIGNAL');
disp('============================================================');

fprintf('\n');

for n = 1:N
    fprintf('x[%d] = %.10f\n', n-1, x(n));
end

fprintf('\n');


%% ============================================================
% MATLAB REFERENCE FFT
% =============================================================

X_matlab = fft(x, N);


%% ============================================================
% MATLAB FFT MAGNITUDE
% =============================================================

Magnitude_matlab = abs(X_matlab);


%% ============================================================
% ERROR CALCULATION
% =============================================================

% Complex error at every FFT bin

Error = X_matlab(:) - X_hw(:);


% Absolute error at every FFT bin

Absolute_Error = abs(Error);


% Maximum absolute error

Maximum_Error = max(Absolute_Error);


% Mean absolute error

Mean_Error = mean(Absolute_Error);


% RMS error

RMS_Error = sqrt(mean(Absolute_Error.^2));


%% ============================================================
% DISPLAY HARDWARE VS MATLAB RESULTS
% =============================================================

disp(' ');
disp('============================================================');
disp('             HARDWARE FFT vs MATLAB FFT');
disp('============================================================');

fprintf('\n');

fprintf('Bin\tFrequency\tHW Magnitude\tMATLAB Magnitude\tError\n');

fprintf('------------------------------------------------------------\n');

for n = 1:N

    fprintf('%d\t%.2f Hz\t%.8f\t%.8f\t\t%.10f\n', ...
        k(n), ...
        Frequency(n), ...
        Magnitude_hw(n), ...
        Magnitude_matlab(n), ...
        Absolute_Error(n));

end

fprintf('------------------------------------------------------------\n');

fprintf('\n');

fprintf('Maximum Absolute Error = %.10f\n', Maximum_Error);

fprintf('Mean Absolute Error    = %.10f\n', Mean_Error);

fprintf('RMS Error              = %.10f\n', RMS_Error);

fprintf('\n');


%% ============================================================
% PASS / FAIL CHECK
% ============================================================

% Tolerance for fixed-point FFT

Tolerance = 0.001;


if Maximum_Error <= Tolerance

    fprintf('RESULT: PASS\n');
    fprintf('Hardware FFT matches MATLAB FFT within tolerance.\n');

else

    fprintf('RESULT: CHECK REQUIRED\n');
    fprintf('Hardware FFT differs from MATLAB FFT by more than %.6f.\n', ...
            Tolerance);

end


fprintf('\n');

disp('============================================================');


%% ============================================================
% FIGURE 1
% REAL COMPONENT
% =============================================================

figure;

stem(Frequency, Re, 'filled');

xlabel('Frequency (Hz)');
ylabel('Real Part');

title('8-Point Verilog FFT - Real Component');

grid on;


%% ============================================================
% FIGURE 2
% IMAGINARY COMPONENT
% =============================================================

figure;

stem(Frequency, Im, 'filled');

xlabel('Frequency (Hz)');
ylabel('Imaginary Part');

title('8-Point Verilog FFT - Imaginary Component');

grid on;


%% ============================================================
% FIGURE 3
% FULL FREQUENCY-DOMAIN MAGNITUDE
% =============================================================

figure;

stem(Frequency, Magnitude_hw, 'filled');

xlabel('Frequency (Hz)');
ylabel('|X[k]|');

title('8-Point Verilog FFT - Frequency Domain');

grid on;


%% ============================================================
% FIGURE 4
% PHASE SPECTRUM
% =============================================================

figure;

stem(Frequency, Phase_hw, 'filled');

xlabel('Frequency (Hz)');
ylabel('Phase (Radians)');

title('8-Point Verilog FFT - Phase Spectrum');

grid on;


%% ============================================================
% FIGURE 5
% HARDWARE FFT vs MATLAB FFT
% =============================================================

figure;

stem(Frequency, Magnitude_matlab, 'filled');

hold on;

stem(Frequency, Magnitude_hw);

xlabel('Frequency (Hz)');
ylabel('Magnitude');

title('Verilog FFT vs MATLAB FFT');

legend('MATLAB FFT', 'Verilog FFT');

grid on;

hold off;


%% ============================================================
% SINGLE-SIDED SPECTRUM
% ============================================================
%
% Because the input signal is real-valued, the FFT contains
% conjugate-symmetric positive and negative frequency components.
%
% Therefore, for the conventional single-sided spectrum,
% only 0 -> Fs/2 is displayed.
% =============================================================

Frequency_single = Frequency(1:N/2+1);

Magnitude_single = Magnitude_hw(1:N/2+1);


% Double non-DC and non-Nyquist components

Magnitude_single(2:end-1) = ...
    2 * Magnitude_single(2:end-1);


%% ============================================================
% FIGURE 6
% SINGLE-SIDED FREQUENCY SPECTRUM
% =============================================================

figure;

stem(Frequency_single, Magnitude_single, 'filled');

xlabel('Frequency (Hz)');
ylabel('Magnitude');

title('Single-Sided Frequency Spectrum');

grid on;


%% ============================================================
% SINGLE-SIDED MATLAB REFERENCE
% =============================================================

Magnitude_single_matlab = Magnitude_matlab(1:N/2+1);

Magnitude_single_matlab(2:end-1) = ...
    2 * Magnitude_single_matlab(2:end-1);


%% ============================================================
% FIGURE 7
% SINGLE-SIDED HARDWARE vs MATLAB
% =============================================================

figure;

stem(Frequency_single, ...
     Magnitude_single_matlab, ...
     'filled');

hold on;

stem(Frequency_single, ...
     Magnitude_single);

xlabel('Frequency (Hz)');
ylabel('Magnitude');

title('Single-Sided Spectrum: Verilog FFT vs MATLAB FFT');

legend('MATLAB FFT', 'Verilog FFT');

grid on;

hold off;


%% ============================================================
% FINAL SUMMARY
% =============================================================

disp(' ');
disp('============================================================');
disp('                    FFT ANALYSIS COMPLETE');
disp('============================================================');

fprintf('\n');
fprintf('FFT Size              : %d\n', N);
fprintf('Sampling Frequency    : %.2f Hz\n', Fs);
fprintf('Frequency Resolution  : %.2f Hz\n', Frequency_resolution);

fprintf('\n');

fprintf('Maximum Absolute Error : %.10f\n', Maximum_Error);
fprintf('Mean Absolute Error    : %.10f\n', Mean_Error);
fprintf('RMS Error              : %.10f\n', RMS_Error);

fprintf('\n');

if Maximum_Error <= Tolerance
    fprintf('STATUS: PASS\n');
else
    fprintf('STATUS: CHECK HARDWARE / REFERENCE\n');
end

disp('============================================================');