%% Init toolbox
start;
%openNetworkIO;
%bIO(1,1);
%bIO(5,1);
experimentalConditions;
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
            keyOut = keyBuffer(exp.pretraining.stimulusDuration, 'goodKey', [keySide], inf);
            showStimuli;
            
            result(i).respPerTrial = keyOut.goodKey;

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

        % Trial 1-3 means left key, as per GoogleDoc stimulus diagram
        % Trial 4-6 means right key, with same order

        % Stimulus 4 & 5 are disambiguation stimuli

        noOfCondition = 3;

        trials = randomOrder(noOfCondition * 2, exp.training.trialsPerCondition * noOfCondition * 2);

        i = 1;
        for trial = trials
            fprintf("No. of Trial: %i \n", i);
            fprintf("Trial type: %i \n", trial);
            result(i).trial = trial;

            itiTime = randi(exp.training.iti);
            fprintf("ITI: %is \n", itiTime);
            showStimuli;
            pause(itiTime);

            original_stimulus = 1 + mod(trial - 1, noOfCondition); % map back to original domain

            % show stimulus on left or right key
            if trial < 4
                % left
                keySide = 1;
            else
                % right
                keySide = 2;
            end

            fprintf("Condition: %i, Key: %i \n", original_stimulus, keySide);

            switch original_stimulus
                case 1
                    % decrease food delay by pecks
                    showStimuli(pigeonStimuli(original_stimulus), keySide);
                    tic
                    loopEndTime = exp.training.stimulusDuration + toc;
                    pecks = 0;

                    while(loopEndTime >= toc)
                        keyOut = keyBuffer(exp.training.stimulusDecrement, 'goodKey', [keySide], inf);

                        if keyOut.goodKey > 0
                            pecks = pecks + keyOut.goodKey;
                            loopEndTime = loopEndTime - (keyOut.goodKey * exp.training.stimulusDecrement);
                        end
                    end

                    result(i).respPerTrial = pecks;
                    result(i).delay = exp.training.stimulusDuration - (pecks * exp.training.stimulusDecrement);

                    foodChanceThrow = randi([1 100], 1);
                    if foodChanceThrow <= exp.training.foodChance
                        feeding(exp.feedingTime);
                        result(i).rewarded = 1;
                    else
                        result(i).rewarded = 0;
                    end

                case 2
                    % increase food probability
                    showStimuli(pigeonStimuli(original_stimulus), keySide);
                    keyOut = keyBuffer(exp.training.stimulusDuration, 'goodKey', [keySide], inf);

                    foodChanceBonus = keyOut.goodKey * 1.5;
                    foodChanceThrow = randi([1 100], 1);
                    finalFoodChance = exp.training.foodChance + foodChanceBonus;

                    if foodChanceThrow <= finalFoodChance
                        feeding(exp.feedingTime);
                        result(i).rewarded = 1;
                    else
                        result(i).rewarded = 0;
                    end

                    result(i).respPerTrial = keyOut.goodKey;
                    result(i).foodProbability = finalFoodChance;

                case 3
                    % decrease food disambiguation delay
                    showStimuli(pigeonStimuli(original_stimulus), keySide);

                    tic
                    loopEndTime = exp.training.stimulusDuration + toc;
                    pecks = 0;

                    while(loopEndTime >= toc)
                        keyOut = keyBuffer(exp.training.stimulusDecrement, 'goodKey', [keySide], inf);

                        if keyOut.goodKey > 0
                            pecks = pecks + keyOut.goodKey;
                            loopEndTime = loopEndTime - (keyOut.goodKey * exp.training.stimulusDecrement);
                        end
                    end

                    result(i).respPerTrial = pecks;
                    result(i).delay = exp.training.stimulusDuration - (pecks * exp.training.stimulusDecrement);
                    
                    secondStimulusDuration = pecks * exp.training.stimulusDecrement;
                    result(i).secondStimulus = secondStimulusDuration;

                    foodChanceThrow = randi([1 100], 1);
                    if foodChanceThrow <= exp.training.foodChance
                        showStimuli(pigeonStimuli(4), keySide);
                        pause(secondStimulusDuration);
                        feeding(exp.feedingTime);
                        result(i).rewarded = 1;
                    else
                        showStimuli(pigeonStimuli(5), keySide);
                        pause(secondStimulusDuration);
                        result(i).rewarded = 0;
                    end

            end

            % clear screen
            showStimuli;
            i = i + 1;
        end

        save2File(result, "subject", subjectPrefix);

    case 'Test'
        closeWindow;
        error("Phase not yet implemented.");
end


%% Shutdown toolbox
closeWindow;
%closeNetworkIO;