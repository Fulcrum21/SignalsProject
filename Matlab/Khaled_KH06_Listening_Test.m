
%% KH-06 - Listening Evaluation

clc;
clear;

%% 1. Locate project
scriptFolder = fileparts(which('Khaled_Quantizer'));
root = fileparts(scriptFolder);

storageFolder = fullfile(root, ...
    'Results', 'Khaled', 'Storage');

auditPath = fullfile(storageFolder, ...
    'KH06_Storage_Audit_72.csv');

notesPath = fullfile(storageFolder, ...
    'KH06_Listening_Notes.csv');

%% 2. Load existing files
T = readtable(auditPath, ...
    'Delimiter', ',', 'TextType', 'string');

Notes = readtable(notesPath, ...
    'Delimiter', ',', ...
    'TextType', 'string', ...
    'VariableNamingRule', 'preserve');

assert(height(Notes) == 72);
assert(numel(unique(Notes.CaseID)) == 72);

%% 3. Choose representative cases
caseIDs = [
    "speechmusic_fs44100_b16_native_matlab"
    "speechmusic_fs44100_b08_native_matlab"
    "speechmusic_fs44100_b04_native_matlab"
    "speechmusic_fs44100_b02_native_matlab"
    "speechmusic_fs8000_b04_lpf_matlab"
    "speechmusic_fs8000_b04_none_matlab"
    "speechmusic_fs4000_b02_lpf_matlab"
    "speechmusic_fs4000_b02_none_matlab"
    "speechmusic_fs8000_b04_lpf_simulink"
];

%% 4. Backup current listening worksheet
backupPath = fullfile(storageFolder, ...
    ['Listening_Backup_' ...
    datestr(now,'yyyymmdd_HHMMSS') '.csv']);

copyfile(notesPath, backupPath);

%% 5. Ask for playback setup
device = string(input( ...
    'Playback device (e.g. laptop speakers): ', 's'));

if strlength(device) == 0
    device = "not_recorded";
end

%% 6. Play recordings and collect observations
for k = 1:numel(caseIDs)

    id = caseIDs(k);

    auditIdx = find(T.CaseID == id, 1);
    noteIdx = find(Notes.CaseID == id, 1);

    assert(~isempty(auditIdx), ...
        'Case missing from storage audit.');

    assert(~isempty(noteIdx), ...
        'Case missing from listening sheet.');

    wavPath = string(T.WAVPath(auditIdx));

    if ~isfile(wavPath)
        wavPath = fullfile(root, wavPath);
    end

    assert(isfile(wavPath), ...
        'WAV file not found.');

    [y, Fs] = audioread(wavPath);

    fprintf('\n==============================\n');
    fprintf('Recording %d of %d\n', ...
        k, numel(caseIDs));

    fprintf('Case: %s\n', id);
    fprintf('Rate: %d Hz\n', Fs);
    fprintf('==============================\n');

    disp('Playing audio...');

    player = audioplayer(y, Fs);
    playblocking(player);

    disp('Playback finished.');

    observation = strtrim(input( ...
        'What did you hear? (Enter to skip): ', 's'));

    if isempty(observation)
        disp('Skipped; previous notes preserved.');
        continue;
    end

    % Record actual observation
    Notes.PlaybackStatus(noteIdx) = "tested";
    Notes.Listener(noteIdx) = "self";
    Notes.PlaybackDevice(noteIdx) = device;
    Notes.ListeningNotes(noteIdx) = ...
        string(observation);

    % Save after every completed observation
    writetable(Notes, notesPath, ...
        'Delimiter', ',', ...
        'WriteVariableNames', true);

    disp('Observation saved successfully.');

end

%% 7. Final results
tested = sum(Notes.PlaybackStatus == "tested");

fprintf('\n===== LISTENING TEST COMPLETE =====\n');
fprintf('Cases marked tested: %d / 72\n', tested);

disp('Listening notes saved successfully.');
