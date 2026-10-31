function expected = expectedCases()
%EXPECTEDCASES The shared 36-condition matrix for each actual platform.
rows = cell(72, 6);
k = 0;
for platform = ["matlab", "simulink"]
    for rate = [44100, 22050, 11025, 8000, 4000]
        if rate == 44100
            modes = "native";
        else
            modes = ["lpf", "none"];
        end
        for mode = modes
            for bits = [16, 8, 4, 2]
                k = k + 1;
                id = sprintf('speechmusic_fs%d_b%02d_%s_%s', rate, bits, mode, platform);
                rows(k,:) = {string(id), platform, "Audios/SpeechMusic.wav", rate, bits, mode};
            end
        end
    end
end
expected = cell2table(rows, 'VariableNames', ...
    {'caseId','platform','sourceFile','Fs','effectiveBits','filterMode'});
end
