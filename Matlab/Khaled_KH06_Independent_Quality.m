%% Khaled_KH06_Independent_Quality.m
% CCEN 302 - Independent KH-06 storage / quality integration
%
% Uses Khaled's actual 72 KH-04 processed arrays AND the 72 real WAV files
% created by Khaled_KH06_Storage_Audit.m.
%
% IMPORTANT RECONSTRUCTION ASSUMPTION:
% Lower-rate signals are linearly interpolated to the original 44100-Hz
% time grid, holding the first/last sample beyond their timestamps.
% This is a first-order-hold-style approximate reconstruction, NOT ideal
% bandlimited reconstruction. Metrics can differ from results obtained
% using Signal Processing Toolbox resample() or another reconstruction.

clc;
clear;
close all;

%% 1. Locate all input and output files
scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptFolder);
caseFolder = fullfile(projectRoot,'Results','Khaled','Combined');
storageFolder = fullfile(projectRoot,'Results','Khaled','Storage');

matFile = fullfile(caseFolder,'KH04_MATLAB_Cases.mat');
simFile = fullfile(caseFolder,'KH04_Simulink_Cases.mat');
storageFile = fullfile(storageFolder,'KH06_Storage_Audit_72.csv');
audioFile = fullfile(projectRoot,'Audios','SpeechMusic.wav');
listeningFile = fullfile(storageFolder,'KH06_Listening_Notes.csv');
outputFile = fullfile(storageFolder,'KH06_Storage_Quality_72.csv');

assert(isfile(matFile),'Missing KH04_MATLAB_Cases.mat.');
assert(isfile(simFile),'Missing KH04_Simulink_Cases.mat.');
assert(isfile(storageFile),'Missing KH06_Storage_Audit_72.csv.');
assert(isfile(audioFile),'Missing SpeechMusic.wav.');

%% 2. Read the original signal and the 72 processing cases
[original, originalFs] = audioread(audioFile);
assert(size(original,2)==1 && originalFs==44100, ...
    'Expected the unchanged mono 44100-Hz original recording.');
original = double(original(:));
originalN = numel(original);
refTime = (0:originalN-1)'/originalFs;
referenceEnergy = sum(original.^2);
assert(referenceEnergy > 0, 'Original signal has zero energy.');

M = load(matFile,'cases');
S = load(simFile,'cases');
assert(numel(M.cases)==36 && numel(S.cases)==36, ...
    'Expected exactly 36 MATLAB and 36 Simulink cases.');
cases = [M.cases(:); S.cases(:)];
caseIds = string({cases.caseId})';
assert(numel(unique(caseIds))==72,'Duplicate KH-04 case IDs.');

%% 3. Read and verify the measured storage audit
Storage = readtable(storageFile,'TextType','string');
requiredColumns = { ...
    'CaseID','Platform','FilterMode','ActualRateHz','EffectiveBits', ...
    'SampleCount','Channels','DurationSeconds','IdealPackedPayloadBytes', ...
    'ActualContainerBits','ActualPCMPayloadBytes','ActualWAVBytes', ...
    'WAVOverheadBytes','ClippedInputSamples','ExportMaxError', ...
    'QuantOnlyMSE','QuantOnlySNRdB','WAVPath'};
assert(all(ismember(requiredColumns,Storage.Properties.VariableNames)), ...
    'The storage audit does not contain all required columns.');
assert(height(Storage)==72,'Storage audit must contain 72 rows.');
assert(numel(unique(string(Storage.CaseID)))==72, ...
    'Duplicate storage-audit CaseID values.');

% Match by exact CaseID; never rely on file row order.
[found, auditIndex] = ismember(caseIds,string(Storage.CaseID));
assert(all(found) && numel(unique(auditIndex))==72, ...
    'KH-04 case IDs and storage audit IDs do not match exactly.');
Quality = Storage(auditIndex,:);

