%% Init toolbox
start;
experimentalConditions;
%openNetworkIO;

%% Input variables
pStr = inputdlg("Pigeon number");
pigeonNumber = str2num(pStr{1});
pigeonRole = find(exp.pigeon.numberMapping==pigeonNumber);
if isempty(pigeonRole)
    error("Unknown pigeon number");
end

sStr = inputdlg("Session number");
sessionNumber = str2num(sStr{1});

experimentPhase = questdlg("Experiment phase", "Phase", "Pretraining", "Training", "Test", "Pretraining");

subjectPrefix = char(join([pStr sStr experimentPhase], "-"));


initWindow(2);
d = msgbox('Place window ^__^');
waitfor(d);


%% Start session
pigeonStimuli = cat(2, exp.pigeon.stimuli(pigeonRole,:), [exp.stimulus.white, exp.stimulus.grey]);

switch experimentPhase
    case 'Pretraining'
        % Trial 1-5 means left key, as per GoogleDoc stimulus diagram
        % Trial 6-10 means right key, with same order

        trials = randomOrder(5 * 2, exp.pretraining.trialsPerStimulusPerKey * 5 * 2);

        i = 1;
        for trial = trials
            fprintf("No. of Trial: %i \n", i);
            fprintf("Trial type: %i \n", trial);
            result(i).trial = trial;

            itiTime = randi(exp.pretaining.iti);
            fprintf("ITI: %is \n", itiTime);
            
            showStimuli;
            pause(itiTime);

            original_stimulus = 1 + mod(trial - 1, 5); % map back to original domain

            % show stimulus on left or right key
            if trial < 6
                % left
                keySide = 1;
            else
                % right
                keySide = 2;
            end

            fprintf("Stimulus: %i, Key: %i \n", original_stimulus, keySide);

            showStimuli(pigeonStimuli(original_stimulus), keySide);
            keyOut = keyBuffer(exp.pretraining.stimulusDuration);
            
            if keyOut.raw(1) == 0
                result(i).respPerTrial = 0;
            else
                result(i).respPerTrial = size(keyOut.raw, 1)+size(keyOut.raw, 2);
            end

            if original_stimulus <= 3
                toss_a_coin_to_the_witcher = randi([1 100], 1);

            elseif original_stimulus == 4
                toss_a_coin_to_the_witcher = 0;
            elseif original_stimulus == 5
                toss_a_coin_to_the_witcher = 100;
            end

            if toss_a_coin_to_the_witcher <= exp.pretaining.foodChance123
                feeding(exp.feedingTime);
                result(i).rewarded = 1;
            else
                result(i).rewarded = 0;
            end

            i = i + 1;

        end

        save2File(result, "subject", subjectPrefix);
        
    case 'Training'
        closeWindow;
        error("Phase not yet implemented.");
    case 'Test'
        closeWindow;
        error("Phase not yet implemented.");
end


%% Shutdown toolbox
closeWindow;
%closeNetworkIO;