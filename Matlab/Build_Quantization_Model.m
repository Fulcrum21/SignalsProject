function Build_Quantization_Model()
% Create a small readable model. Normal runs use the saved model in Simulink.
root = fileparts(fileparts(mfilename('fullpath')));
model = 'Quantization_Khaled';
assert(~bdIsLoaded(model),'Close Quantization_Khaled before rebuilding.');
load_system('simulink'); new_system(model);
set_param(model,'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
    'FixedStep','1','StopTime','0','ReturnWorkspaceOutputs','on', ...
    'SaveTime','off','SaveOutput','off','SignalLogging','off');
workspace = get_param(model,'ModelWorkspace');
workspace.DataSource = 'Model File'; % Saved empty; runtime samples are not saved.
% Default input when opened and run manually. RUN_DEMO supplies the chosen case.
set_param(model,'InitFcn', ...
    'addpath(fullfile(fileparts(fileparts(get_param(''Quantization_Khaled'',''FileName''))),''Matlab'')); Setup_Quantization_Model;');
add_block('simulink/Sources/Constant',[model '/Sampling output'], ...
    'Value','inputSamples','VectorParams1D','off','SampleTime','1','Position',[30 100 150 140]);
add_block('simulink/Math Operations/Gain',[model '/Divide by step'], ...
    'Gain','1/quantStep','Position',[200 35 290 75]);
add_block('simulink/Math Operations/Rounding Function',[model '/Round index'], ...
    'Operator','round','Position',[340 35 430 75]);
add_block('simulink/Discontinuities/Saturation',[model '/Limit signed index'], ...
    'LowerLimit','minimumIndex','UpperLimit','maximumIndex','Position',[480 35 590 75]);
add_block('simulink/Math Operations/Gain',[model '/Multiply by step'], ...
    'Gain','quantStep','Position',[640 35 740 75]);
add_block('simulink/Sources/Constant',[model '/16 bit bypass'], ...
    'Value','bypassQuantizer','Position',[620 130 730 160]);
add_block('simulink/Signal Routing/Switch',[model '/Control or quantized'], ...
    'Criteria','u2 ~= 0','Position',[800 95 850 195]);
add_block('simulink/Sinks/To Workspace',[model '/Quantized samples'], ...
    'VariableName','quantizedSamples','SaveFormat','Array','Position',[930 110 1070 150]);
add_block('simulink/Math Operations/Sum',[model '/Quantization error'], ...
    'Inputs','+-','IconShape','rectangular','Position',[800 270 850 320]);
add_block('simulink/Sinks/To Workspace',[model '/Error samples'], ...
    'VariableName','quantizationError','SaveFormat','Array','Position',[930 280 1070 320]);
wire(model,'Sampling output/1','Divide by step/1');
wire(model,'Divide by step/1','Round index/1');
wire(model,'Round index/1','Limit signed index/1');
wire(model,'Limit signed index/1','Multiply by step/1');
wire(model,'Sampling output/1','Control or quantized/1');
wire(model,'16 bit bypass/1','Control or quantized/2');
wire(model,'Multiply by step/1','Control or quantized/3');
wire(model,'Control or quantized/1','Quantized samples/1');
wire(model,'Sampling output/1','Quantization error/1');
wire(model,'Control or quantized/1','Quantization error/2');
wire(model,'Quantization error/1','Error samples/1');
note = Simulink.Annotation(model,sprintf(['Run RUN_DEMO from the project root. Input = actual sampling-stage output.\n' ...
    'One frame holds the complete recording. Stop time 0 processes the frame once.\n' ...
    'Uniform signed levels: delta = 2/2^B; round; saturate; scale. B=16 bypasses.\n' ...
    'Jesher evaluates and exports the logged output in MATLAB after simulation.']));
note.Position=[25 380]; note.FontSize=11;
set_param(model,'Location',[30 60 1180 650]);
% Use the same saved format as the team's sampling models. Execution is tested
% in R2026b here; exporting a format is not a claim of an R2026a runtime test.
temporaryFolder=tempname; mkdir(temporaryFolder);
temporaryModel=fullfile(temporaryFolder,[model '.slx']);
save_system(model,temporaryModel); % Export requires a saved, unmodified source.
Simulink.exportToVersion(model,fullfile(root,'Simulink',[model '.slx']),'R2026a');
close_system(model,0);
delete(temporaryModel); rmdir(temporaryFolder); % Only this one generated file.
end
function wire(model,source,destination)
add_line(model,source,destination,'autorouting','on');
end
