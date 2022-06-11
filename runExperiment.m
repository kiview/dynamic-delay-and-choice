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
                        keyOut = keyBuffer(secondStimulusDuration, 'goodKey', [keySide], inf);
                        feeding(exp.feedingTime);
                        result(i).rewarded = 1;
                    else
                        showStimuli(pigeonStimuli(5), keySide);
                        keyOut = keyBuffer(secondStimulusDuration, 'goodKey', [keySide], inf);
                        result(i).rewarded = 0;
                    end
                    result(i).respPerTrialSecondStimulus = keyOut.goodKey;

            end

            % clear screen
            showStimuli;
            i = i + 1;
        end

        save2File(result, "subject", subjectPrefix);

    case 'Test'

        % Trial 1-3 means left key, as per GoogleDoc stimulus diagram
        % Trial 4-6 means right key, with same order
        % Trial 7   means i1 + i2
        % Trial 8   means i1 + ni
        % Trial 9   means i2 + ni
        % Trial 10  means i2 + i1
        % Trial 11  means ni + i1
        % Trial 12  means ni + i2

        noOfCondition = 3;
        trials = randomOrder(noOfCondition * 2, exp.test.trialsPerCondition * noOfCondition * 2);

        noOfChoiceConditions = 3;
        % We want 24 values betwen [1,3] and add an offest of 6
        forceTrials = randomOrder(noOfChoiceConditions * 2, exp.test.choiceTrialsPerCondition * noOfChoiceConditions * 2) + 6;

        % Randomly mix trials with 24 choice trials
        % Beware! mixarrays does not provide same distribution guarantees
        % as randomOrder.
        combinedTrials = mixarrays(trials, forceTrials);

        i = 1;
        for trial = combinedTrials
            fprintf("No. of Trial: %i \n", i);
            fprintf("Trial type: %i \n", trial);
            result(i).trial = trial;

            itiTime = randi(exp.training.iti);
            fprintf("ITI: %is \n", itiTime);
            showStimuli;
            pause(itiTime);

            if trial < 7
                %% Force Trial
                fprintf("Force trial\n");
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
                        loopEndTime = exp.test.stimulusDuration + toc;
                        pecks = 0;

                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', [keySide], inf);

                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end

                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.training.stimulusDuration - (pecks * exp.test.stimulusDecrement);

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
                        keyOut = keyBuffer(exp.test.stimulusDuration, 'goodKey', [keySide], inf);

                        foodChanceBonus = keyOut.goodKey * 1.5;
                        foodChanceThrow = randi([1 100], 1);
                        finalFoodChance = exp.test.foodChance + foodChanceBonus;

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
                        loopEndTime = exp.test.stimulusDuration + toc;
                        pecks = 0;

                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', [keySide], inf);

                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end

                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.test.stimulusDuration - (pecks * exp.test.stimulusDecrement);
                        
                        secondStimulusDuration = pecks * exp.test.stimulusDecrement;
                        result(i).secondStimulus = secondStimulusDuration;

                        foodChanceThrow = randi([1 100], 1);
                        if foodChanceThrow <= exp.test.foodChance
                            showStimuli(pigeonStimuli(4), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', [keySide], inf);
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            showStimuli(pigeonStimuli(5), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', [keySide], inf);
                            result(i).rewarded = 0;
                        end
                        result(i).respPerTrialSecondStimulus = keyOut.goodKey;

                end
            else
                %% Choice Trial
                fprintf("Choice trial: %i\n", trial);

                % Trial 8   means i1 + ni
                % Trial 9   means i2 + ni
                % Trial 10  means i2 + i1
                % Trial 11  means ni + i1
                % Trial 12  means ni + i2
                
                % goodKey means left, badKey means right

                switch trial
                case 7
                    % i1 + i2
                    showStimuli([pigeonStimuli(1) pigeonStimuli(2)], [1 2]);

                    % choice
                    tic
                    keyOut = keyBuffer(exp.test.stimulusDuration, 'goodKey', 1, 1, 'badKey', 2, 1);
                    showStimuli;

                    if keyOut.goodKey > 0
                        % i1
                        keySide = 1;
                        showStimuli(pigeonStimuli(1), keySide);
                        result(i).choice = keySide;

                        loopEndTime = exp.test.stimulusDuration - toc;
                        tic;
                        pecks = 1;
    
                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', keySide, inf);
    
                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end
    
                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.test.stimulusDuration - (pecks * exp.test.stimulusDecrement);
    
                        foodChanceThrow = randi([1 100], 1);
                        if foodChanceThrow <= exp.test.foodChance
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            result(i).rewarded = 0;
                        end
                   
                    elseif keyOut.badKey > 0
                        % i2
                        keySide = 2;
                        showStimuli(pigeonStimuli(2), keySide);
                        result(i).choice = keySide;

                        keyOut = keyBuffer(exp.test.stimulusDuration - toc, 'goodKey', keySide, inf);

                        foodChanceBonus = keyOut.goodKey * 1.5;
                        foodChanceThrow = randi([1 100], 1);
                        finalFoodChance = exp.test.foodChance + foodChanceBonus;

                        if foodChanceThrow <= finalFoodChance
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            result(i).rewarded = 0;
                        end

                        result(i).respPerTrial = keyOut.goodKey;
                        result(i).foodProbability = finalFoodChance;
                    end



                case 8
                    % i1 + ni
                    showStimuli([pigeonStimuli(1) pigeonStimuli(3)], [1 2]);

                    tic;
                    keyOut = keyBuffer(exp.test.stimulusDuration, 'goodKey', 1, 1, 'badKey', 2, 1);
                    showStimuli;

                    if keyOut.goodKey > 0
                        % i1
                        keySide = 1;
                        result(i).choice = keySide;

                    
                        showStimuli(pigeonStimuli(1), keySide);
                        
                        loopEndTime = exp.test.stimulusDuration - toc;
                        tic
                        pecks = 1;

                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', keySide, inf);

                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end

                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.test.stimulusDuration - (pecks * exp.test.stimulusDecrement);

                        foodChanceThrow = randi([1 100], 1);
                        if foodChanceThrow <= exp.test.foodChance
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            result(i).rewarded = 0;
                        end

                   
                    elseif keyOut.badKey > 0
                        keySide = 2;
                        result(i).choice = keySide;

                        % ni
                        showStimuli(pigeonStimuli(3), keySide);
                        loopEndTime = exp.test.stimulusDuration - toc;

                        pecks = 1;

                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', keySide, inf);

                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end

                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.test.stimulusDuration - (pecks * exp.test.stimulusDecrement);
                        
                        secondStimulusDuration = pecks * exp.test.stimulusDecrement;
                        result(i).secondStimulus = secondStimulusDuration;

                        foodChanceThrow = randi([1 100], 1);
                        if foodChanceThrow <= exp.test.foodChance
                            showStimuli(pigeonStimuli(4), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', keySide, inf);
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            showStimuli(pigeonStimuli(5), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', keySide, inf);
                            result(i).rewarded = 0;
                        end
                        result(i).respPerTrialSecondStimulus = keyOut.goodKey;
                        

                    end


                case 9
                    % i2 + ni
                    showStimuli([pigeonStimuli(2) pigeonStimuli(3)], [1 2]);

                    % choice
                    tic
                    keyOut = keyBuffer(exp.test.stimulusDuration, 'goodKey', 1, 1, 'badKey', 2, 1);
                    showStimuli;
                    
                    if keyOut.goodKey > 0
                        keySide = 1;
                        result(i).choice = keySide;

                        % i2
                        showStimuli(pigeonStimuli(2), keySide);

                        keyOut = keyBuffer(exp.test.stimulusDuration - toc, 'goodKey', keySide, inf);

                        foodChanceBonus = keyOut.goodKey * 1.5;
                        foodChanceThrow = randi([1 100], 1);
                        finalFoodChance = exp.test.foodChance + foodChanceBonus;

                        if foodChanceThrow <= finalFoodChance
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            result(i).rewarded = 0;
                        end

                        result(i).respPerTrial = keyOut.goodKey;
                        result(i).foodProbability = finalFoodChance;
                    elseif keyOut.badKey > 0
                        keySide = 2;
                        result(i).choice = keySide;

                        % ni
                        showStimuli(pigeonStimuli(3), keySide);
                        loopEndTime = exp.test.stimulusDuration - toc;

                        pecks = 1;

                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', keySide, inf);

                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end

                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.test.stimulusDuration - (pecks * exp.test.stimulusDecrement);
                        
                        secondStimulusDuration = pecks * exp.test.stimulusDecrement;
                        result(i).secondStimulus = secondStimulusDuration;

                        foodChanceThrow = randi([1 100], 1);
                        if foodChanceThrow <= exp.test.foodChance
                            showStimuli(pigeonStimuli(4), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', keySide, inf);
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            showStimuli(pigeonStimuli(5), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', keySide, inf);
                            result(i).rewarded = 0;
                        end
                        result(i).respPerTrialSecondStimulus = keyOut.goodKey;

                    end

                case 10
                    % i2 + i1
                    showStimuli([pigeonStimuli(2) pigeonStimuli(1)], [1 2]);

                    % choice
                    tic
                    keyOut = keyBuffer(exp.test.stimulusDuration, 'goodKey', 1, 1, 'badKey', 2, 1);
                    showStimuli;

                    if keyOut.goodKey > 0
                        keySide = 1;
                        result(i).choice = keySide;

                        % i2
                        showStimuli(pigeonStimuli(2), keySide);

                        keyOut = keyBuffer(exp.test.stimulusDuration - toc, 'goodKey', keySide, inf);

                        foodChanceBonus = keyOut.goodKey * 1.5;
                        foodChanceThrow = randi([1 100], 1);
                        finalFoodChance = exp.test.foodChance + foodChanceBonus;

                        if foodChanceThrow <= finalFoodChance
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            result(i).rewarded = 0;
                        end

                        result(i).respPerTrial = keyOut.goodKey;
                        result(i).foodProbability = finalFoodChance;

                    elseif keyOut.badKey > 0
                        keySide = 2;
                        result(i).choice = keySide;

                        % i1
                        showStimuli(pigeonStimuli(1), keySide);
                        result(i).choice = keySide;

                        loopEndTime = exp.test.stimulusDuration - toc;
                        tic;
                        pecks = 1;
    
                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', keySide, inf);
    
                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end
    
                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.test.stimulusDuration - (pecks * exp.test.stimulusDecrement);
    
                        foodChanceThrow = randi([1 100], 1);
                        if foodChanceThrow <= exp.test.foodChance
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            result(i).rewarded = 0;
                        end

                    end
                case 11
                    % ni + i1
                    showStimuli([pigeonStimuli(3) pigeonStimuli(1)], [1 2]);

                    % choice
                    tic
                    keyOut = keyBuffer(exp.test.stimulusDuration, 'goodKey', 1, 1, 'badKey', 2, 1);
                    showStimuli;

                    if keyOut.goodKey > 0
                        keySide = 1;
                        result(i).choice = keySide;

                        % ni
                        showStimuli(pigeonStimuli(3), keySide);
                        loopEndTime = exp.test.stimulusDuration - toc;

                        pecks = 1;

                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', keySide, inf);

                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end

                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.test.stimulusDuration - (pecks * exp.test.stimulusDecrement);
                        
                        secondStimulusDuration = pecks * exp.test.stimulusDecrement;
                        result(i).secondStimulus = secondStimulusDuration;

                        foodChanceThrow = randi([1 100], 1);
                        if foodChanceThrow <= exp.test.foodChance
                            showStimuli(pigeonStimuli(4), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', keySide, inf);
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            showStimuli(pigeonStimuli(5), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', keySide, inf);
                            result(i).rewarded = 0;
                        end
                        result(i).respPerTrialSecondStimulus = keyOut.goodKey;

                    elseif keyOut.badKey > 0
                        keySide = 2;
                        result(i).choice = keySide;

                        % i1
                        showStimuli(pigeonStimuli(1), keySide);
                        result(i).choice = keySide;

                        loopEndTime = exp.test.stimulusDuration - toc;
                        tic;
                        pecks = 1;
    
                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', keySide, inf);
    
                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end
    
                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.test.stimulusDuration - (pecks * exp.test.stimulusDecrement);
    
                        foodChanceThrow = randi([1 100], 1);
                        if foodChanceThrow <= exp.test.foodChance
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            result(i).rewarded = 0;
                        end
                        
                    end
                case 12
                    % ni + i2
                    showStimuli([pigeonStimuli(3) pigeonStimuli(2)], [1 2]);
                
                    % choice
                    tic
                    keyOut = keyBuffer(exp.test.stimulusDuration, 'goodKey', 1, 1, 'badKey', 2, 1);
                    showStimuli;

                    if keyOut.goodKey > 0
                        keySide = 1;
                        result(i).choice = keySide;

                        % ni
                        showStimuli(pigeonStimuli(3), keySide);
                        loopEndTime = exp.test.stimulusDuration - toc;

                        pecks = 1;

                        while(loopEndTime >= toc)
                            keyOut = keyBuffer(exp.test.stimulusDecrement, 'goodKey', keySide, inf);

                            if keyOut.goodKey > 0
                                pecks = pecks + keyOut.goodKey;
                                loopEndTime = loopEndTime - (keyOut.goodKey * exp.test.stimulusDecrement);
                            end
                        end

                        result(i).respPerTrial = pecks;
                        result(i).delay = exp.test.stimulusDuration - (pecks * exp.test.stimulusDecrement);
                        
                        secondStimulusDuration = pecks * exp.test.stimulusDecrement;
                        result(i).secondStimulus = secondStimulusDuration;

                        foodChanceThrow = randi([1 100], 1);
                        if foodChanceThrow <= exp.test.foodChance
                            showStimuli(pigeonStimuli(4), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', keySide, inf);
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            showStimuli(pigeonStimuli(5), keySide);
                            keyOut = keyBuffer(secondStimulusDuration, 'goodKey', keySide, inf);
                            result(i).rewarded = 0;
                        end
                        result(i).respPerTrialSecondStimulus = keyOut.goodKey;

                    elseif keyOut.badKey > 0
                        keySide = 2;
                        result(i).choice = keySide;

                        % i2
                        showStimuli(pigeonStimuli(2), keySide);

                        keyOut = keyBuffer(exp.test.stimulusDuration - toc, 'goodKey', keySide, inf);

                        foodChanceBonus = keyOut.goodKey * 1.5;
                        foodChanceThrow = randi([1 100], 1);
                        finalFoodChance = exp.test.foodChance + foodChanceBonus;

                        if foodChanceThrow <= finalFoodChance
                            feeding(exp.feedingTime);
                            result(i).rewarded = 1;
                        else
                            result(i).rewarded = 0;
                        end

                        result(i).respPerTrial = keyOut.goodKey;
                        result(i).foodProbability = finalFoodChance;
                        
                    end
                end

            end
            
            % clear screen
            showStimuli;
            i = i + 1;

        end
        save2File(result, "subject", subjectPrefix);



end


%% Shutdown toolbox
closeWindow;
closeNetworkIO;