%% IETS Measurment %% DC and AC signals are mixed with the help of Op-Amps
%  and the output of adder are in series with LIA and DUT. %%

%Intializing Instruments %
clc;
clear;
clear ALL;
tic  %enabling clock
fprintf('Initializing...');
fprintf('\n');
close all;
pause(4);
openports=instrfind;
if ~isempty(openports)
    fclose(instrfind);
end
pause(4);
lockin=gpib('ni',0,8);
dcsource=gpib('ni',0,26);
acsource=gpib('ni',0,10);
fopen(lockin);
fopen(dcsource);
fopen(acsource); 
pause(4);
prompt = 'Do you want to reset the instruments? Y/N [Y]: ';
Choise = input(prompt,'s');
switch Choise
    case 'Y'
    fprintf(dcsource,'smua.reset()');
    pause(1);
    fprintf(acsource,'*RST');
    pause(1);
    fprintf(lockin,'*RST'); 
    pause(3);     
    case 'N'
end
% DC Source(2602) setting %
fprintf('Setting DC source');
fprintf('\n');
pause(5);
c = input('Enter current compliance ..mA\n'); icompl = c*1e-3;
fprintf(dcsource,'smua.source.func = smua.OUTPUT_DCVOLTS'); % Select voltage source 
fprintf(dcsource,'smua.source.autorangev = smua.AUTORANGE_ON'); % Enable voltage source autorange
instr=['smua.source.limiti =' num2str(icompl)]; fprintf(dcsource,instr); % Set current compliance limit
fprintf(dcsource,'smua.measure.rangei = 1e-3'); % Set current measure range
pause(2);

% AC Source(33220) setting %
fprintf('Setting AC source');
fprintf('\n');
pause(2);
f = input('Enter modulation frequency ..Hz\n');
fprintf(acsource,'VOLT:RANG:AUTO ON');
%fprintf(acsource,'OUTP:LOAD 50'); % Load impedance is 50 Ohms
fprintf(acsource,'APPL:SIN %d,0.1',f);
pause(2);

% Lock-In(SR830) setting %
fprintf('Setting LIA');
fprintf('\n');
pause(2);
hrm = input('Select harmonic\n');
sen = input('Set sensitivity\n');
tau = input('Set time constant\n');
drm = input('Set Dynamic Reserve\n');
if f<200
    synf = 1;
else 
    synf = 0;
end
fprintf(lockin,'OUTX 1'); % 1: Output interface to GPIB
fprintf(lockin,'FMOD 0'); % 0: Reference source is external
fprintf(lockin,'RSLP 1'); % 1: Reference slope is TTL rising
fprintf(lockin,'IGND 0'); % 1: gnd, 0: Float
fprintf(lockin,'ISRC 2'); % 2: Input configuration is I(1MOhm)
instr=['RMOD ',num2str(drm)];fprintf(lockin,instr); %Dynamic reserve mode 1: Normal, 0: High
instr=['SYNC ',num2str(synf)];fprintf(lockin,instr); %Synchronous filter 1:ON (below 200Hz), 0: OFF
instr=['HARM ',num2str(hrm)];fprintf(lockin,instr); % Harmonics
instr=['SENS ',num2str(sen)];fprintf(lockin,instr); % Sensitivity 
instr=['OFLT ',num2str(tau)];fprintf(lockin,instr); % Time constant
% instr='OFSL 1';fprintf(lockin,instr); % Slope of Low pass filter
% fprintf(lockin,'ILIN 3'); % 
fprintf(lockin,'DDEF 1,1,0'); % Setting Channel 1 display as R
fprintf(lockin,'DDEF 2,1,0'); % Setting Channel 2 display as theta
fprintf(lockin,'APHS'); % Autophase 
pause(10);

% Turning ON sources %
fprintf(acsource,'OUTP ON');
fprintf(acsource,'OUTP:SYNC ON');
pause(4)
fprintf(dcsource,'smua.source.output = smua.OUTPUT_ON'); % Turn on source output
fprintf('Sources are turned ON');
fprintf('\n');
pause(10);

% Start sweeping the voltage%
vm = input('Set the maximum DC voltage\n');
s = input('How many data points for averaging?\n');
initial = -vm;
step = 0.001;
final = vm;
if tau == 9
    t = 0.3;
elseif tau == 10
    t = 1;
elseif tau == 11
    t = 5;
end
p=5*t;
j=1;
fprintf('Sweeping the DC voltage');
fprintf('\n');
for l=initial:step:final
instr=['smua.source.levelv = ' num2str(l)];fprintf(dcsource,instr);
pause(p);
for k=1:s
    fprintf(lockin,'OUTP? 3');
    z(k,1)=str2num(fscanf(lockin));
end
h(j,1)=sum(z)/k;
v(1,j)=l;
j=j+1;
figure(1);
plot(v,h);
title('Harmonic detection');
xlabel('Voltage(V)');
ylabel('Harmonic signal');
grid on;
end

% Data Saving %
pause(2);
data=[v' h];
filename = 'IETS-Adder-130422';
tag={'V','If'};
xlswrite(filename,tag,'10K','C1'); 
xlswrite(filename,data,'10K','C2');
fprintf('Data saved');
fprintf('\n');
pause(2);

% Closing all instruments %
close all;
offvolt=0;
instr=['smua.source.levelv =' num2str(offvolt)]; fprintf(dcsource,instr);
pause(0.1);
%fprintf(dcsource,'smua.source.output = smua.OUTPUT_OFF');
%fprintf(acsource,'OUTP OFF');
pause(0.1);
fclose(dcsource);delete(dcsource);
fclose(lockin);delete(lockin);
fclose(acsource);delete(acsource);
fprintf('Instruments are turned OFF');
fprintf('\n');
pause(1);
toc       %disabling clock
pause(1);
fprintf('Thank You');
fprintf('\n');

%%%-----------------------------------END-------------------------------%%%
                                     
%   Sensitivity   
%   26 -> 1V/uA     25 -> 500 mV/nA   24 -> 200 mV/nA   23 -> 100 mV/nA
%   22 -> 50 mV/nA  21 -> 20 mV/nA    20 -> 10 mV/nA    19 -> 5 mV/nA
%   18 -> 2 mV/nA   17 -> 1 mV/nA     16 -> 500 uV/pA
%   
%   Time Constant  
%   8 -> 100 ms     9 -> 300 ms       10 -> 1 s         11 -> 3 s
%   RMOD
%   0 -> High Reserve      1 -> Normal      2 -> Low noise
