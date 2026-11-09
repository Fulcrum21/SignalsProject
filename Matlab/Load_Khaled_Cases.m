function [cases,handoffFiles]=Load_Khaled_Cases(handoffFiles)
% Read Khaled's two producer files verbatim. No regeneration or requantization.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin==0
    folder=fullfile(root,'Results','Khaled','Combined');
    handoffFiles={fullfile(folder,'KH04_MATLAB_Cases.mat'), ...
        fullfile(folder,'KH04_Simulink_Cases.mat')};
end
assert(iscell(handoffFiles) && numel(handoffFiles)==2,'Supply Khaled''s two KH04 handoffs.');
assert(all(cellfun(@isfile,handoffFiles)),'Run Run_Khaled_Handoff to generate the local MATs.');
m=load(handoffFiles{1},'cases'); s=load(handoffFiles{2},'cases');
assert(numel(m.cases)==36 && numel(s.cases)==36,'Expected 36 cases per platform.');
assert(all(strcmp({m.cases.platform},'matlab')) && all(strcmp({s.cases.platform},'simulink')));
cases=[m.cases(:);s.cases(:)];
assert(numel(unique(string({cases.caseId})))==72,'Duplicate Khaled case IDs.');
end
