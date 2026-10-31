%% Play the last chosen case and the original at one fixed gain.
% Run RUN_MATLAB or RUN_SIMULINK first. Record what you actually hear.
if ~exist('result','var') || ~isstruct(result) || ~isfield(result,'WavFile')
    error('Run RUN_MATLAB or RUN_SIMULINK first.');
end
gain = 0.5;                     % Keep the same gain and OS volume for comparisons.
[original,originalFs] = audioread(result.Source);
if size(original,2)>1, original = mean(original,2); end
[exported,actualFs] = audioread(result.WavFile);
fprintf('Original: %d Hz.\n',originalFs);
playblocking(audioplayer(gain*original,originalFs));
fprintf('Processed: %d Hz, %d effective bits, %s.\n',actualFs,result.Bits,result.Filter);
playblocking(audioplayer(gain*exported,actualFs));
fprintf('Record your actual observation. Stream completion alone is not a listening result.\n');
