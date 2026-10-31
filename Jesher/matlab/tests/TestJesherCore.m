classdef TestJesherCore < matlab.unittest.TestCase
    % Run after adding Jesher/matlab to the MATLAB path.
    methods (Test)
        function unchangedReference(testCase)
            x = [-0.5; 0; 0.25; 0.75];
            m = jesher.computeMetrics(x, x);
            testCase.verifyEqual(m.nmse, 0);
            testCase.verifyEqual(m.snrDb, Inf);
            testCase.verifyEqual(m.status, 'unchanged');
        end

        function predictableDegradation(testCase)
            x = [-0.5; 0; 0.25; 0.75];
            m = jesher.computeMetrics(x, x / 2);
            testCase.verifyEqual(m.nmse, 0.25, 'AbsTol', 1e-14);
            testCase.verifyEqual(m.snrDb, 10 * log10(4), 'AbsTol', 1e-12);
            testCase.verifyEqual(m.snrDb, -10 * log10(m.nmse), 'AbsTol', 1e-12);
            m = jesher.computeMetrics(x, zeros(size(x)));
            testCase.verifyEqual(m.nmse, 1);
            testCase.verifyEqual(m.snrDb, 0);
        end

        function zeroReferenceCases(testCase)
            m = jesher.computeMetrics(zeros(4, 1), zeros(4, 1));
            testCase.verifyTrue(isnan(m.nmse) && isnan(m.snrDb));
            testCase.verifyEqual(m.status, 'zero_reference_silence');
            m = jesher.computeMetrics(zeros(4, 1), ones(4, 1));
            testCase.verifyEqual(m.nmse, Inf);
            testCase.verifyEqual(m.snrDb, -Inf);
            testCase.verifyEqual(m.status, 'zero_reference_error');
        end

        function invalidMetricInputs(testCase)
            testCase.verifyError(@() jesher.computeMetrics([1; 2], 1), 'jesher:UnequalLengths');
            invalid = {[1, 2], [1; NaN], [1; Inf], [1; 1i], zeros(2, 2), [], single([1; 2])};
            for k = 1:numel(invalid)
                testCase.verifyError(@() jesher.computeMetrics(invalid{k}, invalid{k}), 'jesher:InvalidSamples');
            end
        end

        function nativeGridIsUnchanged(testCase)
            x = linspace(-0.5, 0.5, 101)';
            c = testCase.makeCase(x, 44100);
            [aligned, a] = jesher.alignToReference(x, 44100, c);
            testCase.verifyEqual(aligned, x);
            testCase.verifyEqual(a.discardedEndpointSamples, 0);
            testCase.verifyEqual(a.lastTimeSeconds, 100 / 44100);
        end

        function oddLengthReconstruction(testCase)
            testCase.assumeTrue(exist('resample', 'file') == 2, 'Signal Processing Toolbox required.');
            x = 0.2 * sin(2 * pi * 300 * (0:100)' / 44100);
            c = testCase.makeCase(x(1:2:end), 22050);
            [aligned, a] = jesher.alignToReference(x, 44100, c);
            expected = resample(c.samples, 2, 1, 10, 5);
            testCase.verifyEqual(aligned, expected(1:101));
            testCase.verifyEqual(a.reconstructedSampleCount, 102);
            testCase.verifyEqual(a.discardedEndpointSamples, 1);
        end

        function mismatchedTimingAndLengthAreRejected(testCase)
            x = zeros(101, 1);
            c = testCase.makeCase(zeros(50, 1), 22050);
            testCase.verifyError(@() jesher.alignToReference(x, 44100, c), 'jesher:UnexpectedCaseLength');
            c = testCase.makeCase(zeros(51, 1), 22050);
            c.firstSampleTimeSeconds = 1 / 22050;
            testCase.verifyError(@() jesher.alignToReference(x, 44100, c), 'jesher:UnsupportedStartTime');
            c.firstSampleTimeSeconds = 0;
            c.delayCompensated = false;
            testCase.verifyError(@() jesher.alignToReference(x, 44100, c), 'jesher:UncompensatedDelay');
            c.delayCompensated = true;
            c.normalizationApplied = true;
            testCase.verifyError(@() jesher.alignToReference(x, 44100, c), 'jesher:NormalizationNotAllowed');
        end

        function rateAndPolicyAreExplicit(testCase)
            x = zeros(101, 1);
            c = testCase.makeCase(zeros(26, 1), 11025);
            testCase.verifyError(@() jesher.alignToReference(x, 44100, c), 'jesher:UnsupportedCaseRate');
            c.Fs = 0;
            testCase.verifyError(@() jesher.alignToReference(x, 44100, c), 'jesher:InvalidRate');
            c.Fs = 22050;
            c.alignmentPolicy = 'unknown';
            testCase.verifyError(@() jesher.alignToReference(x, 44100, c), 'jesher:UnsupportedAlignmentPolicy');
            c = rmfield(c, 'alignmentPolicy');
            testCase.verifyError(@() jesher.alignToReference(x, 44100, c), 'jesher:MissingAlignmentMetadata');
        end

        function rationalGridEndpointRule(testCase)
            testCase.assumeTrue(exist('resample', 'file') == 2, 'Signal Processing Toolbox required.');
            x = zeros(882005, 1);
            for rate = [11025, 8000, 4000]
                count = ceil(numel(x) * rate / 44100);
                c = testCase.makeCase(zeros(count, 1), rate);
                c.alignmentPolicy = 'full_record_resample_v1';
                [aligned, a] = jesher.alignToReference(x, 44100, c);
                testCase.verifySize(aligned, size(x));
                testCase.verifyGreaterThanOrEqual(a.discardedEndpointSamples, 0);
                testCase.verifyLessThan(a.discardedEndpointSamples, ceil(44100 / rate));
            end
        end

        function wavRateContainerAndRoundTrip(testCase)
            fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            folder = fixture.Folder;
            samples = [-1; -0.5; 0; 0.12345; 1 - 1 / 32768];
            path = fullfile(folder, 'actual_rate.wav');
            w = jesher.exportVerifiedWav(samples, 8000, path);
            testCase.verifyEqual(w.containerBits, 16);
            testCase.verifyEqual(w.sampleCount, 5);
            testCase.verifyEqual(w.durationSeconds, 5 / 8000);
            testCase.verifyGreaterThan(w.fileBytes, 2 * numel(samples));
            testCase.verifyLessThanOrEqual(w.maxAbsRoundTripError, 1 / 32768 + 8 * eps(1));
            info = audioinfo(path);
            testCase.verifyEqual(info.SampleRate, 8000);
        end

        function wavClippingAndInvalidRatesAreRejected(testCase)
            testCase.verifyError(@() jesher.exportVerifiedWav([0; 1], 44100, 'unused.wav'), 'jesher:WavRangeExceeded');
            testCase.verifyError(@() jesher.exportVerifiedWav([-1.1; 0], 44100, 'unused.wav'), 'jesher:WavRangeExceeded');
            testCase.verifyError(@() jesher.exportVerifiedWav([0; NaN], 44100, 'unused.wav'), 'jesher:InvalidSamples');
            testCase.verifyError(@() jesher.exportVerifiedWav([0; 0], 8000.5, 'unused.wav'), 'jesher:InvalidRate');
        end
    end

    methods (Static, Access = private)
        function c = makeCase(samples, Fs)
            c = struct('samples', samples, 'Fs', Fs, ...
                'firstSampleTimeSeconds', 0, 'delayCompensated', true, ...
                'normalizationApplied', false, 'alignmentPolicy', 'aa03_full_record_v1');
        end
    end
end
