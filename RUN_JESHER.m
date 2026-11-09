%% Jesher's part: evaluate Khaled's actual 36 MATLAB + 36 Simulink outputs.
% Run this when sampling is ready. RUN_PROJECT also calls it after regeneration.
projectRoot=fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot,'Matlab'),fullfile(projectRoot,'Jesher','matlab'));
caseFolder=fullfile(projectRoot,'Results','Khaled','Combined');
if ~isfile(fullfile(caseFolder,'KH04_MATLAB_Cases.mat')) || ...
        ~isfile(fullfile(caseFolder,'KH04_Simulink_Cases.mat'))
    Run_Khaled_Handoff(); % Generate with HIS script/model if local MATs are absent.
end
[~,handoffFiles]=Load_Khaled_Cases();
runName=['khaled_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))];
evaluationFolder=fullfile(projectRoot,'Results','Integrated',runName);
summary=Run_Jesher_Evaluation('HandoffFiles',handoffFiles, ...
    'OutputFolder',evaluationFolder,'RequireComplete',true,'MakePlots',false);
Make_Integrated_Results(evaluationFolder,handoffFiles);
CHECK_INTEGRATION(evaluationFolder,handoffFiles);
Write_Integrated_Report(evaluationFolder);
fid=fopen(fullfile(projectRoot,'Results','Integrated','latest_run.txt'),'w');
assert(fid>=0,'Cannot save the latest run location.');
fprintf(fid,'%s\n',runName); fclose(fid);
fprintf('\nDONE: Jesher evaluated Khaled''s actual 72 handoff cases.\nResults: %s\n',evaluationFolder);
