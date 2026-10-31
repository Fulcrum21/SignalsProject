function build_model()
% Rebuild the visible Simulink diagram. Normal runs use the saved .slx file.
folder = fileparts(mfilename('fullpath'));
model = 'Audio_Demo';
assert(~bdIsLoaded(model),'Close Audio_Demo before rebuilding it.');
load_system('simulink'); load_system('dspmlti4');
new_system(model);
workspace = get_param(model,'ModelWorkspace');
workspace.DataSource = 'MATLAB Code';
workspace.MATLABCode = ''; % Runtime audio is loaded by InitFcn, not stored in .slx.
set_param(model,'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
    'FixedStep','1','StartTime','0','StopTime','0','ReturnWorkspaceOutputs','on', ...
    'SignalLogging','off','SaveTime','off','SaveOutput','off', ...
    'SignalInfNanChecking','none');
set_param(model,'InitFcn', ...
    'addpath(fileparts(get_param(''Audio_Demo'',''FileName''))); setup_model(''Audio_Demo'');');

constant([model '/Audio frame'],'inputFrame',[30 105 120 145]);
sub = [model '/Sampling'];
add_block('built-in/Subsystem',sub,'Position',[180 85 350 165]);
inport(sub,'In',1,[20 90 50 110]);
rateBlock(sub,'Anti alias FIR and rate change','p','q','filterCoefficients',[100 30 250 85]);
selector(sub,'Remove known FIR delay','filteredIndices',[300 30 440 85]);
selector(sub,'Select source times without filtering','directIndices',[100 150 300 200]);
constant([sub '/Filter choice'],'useFilter',[340 115 390 145]);
add_block('simulink/Signal Routing/Switch',[sub '/Choose filtered or direct'], ...
    'Criteria','u2 ~= 0','Position',[490 60 530 160]);
outport(sub,'Out',1,[590 95 620 115]);
wire(sub,'In/1','Anti alias FIR and rate change/1');
wire(sub,'Anti alias FIR and rate change/1','Remove known FIR delay/1');
wire(sub,'In/1','Select source times without filtering/1');
wire(sub,'Remove known FIR delay/1','Choose filtered or direct/1');
wire(sub,'Filter choice/1','Choose filtered or direct/2');
wire(sub,'Select source times without filtering/1','Choose filtered or direct/3');
wire(sub,'Choose filtered or direct/1','Out/1');

sub = [model '/Uniform Quantization'];
add_block('built-in/Subsystem',sub,'Position',[420 85 590 165]);
inport(sub,'In',1,[20 90 50 110]);
add_block('simulink/Math Operations/Gain',[sub '/Divide by step'],'Gain','1/quantStep','Position',[100 30 170 70]);
add_block('simulink/Math Operations/Rounding Function',[sub '/Round to integer'], ...
    'Operator','round','Position',[210 30 280 70]);
add_block('simulink/Discontinuities/Saturation',[sub '/Limit signed level index'], ...
    'LowerLimit','quantMin','UpperLimit','quantMax','Position',[320 30 430 70]);
add_block('simulink/Math Operations/Gain',[sub '/Multiply by step'], ...
    'Gain','quantStep','Position',[470 30 540 70]);
constant([sub '/16 bit control bypass'],'bypassQuantizer',[380 115 450 145]);
add_block('simulink/Signal Routing/Switch',[sub '/Keep control or quantize'], ...
    'Criteria','u2 ~= 0','Position',[600 60 640 160]);
outport(sub,'Out',1,[700 95 730 115]);
wire(sub,'In/1','Divide by step/1'); wire(sub,'Divide by step/1','Round to integer/1');
wire(sub,'Round to integer/1','Limit signed level index/1');
wire(sub,'Limit signed level index/1','Multiply by step/1');
wire(sub,'In/1','Keep control or quantize/1');
wire(sub,'16 bit control bypass/1','Keep control or quantize/2');
wire(sub,'Multiply by step/1','Keep control or quantize/3');
wire(sub,'Keep control or quantize/1','Out/1');

sub = [model '/Reconstruct at source rate'];
add_block('built-in/Subsystem',sub,'Position',[660 85 850 165]);
inport(sub,'In',1,[20 90 50 110]);
constant([sub '/Zero tail'],'reconstructionTail',[90 145 160 175]);
add_block('simulink/Math Operations/Matrix Concatenate',[sub '/Pad frame'], ...
    'NumInputs','2','ConcatenateDimension','1','Position',[210 50 245 120]);
rateBlock(sub,'Reconstruction FIR','q','p','reconstructionCoefficients',[290 30 445 85]);
selector(sub,'Remove phase delay and keep source interval','referenceIndices',[490 30 670 85]);
outport(sub,'Out',1,[740 45 770 65]);
wire(sub,'In/1','Pad frame/1'); wire(sub,'Zero tail/1','Pad frame/2');
wire(sub,'Pad frame/1','Reconstruction FIR/1');
wire(sub,'Reconstruction FIR/1','Remove phase delay and keep source interval/1');
wire(sub,'Remove phase delay and keep source interval/1','Out/1');

