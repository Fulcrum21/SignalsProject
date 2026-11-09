function [quantized,errorSignal]=Run_Khaled_Quantizer(samples,Fs,bits)
% Live adapter for Khaled's actual model, using the same inputs as his KH04 script.
% No quantization arithmetic is implemented here. Simulink returns the samples.
root=fileparts(fileparts(mfilename('fullpath')));
model='Khaled_Quantizer_Model';
load_system(fullfile(root,'Simulink',[model '.slx']));
time=(0:numel(samples)-1)'/Fs;
simIn=timeseries(samples,time);
simulation=Simulink.SimulationInput(model);
simulation=simulation.setVariable('simIn',simIn);
simulation=simulation.setVariable('Fs',Fs);
simulation=simulation.setVariable('Bsim',bits);
simulation=simulation.setModelParameter('StartTime','0', ...
    'StopTime',sprintf('%.17g',time(end)),'SolverType','Fixed-step', ...
    'Solver','FixedStepDiscrete','FixedStep',sprintf('%.17g',1/Fs));
out=sim(simulation); logged=out.get('sim_q4');
quantized=double(logged.Data(:));
assert(isequal(size(quantized),size(samples)) && ...
    max(abs(double(logged.Time(:))-time))<1e-8,'Model output count or time grid changed.');
errorSignal=samples-quantized;
% Leave the selected input ready for the model's direct Run button.
assignin('base','simIn',simIn); assignin('base','Fs',Fs); assignin('base','Bsim',bits);
set_param(model,'StopTime',sprintf('%.17g',time(end)), ...
    'SolverType','Fixed-step','Solver','FixedStepDiscrete','FixedStep',sprintf('%.17g',1/Fs));
end
