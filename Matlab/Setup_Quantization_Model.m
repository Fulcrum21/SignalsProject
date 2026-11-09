function Setup_Quantization_Model(samples,bits)
% Supply model-workspace parameters without storing audio inside the SLX file.
% No arguments: keep explicitly supplied data, or load PROJECT_SETTINGS once.
model = 'Quantization_Khaled';
workspace = get_param(model,'ModelWorkspace');
if nargin==0
    if hasVariable(workspace,'inputSamples'), return; end
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(root);
    settings = PROJECT_SETTINGS();
    inputs = Load_Sampling_Inputs();
    mode = settings.filterMode;
    if settings.Fs==44100, mode='native'; end
    selected = [inputs.Fs]==settings.Fs & strcmp({inputs.filterMode},mode) & ...
        strcmp({inputs.platform},settings.platform);
    assert(nnz(selected)==1,'Choose one valid rate/filter/platform in PROJECT_SETTINGS.');
    samples=inputs(selected).samples; bits=settings.bits;
end
[~,~,q] = Uniform_Quantize(samples,bits);
assignin(workspace,'inputSamples',samples);
assignin(workspace,'quantStep',q.step);
assignin(workspace,'minimumIndex',q.minimumIndex);
assignin(workspace,'maximumIndex',q.maximumIndex);
assignin(workspace,'bypassQuantizer',bits==16);
end
