function [nmse,snrDb] = quality_metrics(reference,processed)
% Inputs must already represent the same physical times.
assert(isequal(size(reference),size(processed)),'Align samples before subtraction.');
assert(all(isfinite(reference)) && all(isfinite(processed)),'Nonfinite samples.');
referenceEnergy = sum(reference.^2);
errorEnergy = sum((reference-processed).^2);
if referenceEnergy==0
    if errorEnergy==0, nmse=NaN; snrDb=NaN;
    else, nmse=Inf; snrDb=-Inf; end
elseif errorEnergy==0
    nmse=0; snrDb=Inf;
else
    nmse=errorEnergy/referenceEnergy;
    snrDb=10*log10(referenceEnergy/errorEnergy);
end
end