%% 4. Compute the full processing and re-imported WAV metrics
nCases = numel(cases);
ProcessingNMSE = zeros(nCases,1);
ProcessingSNRdB = zeros(nCases,1);
ExportedWAV_NMSE = zeros(nCases,1);
ExportedWAV_SNRdB = zeros(nCases,1);
PCM16_ExportMSE = zeros(nCases,1);
PCM16_ExportSNRdB = zeros(nCases,1);
ReconstructionHeldEndSamples = zeros(nCases,1);
MaxWAVReadbackError = zeros(nCases,1);
ReferenceSampleCount = repmat(originalN,nCases,1);
ReferenceRateHz = repmat(originalFs,nCases,1);
ReconstructionMethod = repmat("linear_interpolation_hold_endpoints",nCases,1);
QuantizerSourceProvenance = strings(nCases,1);

fprintf('KH-06: Evaluating %d actual processing cases and WAV exports.\n',nCases);
fprintf('Original: %d samples, %d Hz, %.6f seconds.\n', ...
    originalN,originalFs,originalN/originalFs);

for k = 1:nCases
    c = cases(k);
    id = caseIds(k);
    rate = double(c.Fs);
    bits = double(c.effectiveBits);
    q = double(c.samples(:));
    N = numel(q);

    % Verify metadata against the corresponding storage row.
    assert(N==c.sampleCount && N==Quality.SampleCount(k), ...
        'Sample count mismatch: %s',char(id));
    assert(rate==Quality.ActualRateHz(k) && ...
        bits==Quality.EffectiveBits(k), ...
        'Rate/bit-depth mismatch: %s',char(id));
    assert(strcmp(string(c.platform),string(Quality.Platform(k))) && ...
        strcmp(string(c.filterMode),string(Quality.FilterMode(k))), ...
        'Platform/filter mismatch: %s',char(id));
    assert(Quality.Channels(k)==1 && all(isfinite(q)), ...
        'Expected finite mono processed samples: %s',char(id));
    assert(abs(N/rate - Quality.DurationSeconds(k))<1e-7, ...
        'Duration mismatch: %s',char(id));
    assert(ceil(N*bits/8)==Quality.IdealPackedPayloadBytes(k), ...
        'Theoretical storage mismatch: %s',char(id));

    % Read back the user's OWN WAV file from KH-06 (not the demo export).
    wavPath = char(string(Quality.WAVPath(k)));
    if ~isfile(wavPath)
        % Helpful when copying the repository to a new local folder.
        wavPath = fullfile(storageFolder,'AuditWAVs',char(id + ".wav"));
    end
    assert(isfile(wavPath),'Exported WAV not found for: %s',char(id));
    [wavSignal,wavFs] = audioread(wavPath);
    wavInfo = audioinfo(wavPath);
    wavFileInfo = dir(wavPath);
    wavSignal = double(wavSignal(:));

    assert(wavFs==rate && wavInfo.SampleRate==rate, ...
        'WAV sample-rate mismatch: %s',char(id));
    assert(wavInfo.TotalSamples==N && numel(wavSignal)==N, ...
        'WAV length mismatch: %s',char(id));
    assert(wavInfo.NumChannels==1 && wavInfo.BitsPerSample==16, ...
        'Unexpected WAV channel count/container width: %s',char(id));
    assert(wavFileInfo.bytes==Quality.ActualWAVBytes(k), ...
        'WAV file bytes changed since the storage audit: %s',char(id));
    assert(all(isfinite(wavSignal)), ...
        'Non-finite WAV readback values: %s',char(id));

    % Align the *processed* signal to the original 44.1-kHz time grid.
    % Clamp query time to available sample range to avoid extrapolation.
    [alignedProcessed, heldEnd] = linearHoldToReference(q,rate,refTime);
    alignedExportedWAV = linearHoldToReference(wavSignal,rate,refTime);
    ReconstructionHeldEndSamples(k) = heldEnd;

    % Full degradation due to BOTH sampling AND quantization.
    [ProcessingNMSE(k),ProcessingSNRdB(k)] = ...
        nmseAndSNR(original,alignedProcessed,referenceEnergy);

    % Full degradation including PCM16 WAV export/readback.
    [ExportedWAV_NMSE(k),ExportedWAV_SNRdB(k)] = ...
        nmseAndSNR(original,alignedExportedWAV,referenceEnergy);

    % Additional error from the WAV encoding at the CASE's native rate.
    exportError = q-wavSignal;
    PCM16_ExportMSE(k) = mean(exportError.^2);
    MaxWAVReadbackError(k) = max(abs(exportError));
    inputEnergy = sum(q.^2);
    if inputEnergy == 0
        PCM16_ExportSNRdB(k) = NaN;
    elseif all(exportError==0)
        PCM16_ExportSNRdB(k) = Inf;
    else
        PCM16_ExportSNRdB(k) = ...
            10*log10(inputEnergy/sum(exportError.^2));
    end

    assert(abs(MaxWAVReadbackError(k)-Quality.ExportMaxError(k))<1e-10, ...
        'WAV readback differs from earlier export audit: %s',char(id));
    QuantizerSourceProvenance(k) = string(c.provenance);

    if mod(k,8)==0 || k==nCases
        fprintf('Evaluated %d/%d cases.\n',k,nCases);
    end