% Metrics are calculated with Simulink arithmetic on aligned source-grid arrays.
constant([model '/Original reference'],'referenceAudio',[660 270 785 310]);
add_block('simulink/Math Operations/Sum',[model '/Error'],'Inputs','+-','Position',[920 200 950 245]);
add_block('simulink/Math Operations/Dot Product',[model '/Reference energy'],'Position',[840 350 925 390]);
add_block('simulink/Math Operations/Dot Product',[model '/Error energy'],'Position',[1010 200 1090 240]);
add_block('simulink/Math Operations/Divide',[model '/NMSE'],'Position',[1160 270 1205 310]);
add_block('simulink/Math Operations/Divide',[model '/Energy ratio'],'Position',[1010 350 1060 395]);
add_block('simulink/Math Operations/Math Function',[model '/Log10'],'Operator','log10','Position',[1110 355 1165 390]);
add_block('simulink/Math Operations/Gain',[model '/SNR dB'],'Gain','10','Position',[1210 355 1270 390]);
add_block('simulink/Sinks/Display',[model '/NMSE display'],'Position',[1270 265 1415 310]);
add_block('simulink/Sinks/Display',[model '/SNR display'],'Position',[1310 350 1455 395]);
sink(model,'Processed samples','processed_samples',[420 220 555 250]);
sink(model,'Sampled before quantization','sampled_samples',[200 220 350 250]);
sink(model,'Aligned samples','aligned_samples',[700 210 835 240]);
sink(model,'NMSE logged','nmse_model',[1260 200 1380 230]);
sink(model,'SNR logged','snr_model',[1310 440 1430 470]);
wire(model,'Audio frame/1','Sampling/1'); wire(model,'Sampling/1','Uniform Quantization/1');
wire(model,'Sampling/1','Sampled before quantization/1');
wire(model,'Uniform Quantization/1','Reconstruct at source rate/1');
wire(model,'Uniform Quantization/1','Processed samples/1');
wire(model,'Reconstruct at source rate/1','Aligned samples/1');
wire(model,'Original reference/1','Error/1'); wire(model,'Reconstruct at source rate/1','Error/2');
wire(model,'Error/1','Error energy/1'); wire(model,'Error/1','Error energy/2');
wire(model,'Original reference/1','Reference energy/1'); wire(model,'Original reference/1','Reference energy/2');
wire(model,'Error energy/1','NMSE/1'); wire(model,'Reference energy/1','NMSE/2');
wire(model,'Reference energy/1','Energy ratio/1'); wire(model,'Error energy/1','Energy ratio/2');
wire(model,'Energy ratio/1','Log10/1'); wire(model,'Log10/1','SNR dB/1');
wire(model,'NMSE/1','NMSE display/1'); wire(model,'NMSE/1','NMSE logged/1');
wire(model,'SNR dB/1','SNR display/1'); wire(model,'SNR dB/1','SNR logged/1');
note = Simulink.Annotation(model, ...
    ['Read SETTINGS.m, then run RUN_SIMULINK.m. One frame = the complete audio recording.' newline ...
     'Stop time 0 processes that frame once; WAV duration is sample count / actual audio rate.' newline ...
     'Displays: processing-array metrics. RUN_SIMULINK also exports, re-imports and scores the WAV.']);
note.Position = [25 15]; note.FontSize = 11;
set_param(model,'Location',[30 60 1530 700]);
save_system(model,fullfile(folder,[model '.slx']));
close_system(model,0);
fprintf('Built %s\n',fullfile(folder,[model '.slx']));
end

function constant(path,value,position)
add_block('simulink/Sources/Constant',path,'Value',value, ...
    'VectorParams1D','off','SampleTime','1','Position',position);
end
function inport(sub,name,number,position)
add_block('built-in/Inport',[sub '/' name],'Port',num2str(number),'Position',position);
end
function outport(sub,name,number,position)
add_block('built-in/Outport',[sub '/' name],'Port',num2str(number),'Position',position);
end
function selector(sub,name,indices,position)
add_block('simulink/Signal Routing/Selector',[sub '/' name],'NumberOfDimensions','2', ...
    'IndexOptionArray',{'Index vector (dialog)','Select all'}, ...
    'IndexParamArray',{indices,'1'},'Position',position);
end
function rateBlock(sub,name,up,down,coefficients,position)
add_block('dspmlti4/FIR Rate Conversion',[sub '/' name], ...
    'FilterSource','Dialog parameters','L',up,'M',down,'h',coefficients, ...
    'rateMode','Enforce single-rate processing','Position',position);
end
function sink(model,name,variable,position)
add_block('simulink/Sinks/To Workspace',[model '/' name],'VariableName',variable, ...
    'SaveFormat','Array','MaxDataPoints','inf','Position',position);
end
function wire(system,source,destination)
add_line(system,source,destination,'autorouting','on');
end
