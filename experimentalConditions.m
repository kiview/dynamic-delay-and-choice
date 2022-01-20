exp.feedingTime = 4;

exp.pretraining.trialsPerStimulusPerKey = 6; %
exp.pretaining.iti = [1, 5];
exp.pretraining.stimulusDuration = 12; % seconds

exp.pretaining.foodChance123 = 33; % percent
exp.pretaining.foodChance4 = 100; % percent
exp.pretaining.foodChance5 = 0; % percent

% color names as per experiment plan, consider changing actual color in files accordingly
exp.stimulus.orange = loadImage(['stimuli/' 'yellow.jpg']); % orange
exp.stimulus.purple = loadImage(['stimuli/' 'blue.jpg']); % purple
exp.stimulus.green = loadImage(['stimuli/' 'brown.jpg']); % green
exp.stimulus.white = loadImage(['stimuli/' 'white.jpg']); % white
exp.stimulus.grey = loadImage(['stimuli/' 'grey.jpg']); % grey

exp.stimulus.table = [exp.stimulus.orange exp.stimulus.purple exp.stimulus.green];
exp.stimulus.perm = perms(exp.stimulus.table);

exp.pigeon.stimuli = [exp.stimulus.perm(1,:); exp.stimulus.perm(1,:); exp.stimulus.perm(2,:); ...
    exp.stimulus.perm(2,:); exp.stimulus.perm(3,:); exp.stimulus.perm(3,:); ...
    exp.stimulus.perm(4,:); exp.stimulus.perm(4,:); exp.stimulus.perm(5,:); exp.stimulus.perm(6,:)];