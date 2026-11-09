function handoffFiles=Run_Khaled_Handoff()
% Run the teammate's unchanged script in its own workspace: it calls clear.
% It uses Khaled_Quantizer.m and his saved Khaled_Quantizer_Model.slx.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'Matlab'));
generateCases();
close_system('Khaled_Quantizer_Model',0); % Never save runtime data into his model.
[~,handoffFiles]=Load_Khaled_Cases();
end
function generateCases()
Khaled_KH04_All_Cases
end
