classdef TestJesherPipeline < matlab.unittest.TestCase
    % Integration checks use real tracked inputs or isolated temporary files.
    % No teammate source/results are modified and no audio is played.
    methods (Test)
        function expectedMatrixHasTypedUniqueRows(testCase)
            expected = jesher.expectedCases();
            testCase.verifyEqual(height(expected), 72);
            testCase.verifyEqual(numel(unique(expected.caseId)), 72);
            testCase.verifyTrue(isstring(expected.caseId));
            testCase.verifyTrue(isstring(expected.platform));
            testCase.verifyTrue(isnumeric(expected.Fs));
            testCase.verifyTrue(isnumeric(expected.effectiveBits));
            testCase.verifyEqual(sum(expected.platform == "matlab"), 36);
            testCase.verifyEqual(sum(expected.platform == "simulink"), 36);
            testCase.verifyEqual(sum(expected.Fs == 44100), 8);
            testCase.verifyTrue(all(expected.filterMode(expected.Fs == 44100) == "native"));
        end

        function trackedHandoffHasNineAvailableControls(testCase)
            [cases, reference, Fs] = jesher.loadAvailableCases(testCase.repoRoot(), {});
            coverage = jesher.validateCases(cases, reference);
            testCase.verifyEqual(Fs, 44100);
            testCase.verifyEqual(numel(cases), 9);
            testCase.verifyEqual(sum(coverage.status == "available"), 9);
            testCase.verifyEqual(sum(coverage.status == "missing_handoff"), 63);
            testCase.verifyEqual(sum(string({cases.platform}) == "simulink"), 0);
            testCase.verifyFalse(any([cases.quantizationApplied]));
        end

        function baselineOnlyFixtureIsSupported(testCase)
            fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            mkdir(fullfile(fixture.Folder, 'Audios'));
            x = [0; 0.25; -0.25; 0.5];
            audiowrite(fullfile(fixture.Folder, 'Audios', 'SpeechMusic.wav'), ...
                x, 44100, 'BitsPerSample', 16);
            [cases, reference, Fs] = jesher.loadAvailableCases(fixture.Folder, {});
            testCase.verifyEqual(numel(cases), 1);
            testCase.verifyEqual(reference, x);
            testCase.verifyEqual(Fs, 44100);
            coverage = jesher.validateCases(cases, reference);
            testCase.verifyEqual(sum(coverage.status == "available"), 1);
        end

        function nestedHandoffPreservesArraysAndMetadata(testCase)
            root = testCase.repoRoot();
            path = fullfile(root,'Results','Abdulrahman','Sampling','sampling_all_rates.mat');
            saved = load(path);
            [cases,reference] = jesher.loadAvailableCases(root,{path});
            testCase.verifyEqual(numel(cases),9);
            for j = 1:8
                entry = saved.samplingHandoff.cases(j);
                c = cases(strcmp({cases.caseId},entry.caseId));
                testCase.verifyEqual(c.samples,entry.samples);
                testCase.verifyEqual(c.Fs,entry.Fs);
                testCase.verifyEqual(c.firstSampleTimeSeconds,entry.firstSampleTimeSeconds);
                testCase.verifyEqual(c.method,entry.method);
                testCase.verifyEqual(c.samplingMetadata,rmfield(entry,'samples'));
                testCase.verifyEqual(c.platform,'matlab');
                testCase.verifyEqual(c.effectiveBits,16);
                testCase.verifyEqual(c.processingStage,'sampling_only_control');
                testCase.verifyFalse(c.quantizationApplied || c.normalizationApplied);
                testCase.verifyTrue(c.delayCompensated);
                testCase.verifyEqual(c.alignmentPolicy,'full_record_resample_v1');
                testCase.verifyTrue(contains(c.provenance,path));
                aligned = jesher.alignToReference(reference,44100,c);
                expected = resample(entry.samples,entry.q,entry.p);
                testCase.verifyEqual(aligned,expected(1:numel(reference)));
            end
        end

        function explicitCasesOverrideFallbackWithoutRegeneration(testCase)
            fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            root = testCase.repoRoot();
            available = jesher.loadAvailableCases(root,{});
            cases = available(strcmp({available.caseId},'speechmusic_fs8000_b16_none_matlab'));
            cases.samples(10) = cases.samples(10)+1e-6;
            cases.provenance = 'Explicit producer array; intentional sentinel for precedence test.';
            cases = rmfield(cases,{'method','samplingMetadata'}); % Older public contract still works.
            path = fullfile(fixture.Folder,'explicit.mat');
            save(path,'cases');
            loaded = jesher.loadAvailableCases(root,{path});
            testCase.verifyEqual(numel(loaded),9);
            testCase.verifyEqual(numel(unique(string({loaded.caseId}))),9);
            actual = loaded(strcmp({loaded.caseId},cases.caseId));
            testCase.verifyEqual(actual.samples,cases.samples);
            testCase.verifyEqual(actual.provenance,cases.provenance);
        end

        function nestedWrongSourceAndDuplicateIdsAreRejected(testCase)
            fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            root = testCase.repoRoot();
            path = fullfile(root,'Results','Abdulrahman','Sampling','sampling_all_rates.mat');
            saved = load(path);
            samplingHandoff = saved.samplingHandoff;
            samplingHandoff.original.samples(1) = samplingHandoff.original.samples(1)+1e-6;
            badPath = fullfile(fixture.Folder,'bad.mat');
            save(badPath,'samplingHandoff');
            testCase.verifyError(@()jesher.loadAvailableCases(root,{badPath}),'jesher:SourceMismatch');
            samplingHandoff = saved.samplingHandoff;
            samplingHandoff.cases(2) = samplingHandoff.cases(1);
            save(badPath,'samplingHandoff');
            testCase.verifyError(@()jesher.loadAvailableCases(root,{badPath}),'jesher:DuplicateCase');
        end

        function duplicatesAndFalsePrecisionAreRejected(testCase)
            [cases, reference] = jesher.loadAvailableCases(testCase.repoRoot(), {});
            duplicates = [cases(1); cases(1)];
            testCase.verifyError(@() jesher.validateCases(duplicates, reference), 'jesher:DuplicateCase');
            c = cases(1);
            c.caseId = 'speechmusic_fs44100_b02_native_matlab';
            c.effectiveBits = 2;
            testCase.verifyError(@() jesher.validateCases(c, reference), 'jesher:QuantizerMissing');
            c.quantizationApplied = true;
            testCase.verifyError(@() jesher.validateCases(c, reference), 'jesher:QuantizerLevels');
        end

        function duplicateExternalHandoffsNeverOverwrite(testCase)
            fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [cases, ~] = jesher.loadAvailableCases(testCase.repoRoot(), {});
            cases = cases(1); %#ok<NASGU>
            path = fullfile(fixture.Folder, 'handoff.mat');
            save(path, 'cases');
            testCase.verifyError(@() jesher.loadAvailableCases(testCase.repoRoot(), ...
                {path, path}), 'jesher:DuplicateCase');
        end

        function crossPlatformPairsUseExtendedNumbers(testCase)
            [cases, ~] = jesher.loadAvailableCases(testCase.repoRoot(), {});
            ca = cases(1);
            cb = ca;
            cb.caseId = 'speechmusic_fs44100_b16_native_simulink';
            cb.platform = 'simulink';
            pairedCases = [ca; cb];
            ids = string({pairedCases.caseId})';
            results = table(ids, [0; 0], [Inf; Inf], [0; 0], [1; 1], [2; 2], ...
                'VariableNames', {'caseId', 'nmse', 'snrDb', ...
                'comparisonFirstTimeSeconds', 'comparisonLastTimeSeconds', ...
                'comparisonSampleCount'});
            comparison = jesher.comparePlatforms(pairedCases, results);
            testCase.verifyEqual(height(comparison), 36);
            testCase.verifyEqual(sum(comparison.status == "within_proposed_tolerance"), 1);
            testCase.verifyEqual(sum(comparison.status == "missing_platform"), 35);
            match = comparison(comparison.status == "within_proposed_tolerance", :);
            testCase.verifyEqual(match.maxAbsSampleDifference, 0);
            testCase.verifyEqual(match.snrDbDifference, 0);
            pairedCases(2).processingStage = 'different_stage';
            comparison = jesher.comparePlatforms(pairedCases, results);
            testCase.verifyEqual(sum(comparison.status == "incomparable_metadata"), 1);
        end

        function completeMatrixGateWritesNoOutput(testCase)
            fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [cases, ~] = jesher.loadAvailableCases(testCase.repoRoot(), {});
            cases = cases(1); %#ok<NASGU>
            path = fullfile(fixture.Folder, 'handoff.mat');
            save(path, 'cases');
            output = fullfile(fixture.Folder, 'must_not_exist');
            testCase.verifyError(@() Run_Jesher_Evaluation('HandoffFiles', {path}, ...
                'OutputFolder', output, 'RequireComplete', true, 'MakePlots', false), ...
                'jesher:IncompleteMatrix');
            testCase.verifyFalse(isfolder(output));
        end

        function noPlotRunCreatesHonestPartialPackage(testCase)
            testCase.assumeTrue(exist('resample', 'file') == 2, 'Signal Processing Toolbox required.');
            fixture = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [cases, ~] = jesher.loadAvailableCases(testCase.repoRoot(), {});
            cases = cases(1); %#ok<NASGU>
            path = fullfile(fixture.Folder, 'handoff.mat');
            save(path, 'cases');
            output = fullfile(fixture.Folder, 'evaluation');
            summary = Run_Jesher_Evaluation('HandoffFiles', {path}, ...
                'OutputFolder', output, 'MakePlots', false);
            testCase.verifyEqual(summary.availableCases, 9);
            testCase.verifyFalse(summary.matrixComplete);
            testCase.verifyFalse(summary.speakerPlaybackVerified);
            testCase.verifyFalse(summary.listeningCollected);
            testCase.verifyTrue(summary.archiveBytesVerified);
            testCase.verifyEqual(summary.archiveFile, 'audio_partial_NOT_FINAL.zip');
            metrics = readtable(fullfile(output, 'metrics.csv'), 'TextType', 'string');
            testCase.verifyEqual(height(metrics), 9);
            testCase.verifyTrue(isnumeric(metrics.Fs));
            testCase.verifyTrue(isnumeric(metrics.nmse));
            native = metrics(metrics.caseId == "speechmusic_fs44100_b16_native_matlab", :);
            testCase.verifyEqual(native.nmse, 0);
            testCase.verifyEqual(native.snrDb, Inf);
            testCase.verifyTrue(isfile(fullfile(output, summary.archiveFile)));
            testCase.verifyFalse(isfolder(fullfile(output, 'figures')));
            % Reusing a result folder must fail before stale files can mix.
            testCase.verifyError(@() Run_Jesher_Evaluation('HandoffFiles', {path}, ...
                'OutputFolder', output, 'MakePlots', false), 'jesher:OutputExists');
        end
    end

    methods (Static, Access = private)
        function root = repoRoot()
            root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
        end
    end
end
