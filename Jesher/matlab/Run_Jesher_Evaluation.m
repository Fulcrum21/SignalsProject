function summary = Run_Jesher_Evaluation(varargin)
%RUN_JESHER_EVALUATION Evaluate real handoffs without modifying team sources.
% From the repository root:
%   addpath(fullfile(pwd,'Jesher','matlab'));
%   summary = Run_Jesher_Evaluation();
% Future handoffs: save a cases struct vector using inputs/README.md.
% This function does not run teammates' scripts, simulate, or play audio.
p = inputParser;
addParameter(p,'OutputFolder','',@(x)ischar(x) || isstring(x));
addParameter(p,'HandoffFiles',{},@(x)iscell(x) || isstring(x));
addParameter(p,'RequireComplete',false,@(x)islogical(x) && isscalar(x));
addParameter(p,'MakePlots',true,@(x)islogical(x) && isscalar(x));
parse(p,varargin{:});
options = p.Results;
ownerRoot = fileparts(fileparts(mfilename('fullpath')));
repoRoot = fileparts(ownerRoot);
if isstring(options.HandoffFiles)
    handoffs = cellstr(options.HandoffFiles);
else
    handoffs = options.HandoffFiles;
end
assert(isempty(handoffs) || (iscellstr(handoffs) && isvector(handoffs)), ...
    'jesher:HandoffPaths','HandoffFiles must be a cell vector of paths or a string vector.');
if isempty(handoffs)
    found = dir(fullfile(ownerRoot,'inputs','*.mat'));
    handoffs = arrayfun(@(f)fullfile(f.folder,f.name),found,'UniformOutput',false);
end
[cases,reference,referenceFs,sourcePath] = jesher.loadAvailableCases(repoRoot,handoffs);
coverage = jesher.validateCases(cases,reference);
isComplete = all(coverage.status == "available");
if options.RequireComplete && ~isComplete
    error('jesher:IncompleteMatrix', ...
        'Only %d/72 real cases available. Obtain missing handoffs before a final run.',numel(cases));
end
if any([cases.Fs] ~= referenceFs) && exist('resample','file') ~= 2
    error('jesher:MissingSignalToolbox', ...
        ['Signal Processing Toolbox is required for sample-grid reconstruction. ' ...
        'Install the MathWorks toolbox, restart MATLAB, and rerun the tests.']);
end
% Validate time bases and carrier range before writing a result folder.
for j = 1:numel(cases)
    jesher.alignToReference(reference,referenceFs,cases(j));
    assert(all(cases(j).samples >= -1 & cases(j).samples <= 1-2^-15), ...
        'jesher:ExportRange','Case %s exceeds the PCM16 range; resolve with its owner.',cases(j).caseId);
end
if strlength(string(options.OutputFolder)) == 0
    stamp = char(datetime('now','TimeZone','Asia/Dubai','Format','yyyyMMdd_HHmmss_SSS'));
    outputFolder = fullfile(ownerRoot,'results',['matlab_run_' stamp]);
else
    outputFolder = char(options.OutputFolder);
end
assert(~isfolder(outputFolder) && ~isfile(outputFolder), ...
    'jesher:OutputExists','Choose a new output folder to prevent stale/mixed results.');
mkdir(outputFolder);
snapshotFolder = fullfile(outputFolder,'input_snapshot');
mkdir(snapshotFolder);
snapshotSources = handoffs(:);
prototypePath = fullfile(repoRoot,'Results','Abdulrahman','AA02','sampling_22050.mat');
if isfile(prototypePath)
    snapshotSources{end+1,1} = prototypePath;
end
snapshotFiles = cell(numel(snapshotSources),1);
for j = 1:numel(snapshotSources)
    [~,name,extension] = fileparts(snapshotSources{j});
    snapshotFiles{j} = sprintf('%03d_%s%s',j,name,extension);
    copyfile(snapshotSources{j},fullfile(snapshotFolder,snapshotFiles{j}));
end
packageRoot = fullfile(outputFolder,'audio_package');
mkdir(fullfile(packageRoot,'original'));
mkdir(fullfile(packageRoot,'processed'));
copyfile(sourcePath,fullfile(packageRoot,'original','SpeechMusic.wav'));
results = repmat(resultTemplate(),numel(cases),1);
manifest = repmat(manifestTemplate(),numel(cases)+1,1);
sourceInfo = audioinfo(sourcePath);
sourceFile = dir(sourcePath);
manifest(1) = struct('caseId',"original_recording",'platform',"source", ...
    'wavFile',"original/SpeechMusic.wav",'Fs',referenceFs,'effectiveBits',16, ...
    'containerBits',sourceInfo.BitsPerSample,'channels',sourceInfo.NumChannels, ...
    'sampleCount',numel(reference),'durationSeconds',numel(reference)/referenceFs, ...
    'fileBytes',sourceFile.bytes,'maxAbsRoundTripError',0,'rmsRoundTripError',0, ...
    'clippedSamples',0);
