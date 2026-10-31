%% Complete experiment: 36 MATLAB cases + the same 36 Simulink cases.
% This script generates everything from the original WAV; no team handoff needed.
demoFolder = fileparts(mfilename('fullpath'));
addpath(demoFolder);
settings = SETTINGS();
[~,sourceFs] = audioread(settings.audioFile);
rates = [sourceFs 22050 11025 8000 4000];
bitsList = [16 8 4 2];
rows = struct([]); comparisons = struct([]); condition = 0;
if ~isfolder(settings.outputFolder), mkdir(settings.outputFolder); end
copyfile(settings.audioFile,fullfile(settings.outputFolder,'original.wav'));
if ~isfile(fullfile(demoFolder,'Audio_Demo.slx')), build_model(); end
load_system(fullfile(demoFolder,'Audio_Demo.slx'));
for rate = rates
    % Reuse the compiled diagram while only bits/filter choice change.
    set_param('Audio_Demo','FastRestart','on');
    if rate==sourceFs, modes={'native'}; else, modes={'lpf','none'}; end
    for modeIndex=1:numel(modes)
        for bitDepth=bitsList
            condition=condition+1;
            settings.targetFs=rate; settings.bits=bitDepth; settings.filterMode=modes{modeIndex};
            % Plot a readable representative selection, not 72 near-identical figures.
            plotThis=(rate==sourceFs && ismember(bitDepth,[16 2])) || ...
                (rate==22050 && bitDepth==8) || (rate==4000 && bitDepth==2);
            [a,matlabSamples]=run_case('matlab',settings,plotThis);
            [b,simulinkSamples]=run_case('simulink',settings,false);
            rows=[rows;a;b]; %#ok<AGROW>
            assert(isequal(size(matlabSamples),size(simulinkSamples)),'Platform lengths differ.');
            difference=max(abs(matlabSamples-simulinkSamples));
            % Below-16-bit outputs should match level for level. Sampling controls
            % can differ by floating-point accumulation order only.
            assert(difference<1e-10,'MATLAB/Simulink outputs disagree; investigate before continuing.');
            comparison=struct('RateHz',rate,'Bits',bitDepth,'Filter',string(modes{modeIndex}), ...
                'MaxSampleDifference',difference,'MatlabNMSE',a.NMSE,'SimulinkNMSE',b.NMSE, ...
                'MatlabSNRdB',a.SNRdB,'SimulinkSNRdB',b.SNRdB);
            comparisons=[comparisons;comparison]; %#ok<AGROW>
            writetable(struct2table(rows),fullfile(settings.outputFolder,'metrics.csv'));
            writetable(struct2table(comparisons),fullfile(settings.outputFolder,'platform_comparison.csv'));
            close(findall(0,'Type','figure','Tag','JesherDemo'));
            fprintf('Condition %2d/36: %5d Hz, %2d bits, %-6s | MATLAB %.4f dB | Simulink %.4f dB\n', ...
                condition,rate,bitDepth,modes{modeIndex},a.SNRdB,b.SNRdB);
        end
    end
    set_param('Audio_Demo','FastRestart','off');
end
metrics=struct2table(rows);
assert(height(metrics)==72 && numel(unique(metrics.CaseID))==72,'Missing or duplicate cases.');
assert(all(metrics.WavClippedSamples==0),'Some WAV exports clipped.');
native=metrics(metrics.RateHz==sourceFs & metrics.Bits==16,:);
assert(all(native.ProcessingNMSE==0 | isnan(native.ProcessingNMSE)),'Unchanged processing control failed.');
sourceInfo=audioinfo(settings.audioFile);
if sourceInfo.NumChannels==1 && sourceInfo.BitsPerSample==16
    assert(all((native.NMSE==0 & native.SNRdB==Inf) | ...
        (isnan(native.NMSE) & isnan(native.SNRdB))),'Unchanged PCM16 control failed.');
end
positive=metrics.NMSE>0 & isfinite(metrics.NMSE);
assert(all(abs(metrics.SNRdB(positive)+10*log10(metrics.NMSE(positive)))<1e-10));
manifest=metrics(:,{'CaseID','Platform','RateHz','Bits','Filter','Samples', ...
    'DurationSeconds','WavContainerBits','WavBytes','WavMaxSampleError','WavFile'});
sourceInfo=audioinfo(settings.audioFile);
sourceFile=dir(fullfile(settings.outputFolder,'original.wav'));
originalRow=manifest(1,:);
originalRow.CaseID="original_recording"; originalRow.Platform="source";
originalRow.RateHz=sourceFs; originalRow.Bits=sourceInfo.BitsPerSample; originalRow.Filter="native";
originalRow.Samples=sourceInfo.TotalSamples; originalRow.DurationSeconds=sourceInfo.Duration;
originalRow.WavContainerBits=sourceInfo.BitsPerSample; originalRow.WavBytes=sourceFile.bytes;
originalRow.WavMaxSampleError=0;
originalRow.WavFile=string(fullfile(settings.outputFolder,'original.wav'));
manifest=[originalRow;manifest];
writetable(manifest,fullfile(settings.outputFolder,'audio_manifest.csv'));
audioFiles=cellstr(metrics.CaseID+'.wav');
archiveFiles=[{'original.wav','audio_manifest.csv'} audioFiles'];
zip(fullfile(settings.outputFolder,'all_audio.zip'),archiveFiles,settings.outputFolder);
% Return the diagram to the single-case settings for the live demonstration.
settings=SETTINGS();
modelWorkspace=get_param('Audio_Demo','ModelWorkspace');
assignin(modelWorkspace,'demoConfig',settings);
setup_model('Audio_Demo');
fprintf('\nDONE: 72 actual cases, 36 platform comparisons, WAVs, figures and audio ZIP.\n');
fprintf('Results: %s\n',settings.outputFolder);
disp(metrics(:,{'Platform','RateHz','Bits','Filter','NMSE','SNRdB'}));
