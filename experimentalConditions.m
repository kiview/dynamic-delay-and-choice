exp.feedingTime = 0.05;

exp.pretraining.trialsPerStimulusPerKey = 1; %
exp.pretaining.iti = [1, 5];
exp.pretraining.stimulusDuration = 1; % seconds

exp.pretaining.foodChance123 = 33; % percent
exp.pretaining.foodChance4 = 100; % percent
exp.pretaining.foodChance5 = 0; % percent

% color names as per experiment plan, consider changing actual color in files accordingly
exp.stimulus.orange = loadImage(['stimuli/' 'orange.jpg']); % orange
exp.stimulus.purple = loadImage(['stimuli/' 'purple.jpg']); % purple
exp.stimulus.green = loadImage(['stimuli/' 'green.jpg']); % green
exp.stimulus.white = loadImage(['stimuli/' 'white.jpg']); % white
exp.stimulus.grey = loadImage(['stimuli/' 'red.jpg']); % red

exp.stimulus.table = [exp.stimulus.orange exp.stimulus.purple exp.stimulus.green];
exp.stimulus.perm = perms(exp.stimulus.table);

% from 1 to 10
exp.pigeon.numberMapping = [314, 320, 318, 317, 322, 321, 316, 313, 315, 319];

exp.pigeon.stimuli = [exp.stimulus.perm(1,:); exp.stimulus.perm(1,:); exp.stimulus.perm(2,:); ...
    exp.stimulus.perm(2,:); exp.stimulus.perm(3,:); exp.stimulus.perm(3,:); ...
    exp.stimulus.perm(4,:); exp.stimulus.perm(4,:); exp.stimulus.perm(5,:); exp.stimulus.perm(6,:)];