for j = 1:numel(cases)
    c = cases(j);
    [aligned,a] = jesher.alignToReference(reference,referenceFs,c);
    m = jesher.computeMetrics(reference,aligned);
    relativeWav = "processed/" + string(c.caseId) + ".wav";
    wavPath = fullfile(packageRoot,'processed',[char(c.caseId) '.wav']);
    w = jesher.exportVerifiedWav(c.samples,c.Fs,wavPath);
    exportedCase = c;
    exportedCase.samples = audioread(wavPath);
    exportedAligned = jesher.alignToReference(reference,referenceFs,exportedCase);
    exportedMetrics = jesher.computeMetrics(reference,exportedAligned);
    r = resultTemplate();
    r.caseId = string(c.caseId);
    r.platform = string(c.platform);
    r.sourceFile = string(c.sourceFile);
    r.Fs = c.Fs;
    r.effectiveBits = c.effectiveBits;
    r.filterMode = string(c.filterMode);
    r.sampleCount = numel(c.samples);
    r.durationSeconds = numel(c.samples)/c.Fs;
    r.firstSampleTimeSeconds = c.firstSampleTimeSeconds;
    r.lastSampleTimeSeconds = c.firstSampleTimeSeconds+(numel(c.samples)-1)/c.Fs;
    r.comparisonFirstTimeSeconds = a.firstTimeSeconds;
    r.comparisonLastTimeSeconds = a.lastTimeSeconds;
    r.comparisonSampleCount = a.sampleCount;
    r.alignmentPolicy = string(a.policy);
    r.nmse = m.nmse;
    r.snrDb = m.snrDb;
    r.metricStatus = string(m.status);
    r.referenceEnergy = m.referenceEnergy;
    r.errorEnergy = m.errorEnergy;
    r.exportedNmse = exportedMetrics.nmse;
    r.exportedSnrDb = exportedMetrics.snrDb;
    r.wavFile = relativeWav;
    r.wavContainerBits = w.containerBits;
    r.wavFileBytes = w.fileBytes;
    r.wavMaxAbsRoundTripError = w.maxAbsRoundTripError;
    r.wavRmsRoundTripError = w.rmsRoundTripError;
    r.processingStage = string(c.processingStage);
    r.quantizationApplied = c.quantizationApplied;
    r.quantizerDescription = string(c.quantizerDescription);
    r.samplingDescription = string(c.samplingDescription);
    r.provenance = string(c.provenance);
    results(j) = r;
    manifest(j+1) = struct('caseId',string(c.caseId),'platform',string(c.platform), ...
        'wavFile',relativeWav,'Fs',c.Fs,'effectiveBits',c.effectiveBits, ...
        'containerBits',w.containerBits,'channels',1,'sampleCount',w.sampleCount, ...
        'durationSeconds',w.durationSeconds,'fileBytes',w.fileBytes, ...
        'maxAbsRoundTripError',w.maxAbsRoundTripError, ...
        'rmsRoundTripError',w.rmsRoundTripError,'clippedSamples',w.clippedSamples);
end
resultTable = struct2table(results);
manifestTable = struct2table(manifest);
platformTable = jesher.comparePlatforms(cases,resultTable);
writetable(resultTable,fullfile(outputFolder,'metrics.csv'));
writetable(coverage,fullfile(outputFolder,'case_coverage.csv'));
writetable(platformTable,fullfile(outputFolder,'platform_comparison.csv'));
writetable(manifestTable,fullfile(packageRoot,'manifest.csv'));
writetable(coverage,fullfile(packageRoot,'case_coverage.csv'));
if options.MakePlots
    plotFolder = fullfile(outputFolder,'figures');
    mkdir(plotFolder);
    for j = 1:numel(cases)
        % All available cases get comparable plots; IDs keep outputs separate.
        jesher.plotCase(reference,referenceFs,cases(j),plotFolder);
    end
end
summary = struct('createdAtDubai',char(datetime('now','TimeZone','Asia/Dubai')), ...
    'matlabVersion',version,'toolboxes',ver,'sourceFile',sourcePath, ...
    'sourceSampleCount',numel(reference),'sourceRateHz',referenceFs, ...
    'availableCases',numel(cases),'expectedCases',72,'matrixComplete',isComplete, ...
    'handoffFiles',{handoffs},'outputFolder',outputFolder, ...
    'snapshotSources',{snapshotSources},'snapshotFiles',{snapshotFiles}, ...
    'speakerPlaybackVerified',false,'listeningCollected',false, ...
    'reviewerAccepted',false,'finalSignOff',false);
