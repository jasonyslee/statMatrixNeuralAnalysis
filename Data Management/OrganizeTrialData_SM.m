function behavMatrixTrialStruct = OrganizeTrialData_SM(behavMatrix, behavMatrixColIDs, trialLims, trialStart)
%% OrganizeTrialData_SM
%   Organizes statMatrix data into a trial-wise organization. 
%% Check Inputs
% The input trialLims is designed to specify the time period around a trial
% to extract on each trial.
if nargin==1
    error('Not enough inputs');
elseif nargin==2 || isempty(trialLims)
    trialLims = [-1 3];
    trialStart = 'Odor';
elseif nargin==3 || isempty(trialStart)
    trialStart = 'Odor';
end

%% Extract Timestamps
tsVect = behavMatrix(:,1);
sampleRate = 1/mode(diff(tsVect));
trlWindow = [round(trialLims(1)*sampleRate) round(trialLims(2)*sampleRate)];

%% Extract Trial Indexes & Poke Events
% separate out odor and position columns 
odorTrlMtx = behavMatrix(:,cellfun(@(a)~isempty(a), strfind(behavMatrixColIDs, 'Odor')));
positionTrlMtx = behavMatrix(:,cellfun(@(a)~isempty(a), regexp(behavMatrixColIDs, 'Position[1-9]$')));
% Sum them on 2d to extract trial indices
trialVect = sum(odorTrlMtx,2);
trialIndices = find(trialVect);
numTrials = sum(trialVect);
% Pull out Poke events and identify pokeIn/Out indices
pokeVect = behavMatrix(:, cellfun(@(a)~isempty(a), strfind(behavMatrixColIDs, 'PokeEvents')));
pokeInNdxs = find(pokeVect==1);
pokeOutNdxs = find(pokeVect==-1);
% Pull out Sequence Length
seqLength = size(positionTrlMtx,2);
% Identify trial performance 
trialPerfVect = behavMatrix(:, cellfun(@(a)~isempty(a), strfind(behavMatrixColIDs, 'Performance')));

%% Create Data input structures
seqNum = cell(1,numTrials);
trialOdor = cell(1,numTrials);
trialPosition = cell(1,numTrials);
trialPerf = cell(1,numTrials);
trialTransDist = cell(1,numTrials);
trialItmItmDist = cell(1,numTrials);
trialLogVect = cell(1,numTrials);
trialNum = cell(1,numTrials);
seq = 0;
%% Go through each trial and pull out trial information and create a logical vector for that trial's time periods specified by the input trialLims
for trl = 1:numTrials
    trialNum{trl} = trl;
    % Identify Trial/Position/Descriptors
    curTrlOdor = find(odorTrlMtx(trialIndices(trl),:)==1);
    curTrlPos = find(positionTrlMtx(trialIndices(trl),:)==1);
    curTrlPerf = trialPerfVect(trialIndices(trl))==1;
    
    trialOdor{trl} = curTrlOdor;
    trialPosition{trl} = curTrlPos;
    trialPerf{trl} = curTrlPerf;
    trialTransDist{trl} = curTrlPos - curTrlOdor;
    if curTrlPos==1
        trialItmItmDist{trl} = nan;
        seq = seq+1;
    else
        trialItmItmDist{trl} = curTrlOdor - trialOdor{trl-1};
    end
    seqNum{trl} = seq;
    
    % Create trial logical vector
    tempLogVect = false(size(behavMatrix,1),1);
    switch trialStart
        case 'Odor'
            curIndex = trialIndices(trl);
        case 'PokeIn'
            curIndex = pokeInNdxs(find(pokeInNdxs<trialIndices(trl)==1,1, 'last'));
        case 'PokeOut'
            curIndex = pokeOutNdxs(find(pokeOutNdxs>trialIndices(trl)==1,1, 'first'));
    end
    curWindow = curIndex + trlWindow;
    tempLogVect(curWindow(1):curWindow(2)) = true;
    trialLogVect{trl} = tempLogVect;
end

%% Create behavMatrixTrialStruct
behavMatrixTrialStruct = struct( 'TrialNum', trialNum, 'SequenceNum', seqNum,...
    'Odor', trialOdor, 'Position', trialPosition, 'Performance', trialPerf,...
    'TranspositionDistance', trialTransDist, 'ItemItemDistance', trialItmItmDist,...
    'TrialLogVect', trialLogVect);
behavMatrixTrialStruct(1).SeqLength = seqLength;
    
    