end

%% 5. Preserve real listening notes; create a worksheet on first run
if isfile(listeningFile)
    % Accept both the earlier six-column listening worksheet and the
    % newer five-column worksheet. Never discard existing listening notes.
    % 'preserve' also avoids renaming user-edited CSV headers silently.
    Notes = readtable(listeningFile, ...
        'Delimiter', ',', ...
        'TextType', 'string', ...
        'VariableNamingRule', 'preserve');
    existingColumns = string(Notes.Properties.VariableNames);

    if ~ismember("CaseID",existingColumns)
        fprintf('Listening CSV columns found:\n');
        disp(Notes.Properties.VariableNames');
        error('Listening sheet needs a CaseID column. Original file was not changed.');
    end

    % Legacy worksheet fields:
    % CaseID, Listener, ListeningNotes, PlaybackVerified,
    % ListeningDate, ListeningSetup.
    if ~ismember("PlaybackStatus",existingColumns)
        Notes.PlaybackStatus = repmat("not_tested",height(Notes),1);
        if ismember("PlaybackVerified",existingColumns)
            verifiedText = lower(strtrim(string(Notes.PlaybackVerified)));
            verified = ismember(verifiedText,["true","1","yes","y"]);
            Notes.PlaybackStatus(verified) = "played";
        end
    end
    if ~ismember("PlaybackDevice",existingColumns)
        if ismember("ListeningSetup",existingColumns)
            Notes.PlaybackDevice = string(Notes.ListeningSetup);
        else
            Notes.PlaybackDevice = repmat("not_recorded",height(Notes),1);
        end
    end
    if ~ismember("Listener",existingColumns)
        Notes.Listener = repmat("not_recorded",height(Notes),1);
    end
    if ~ismember("ListeningNotes",existingColumns)
        Notes.ListeningNotes = repmat("not_recorded",height(Notes),1);
    end

    % Validate by case ID; never join listening notes by CSV row order.
    assert(height(Notes)==72 && ...
        numel(unique(string(Notes.CaseID)))==72, ...
        'Listening sheet must have 72 unique case IDs.');
    [notesFound,notesIndex] = ismember(caseIds,string(Notes.CaseID));
    assert(all(notesFound),'Listening sheet has unmatched case IDs.');
    Notes = Notes(notesIndex,:);
    fprintf(['Loaded existing listening notes; handled legacy column names ', ...
        'without modifying the source CSV.\n']);
else
    CaseID = caseIds;
    PlaybackStatus = repmat("not_tested",nCases,1);
    Listener = repmat("not_recorded",nCases,1);
    PlaybackDevice = repmat("not_recorded",nCases,1);
    ListeningNotes = repmat("not_recorded",nCases,1);
    Notes = table(CaseID,PlaybackStatus,Listener, ...
        PlaybackDevice,ListeningNotes);
    writetable(Notes,listeningFile);
    fprintf('Created a listening worksheet; no observations were invented.\n');
end

%% 6. Add metrics and notes to the actual storage audit
Quality.ProcessingNMSE = ProcessingNMSE;
Quality.ProcessingSNRdB = ProcessingSNRdB;
Quality.ExportedWAV_NMSE = ExportedWAV_NMSE;
Quality.ExportedWAV_SNRdB = ExportedWAV_SNRdB;
Quality.PCM16_ExportMSE = PCM16_ExportMSE;
Quality.PCM16_ExportSNRdB = PCM16_ExportSNRdB;
Quality.ReconstructionHeldEndSamples = ReconstructionHeldEndSamples;
Quality.MaxWAVReadbackError = MaxWAVReadbackError;
Quality.ReferenceSampleCount = ReferenceSampleCount;
Quality.ReferenceRateHz = ReferenceRateHz;
Quality.ReconstructionMethod = ReconstructionMethod;
Quality.QuantizerSourceProvenance = QuantizerSourceProvenance;
Quality.PlaybackStatus = string(Notes.PlaybackStatus);
Quality.Listener = string(Notes.Listener);
Quality.PlaybackDevice = string(Notes.PlaybackDevice);
Quality.ListeningNotes = string(Notes.ListeningNotes);

assert(height(Quality)==72 && ...
    numel(unique(string(Quality.CaseID)))==72, ...
    'Final storage-quality matrix is incomplete.');
writetable(Quality,outputFile);

%% 7. Print simple native-rate checks
nativeMask = Quality.ActualRateHz==44100 & ...
    Quality.Platform=="matlab" & Quality.FilterMode=="native";
native = sortrows(Quality(nativeMask,:), 'EffectiveBits','descend');
assert(height(native)==4,'Expected four native-rate MATLAB cases.');
assert(native.ProcessingNMSE(1)==0 && ...
    isinf(native.ProcessingSNRdB(1)), ...
    'The native 16-bit control is no longer unchanged.');

fprintf('\n===== INDEPENDENT KH-06: NATIVE-RATE MATLAB =====\n');
disp(native(:,{'EffectiveBits','IdealPackedPayloadBytes', ...
    'ActualWAVBytes','QuantOnlySNRdB', ...
    'ProcessingNMSE','ProcessingSNRdB','ExportedWAV_SNRdB'}));

fprintf('\nSUCCESS: 72 storage-quality rows generated.\n');
fprintf('Table: %s\n',outputFile);
fprintf('Listening worksheet: %s\n',listeningFile);
fprintf(['CAUTION: Total-processing figures use LINEAR interpolation ', ...
    'with endpoint holding, not ideal reconstruction.\n']);
fprintf(['Listening notes remain not_tested until you actually ', ...
    'listen and record observations.\n']);

%% Local functions
function [yAligned,nHeldAfter] = linearHoldToReference(y,Fs,tReference)
    y = double(y(:));
    n = numel(y);
    assert(n >= 2 && Fs > 0,'Invalid signal for interpolation.');
    tSource = (0:n-1)' / Fs;
    nHeldAfter = nnz(tReference > tSource(end));
    % Hold endpoints (no extrapolation) and linearly interpolate interior.
    tClamped = min(max(tReference,tSource(1)),tSource(end));
    yAligned = interp1(tSource,y,tClamped,'linear');
    yAligned = double(yAligned(:));
    assert(numel(yAligned)==numel(tReference) && ...
        all(isfinite(yAligned)),'Invalid aligned signal.');
end

function [nmse,snrDb] = nmseAndSNR(ref,processed,refEnergy)
    diffSamples = double(ref(:))-double(processed(:));
    errorEnergy = sum(diffSamples.^2);
    nmse = errorEnergy/refEnergy;
    if errorEnergy == 0
        snrDb = Inf;
    else
        snrDb = 10*log10(refEnergy/errorEnergy);
    end
end
