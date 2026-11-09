%% Khaled_KH06_Storage_Audit.m
% Produces ACTUAL PCM16 WAV files from KH-04 arrays for a local export audit.

clc;
clear;
close all;

%% 1. Locate KH-04 inputs
scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptFolder);
inputFolder = fullfile(projectRoot,'Results','Khaled','Combined');
outputFolder = fullfile(projectRoot,'Results','Khaled','Storage');
wavFolder = fullfile(outputFolder,'AuditWAVs');
if ~exist(wavFolder,'dir'), mkdir(wavFolder); end

matFile = fullfile(inputFolder,'KH04_MATLAB_Cases.mat');
simFile = fullfile(inputFolder,'KH04_Simulink_Cases.mat');
assert(isfile(matFile) && isfile(simFile), ...
    'KH-04 case files are missing. Run KH04_All_Cases first.');

M = load(matFile,'cases');
S = load(simFile,'cases');
assert(numel(M.cases)==36 && numel(S.cases)==36, ...
    'Expected 36 cases per platform.');
cases = [M.cases(:); S.cases(:)];
caseIds = string({cases.caseId})';
assert(numel(unique(caseIds))==72,'Duplicate case IDs.');

%% 2. Prepare a row for every exported case
nCases = numel(cases);
CaseID = strings(nCases,1);
Platform = strings(nCases,1);
FilterMode = strings(nCases,1);
ActualRateHz = zeros(nCases,1);
EffectiveBits = zeros(nCases,1);
SampleCount = zeros(nCases,1);
Channels = zeros(nCases,1);
DurationSeconds = zeros(nCases,1);
IdealPackedPayloadBytes = zeros(nCases,1);
ActualContainerBits = zeros(nCases,1);
ActualPCMPayloadBytes = zeros(nCases,1);
ActualWAVBytes = zeros(nCases,1);
WAVOverheadBytes = zeros(nCases,1);
ClippedInputSamples = zeros(nCases,1);
ExportMaxError = zeros(nCases,1);
QuantOnlyMSE = zeros(nCases,1);
QuantOnlySNRdB = zeros(nCases,1);
WAVPath = strings(nCases,1);

