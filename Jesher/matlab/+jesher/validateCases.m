function coverage = validateCases(cases, reference)
%VALIDATECASES Reject misleading identities and incomplete processing metadata.
expected = jesher.expectedCases();
ids = string({cases.caseId});
assert(numel(unique(ids)) == numel(ids), 'jesher:DuplicateCase', 'Duplicate case IDs.');
assert(all(ismember(ids, expected.caseId)), 'jesher:UnknownCase', 'Unknown case ID.');
for j = 1:numel(cases)
    c = cases(j);
    e = expected(expected.caseId == string(c.caseId),:);
    assert(isscalar(c.Fs) && c.Fs == e.Fs && ...
        isscalar(c.effectiveBits) && c.effectiveBits == e.effectiveBits && ...
        string(c.platform) == e.platform && string(c.filterMode) == e.filterMode && ...
        string(c.sourceFile) == e.sourceFile, 'jesher:IdentityMismatch', ...
        'Case ID and rate/precision/filter/platform/source metadata disagree: %s', c.caseId);
    assert(isa(c.samples,'double') && iscolumn(c.samples) && ~isempty(c.samples) && ...
        isreal(c.samples) && all(isfinite(c.samples)), 'jesher:Samples', ...
        'Samples must be a finite real mono double column: %s', c.caseId);
    for field = {'quantizationApplied','normalizationApplied','delayCompensated'}
        assert(islogical(c.(field{1})) && isscalar(c.(field{1})), ...
            'jesher:Metadata', 'Timing/processing flags must be scalar logicals.');
    end
    for field = {'processingStage','quantizerDescription','samplingDescription','provenance','alignmentPolicy'}
        value = c.(field{1});
        assert(((ischar(value) && isrow(value)) || (isstring(value) && isscalar(value))) && ...
            ~ismissing(string(value)) && strlength(string(value)) > 0, ...
            'jesher:Metadata', 'Nonempty scalar processing descriptions are required.');
    end
    if c.effectiveBits < 16
        assert(c.quantizationApplied, 'jesher:QuantizerMissing', ...
            'Reduced-bit cases need the actual quantizer output and settings.');
        assert(numel(unique(c.samples)) <= 2^c.effectiveBits, 'jesher:QuantizerLevels', ...
            'Too many distinct output levels for the claimed effective bits.');
    end
    if c.Fs == 44100 && c.effectiveBits == 16
        assert(isequal(c.samples, reference), 'jesher:NativeReference', ...
            'The native 16-bit control must retain the unchanged original.');
    end
end
coverage = expected;
coverage.status = repmat("missing_handoff",height(expected),1);
coverage.status(ismember(expected.caseId, ids)) = "available";
end