% A complete matrix still needs actual listening, review, and final sign-off.
if isComplete
    archiveName = 'audio_all_cases_UNREVIEWED.zip';
else
    archiveName = 'audio_partial_NOT_FINAL.zip';
end
zip(fullfile(outputFolder,archiveName), ...
    {'original','processed','manifest.csv','case_coverage.csv'},packageRoot);
% Verify archive content/bytes against the staging package before delivery.
verifyFolder = fullfile(outputFolder,'archive_verification');
unzip(fullfile(outputFolder,archiveName),verifyFolder);
for j = 1:height(manifestTable)
    rel = char(manifestTable.wavFile(j));
    originalBytes = readBytes(fullfile(packageRoot,rel));
    zippedBytes = readBytes(fullfile(verifyFolder,rel));
    assert(isequal(originalBytes,zippedBytes), 'jesher:ArchiveMismatch', ...
        'Archive bytes do not match manifest source: %s',rel);
end
metadataFiles = {'manifest.csv','case_coverage.csv'};
for j = 1:numel(metadataFiles)
    assert(isequal(readBytes(fullfile(packageRoot,metadataFiles{j})), ...
        readBytes(fullfile(verifyFolder,metadataFiles{j}))), ...
        'jesher:ArchiveMismatch','Archive metadata differs from staging.');
end
unpacked = dir(fullfile(verifyFolder,'**','*'));
unpacked = unpacked(~[unpacked.isdir]);
actualFiles = strings(numel(unpacked),1);
[pathResolved,verifyAttributes] = fileattrib(verifyFolder);
assert(pathResolved,'jesher:ArchiveMismatch','Cannot resolve verification folder.');
verifyAbsolute = verifyAttributes.Name;
for j = 1:numel(unpacked)
    full = fullfile(unpacked(j).folder,unpacked(j).name);
    % dir supplies absolute folder names even if OutputFolder was relative.
    actualFiles(j) = replace(string(full(numel(verifyAbsolute)+2:end)),"\", "/");
end
expectedFiles = [manifestTable.wavFile; string(metadataFiles(:))];
assert(isequal(sort(actualFiles),sort(expectedFiles)), ...
    'jesher:ArchiveMismatch','Archive file set does not exactly match its manifest and coverage.');
summary.archiveBytesVerified = true;
summary.archiveFile = archiveName;
save(fullfile(outputFolder,'evaluation.mat'),'cases','reference','referenceFs', ...
    'results','coverage','platformTable','summary','-v7');
fid = fopen(fullfile(outputFolder,'run_summary.json'),'w');
assert(fid >= 0,'jesher:Write','Cannot write run summary.');
closer = onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(summary,'PrettyPrint',true));
fprintf('Evaluated %d/72 cases. Output: %s\n',numel(cases),outputFolder);
fprintf('Speaker checks, listening, review and final sign-off remain pending.\n');
end

function bytes = readBytes(path)
fid = fopen(path,'rb');
assert(fid >= 0,'jesher:Read','Cannot read archive verification file.');
closer = onCleanup(@()fclose(fid)); %#ok<NASGU>
bytes = fread(fid,Inf,'*uint8');
end

function r = resultTemplate()
r = struct('caseId',"",'platform',"",'sourceFile',"",'Fs',0,'effectiveBits',0, ...
    'filterMode',"",'sampleCount',0,'durationSeconds',0,'firstSampleTimeSeconds',0, ...
    'lastSampleTimeSeconds',0,'comparisonFirstTimeSeconds',0, ...
    'comparisonLastTimeSeconds',0,'comparisonSampleCount',0,'alignmentPolicy',"", ...
    'nmse',NaN,'snrDb',NaN,'metricStatus',"",'referenceEnergy',NaN,'errorEnergy',NaN, ...
    'exportedNmse',NaN,'exportedSnrDb',NaN,'wavFile',"",'wavContainerBits',0, ...
    'wavFileBytes',0,'wavMaxAbsRoundTripError',NaN,'wavRmsRoundTripError',NaN, ...
    'processingStage',"",'quantizationApplied',false,'quantizerDescription',"", ...
    'samplingDescription',"",'provenance',"");
end

function m = manifestTemplate()
m = struct('caseId',"",'platform',"",'wavFile',"",'Fs',0,'effectiveBits',0, ...
    'containerBits',0,'channels',1,'sampleCount',0,'durationSeconds',0,'fileBytes',0, ...
    'maxAbsRoundTripError',NaN,'rmsRoundTripError',NaN,'clippedSamples',0);
end