%% 3. Export, re-import, and measure each real WAV file
fprintf('KH-06: Auditing %d KH-04 processing cases.\n',nCases);
for k = 1:nCases
    c = cases(k);
    id = string(c.caseId);
    audio = double(c.samples(:));
    rate = double(c.Fs);
    bits = double(c.effectiveBits);
    N = numel(audio);
    channelCount = 1;

    assert(all(isfinite(audio)),'Non-finite samples: %s',char(id));
    assert(N == c.sampleCount,'Sample-count metadata mismatch: %s',char(id));
    assert(ismember(bits,[16 8 4 2]),'Unexpected bit depth.');
    assert(ismember(rate,[44100 22050 11025 8000 4000]), ...
        'Unexpected rate.');

    filePath = fullfile(wavFolder,char(id + ".wav"));

    % No amplitude normalization; retain the real KH-04 values.
    % Values beyond [-1,1] may be clipped by the PCM16 encoder.
    clipped = nnz(audio < -1 | audio > 1);
    if clipped > 0
        warning('%s has %d samples outside [-1,1].',char(id),clipped);
    end
    audiowrite(filePath,audio,rate,'BitsPerSample',16);

    % Actual file size and container width, NOT a guessed 44-byte header.
    d = dir(filePath);
    info = audioinfo(filePath);
    [imported, readRate] = audioread(filePath);

    assert(info.SampleRate == rate && readRate == rate, ...
        'Export sampling rate mismatch: %s',char(id));
    assert(info.NumChannels == channelCount && ...
        size(imported,2) == channelCount, ...
        'Export channel mismatch: %s',char(id));
    assert(info.TotalSamples == N && size(imported,1) == N, ...
        'Export sample-count mismatch: %s',char(id));
    assert(info.BitsPerSample == 16, ...
        'Unexpected WAV carrier width: %s',char(id));

    pcmPayload = N * channelCount * info.BitsPerSample / 8;
    headerAndChunks = d.bytes - pcmPayload;
    assert(headerAndChunks >= 0,'Invalid WAV file size: %s',char(id));

    % Quantization-only noise refers to the SAMPLED input, not the
    % time-aligned original. Jesher's aligned NMSE/SNR must be joined later.
    qe = double(c.quantizationError(:));
    assert(numel(qe)==N,'Error-vector length mismatch: %s',char(id));
    sampledInput = audio + qe;
    errorEnergy = sum(qe.^2);
    referenceEnergy = sum(sampledInput.^2);
    if errorEnergy == 0 && referenceEnergy > 0
        quantSNR = Inf;
    elseif referenceEnergy == 0
        quantSNR = NaN;
    else
        quantSNR = 10*log10(referenceEnergy/errorEnergy);
    end

    CaseID(k) = id;
    Platform(k) = string(c.platform);
    FilterMode(k) = string(c.filterMode);
    ActualRateHz(k) = rate;
    EffectiveBits(k) = bits;
    SampleCount(k) = N;
    Channels(k) = channelCount;
    DurationSeconds(k) = N/rate;
    IdealPackedPayloadBytes(k) = ceil(N*channelCount*bits/8);
    ActualContainerBits(k) = info.BitsPerSample;
    ActualPCMPayloadBytes(k) = pcmPayload;
    ActualWAVBytes(k) = d.bytes;
    WAVOverheadBytes(k) = headerAndChunks;
    ClippedInputSamples(k) = clipped;
    ExportMaxError(k) = max(abs(audio-imported(:)));
    QuantOnlyMSE(k) = mean(qe.^2);
    QuantOnlySNRdB(k) = quantSNR;
    WAVPath(k) = string(filePath);

    if mod(k,8)==0 || k==nCases
        fprintf('Checked %d/%d real WAV files.\n',k,nCases);
    end
end

%% 4. Save the measured storage table
Storage = table(CaseID,Platform,FilterMode,ActualRateHz, ...
    EffectiveBits,SampleCount,Channels,DurationSeconds, ...
    IdealPackedPayloadBytes,ActualContainerBits, ...
    ActualPCMPayloadBytes,ActualWAVBytes,WAVOverheadBytes, ...
    ClippedInputSamples,ExportMaxError, ...
    QuantOnlyMSE,QuantOnlySNRdB,WAVPath);

outputCSV = fullfile(outputFolder,'KH06_Storage_Audit_72.csv');
writetable(Storage,outputCSV);

%% 5. Display native-rate examples and sanity checks
native = Storage(Storage.ActualRateHz==44100 & ...
    Storage.FilterMode=="native" & Storage.Platform=="matlab",:);
native = sortrows(native,'EffectiveBits','descend');
disp('===== NATIVE-RATE STORAGE EXAMPLES =====');
disp(native(:,{'EffectiveBits','IdealPackedPayloadBytes', ...
    'ActualContainerBits','ActualWAVBytes', ...
    'WAVOverheadBytes','QuantOnlySNRdB'}));

assert(height(Storage)==72,'Wrong final case count.');
assert(all(Storage.ActualWAVBytes >= Storage.ActualPCMPayloadBytes), ...
    'File smaller than its PCM payload.');
assert(all(Storage.ActualContainerBits==16), ...
    'At least one WAV container is not PCM16.');

fprintf('\nKH-06 audit complete: %d WAV files verified.\n',height(Storage));
fprintf('Audit CSV: %s\n',outputCSV);
fprintf('WAV files: %s\n',wavFolder);
fprintf(['IMPORTANT: These are WAVs exported from Khaled KH-04 arrays.\n', ...
    'Get Jesher''s matching 72-case WAV manifest/metrics for final sign-off.\n']);
