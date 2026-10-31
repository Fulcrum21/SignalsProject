function setup_model(model)
% Called automatically when the model starts, including a direct Run click.
folder = fileparts(get_param(model,'FileName'));
addpath(folder);
workspace = get_param(model,'ModelWorkspace');
if hasVariable(workspace,'demoOverride') && getVariable(workspace,'demoOverride')
    settings = getVariable(workspace,'demoConfig');
else
    settings = SETTINGS();
end
data = prepare_audio(settings);
put(workspace,'inputFrame',data.inputFrame);
put(workspace,'referenceAudio',data.x);
put(workspace,'p',data.p); put(workspace,'q',data.q);
put(workspace,'filterCoefficients',data.h);
put(workspace,'directIndices',data.directIndices);
put(workspace,'filteredIndices',data.filteredIndices);
put(workspace,'useFilter',double(strcmp(data.mode,'lpf')));
put(workspace,'quantStep',data.quantStep);
put(workspace,'quantMin',data.quantMin); put(workspace,'quantMax',data.quantMax);
put(workspace,'bypassQuantizer',double(settings.bits==16));
put(workspace,'reconstructionTail',data.reconstructionTail);
put(workspace,'reconstructionCoefficients',data.reconstructionH);
put(workspace,'referenceIndices',data.referenceIndices);
end

function put(workspace,name,value)
% Leave unchanged arrays alone so Fast Restart does not flag them as edits.
if ~hasVariable(workspace,name) || ~isequaln(getVariable(workspace,name),value)
    assignin(workspace,name,value);
end
end
