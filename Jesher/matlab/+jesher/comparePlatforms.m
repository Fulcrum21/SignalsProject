function comparison = comparePlatforms(cases, results)
%COMPAREPLATFORMS Pair real outputs; missing platform is never zero difference.
% Proposed engineering tolerances, pending team review. These are not a claim
% that every platform implementation must be bit-identical.
expected = jesher.expectedCases();
conditions = expected(expected.platform == "matlab",:);
rows = repmat(struct('conditionId',"",'status',"missing_platform", ...
    'maxAbsSampleDifference',NaN,'sampleTolerance',NaN,'nmseDifference',NaN, ...
    'snrDbDifference',NaN,'nmseTolerance',1e-10,'snrDbTolerance',1e-6),36,1);
ids = string({cases.caseId});
for j = 1:height(conditions)
    matlabId = conditions.caseId(j);
    conditionId = regexprep(matlabId,'_matlab$','');
    simulinkId = conditionId + "_simulink";
    rows(j).conditionId = conditionId;
    a = find(ids == matlabId);
    b = find(ids == simulinkId);
    if isempty(a) || isempty(b)
        continue
    end
    ca = cases(a); cb = cases(b);
    if ~isequal(size(ca.samples),size(cb.samples)) || ...
            string(ca.alignmentPolicy) ~= string(cb.alignmentPolicy) || ...
            ca.quantizationApplied ~= cb.quantizationApplied || ...
            string(ca.processingStage) ~= string(cb.processingStage)
        rows(j).status = "incomparable_metadata";
        continue
    end
    ra = results(results.caseId == matlabId,:);
    rb = results(results.caseId == simulinkId,:);
    if ra.comparisonFirstTimeSeconds ~= rb.comparisonFirstTimeSeconds || ...
            ra.comparisonLastTimeSeconds ~= rb.comparisonLastTimeSeconds || ...
            ra.comparisonSampleCount ~= rb.comparisonSampleCount
        rows(j).status = "incomparable_interval";
        continue
    end
    rows(j).maxAbsSampleDifference = max(abs(ca.samples-cb.samples));
    rows(j).sampleTolerance = 1e-10+1e-8*max(abs(ca.samples));
    rows(j).nmseDifference = extendedDifference(ra.nmse,rb.nmse);
    rows(j).snrDbDifference = extendedDifference(ra.snrDb,rb.snrDb);
    if rows(j).maxAbsSampleDifference <= rows(j).sampleTolerance && ...
            rows(j).nmseDifference <= rows(j).nmseTolerance && ...
            rows(j).snrDbDifference <= rows(j).snrDbTolerance
        rows(j).status = "within_proposed_tolerance";
    else
        rows(j).status = "review_required";
    end
end
comparison = struct2table(rows);
end

function difference = extendedDifference(a,b)
if isequaln(a,b)
    difference = 0;
elseif isfinite(a) && isfinite(b)
    difference = abs(a-b);
else
    difference = Inf;
end
end
