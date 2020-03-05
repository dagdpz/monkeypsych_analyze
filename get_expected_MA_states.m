function get_expected_MA_states(type,effector,ignore_effector)
if nargin<3
   ignore_effector=0; 
end
global MA_STATES
get_MA_STATES
% switch type
%     case 1 %fixation only
%         MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ  MA_STATES.SAC_INI MA_STATES.REA_INI MA_STATES.FIX_HOL  MA_STATES.SAC_END MA_STATES.REA_END MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI ];
%         MA_STATES.state_obs     = MA_STATES.FIX_HOL;
%     case 2 % direct movement
%         MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.TAR_ACQ MA_STATES.SAC_INI MA_STATES.REA_INI MA_STATES.TAR_HOL MA_STATES.SAC_END MA_STATES.REA_END  MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
%         MA_STATES.state_obs     = MA_STATES.TAR_ACQ;
%     case 2.5 % direct movement with dimmed targets (same states as in memory!)
%         MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER  MA_STATES.TAR_ACQ  MA_STATES.SAC_INI MA_STATES.REA_INI MA_STATES.TAR_HOL MA_STATES.SAC_END MA_STATES.REA_END MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
%         MA_STATES.state_obs     = MA_STATES.TAR_ACQ;
%     case 3 % memory tasks
%         MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER  MA_STATES.TAR_ACQ_INV MA_STATES.SAC_INI MA_STATES.REA_INI  MA_STATES.TAR_HOL_INV MA_STATES.SAC_END MA_STATES.REA_END MA_STATES.TAR_ACQ  MA_STATES.TAR_HOL MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
%     case 4 % delay response
%         MA_STATES.all_states    = [MA_STATES.INI_TRI  MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.DEL_PER  MA_STATES.TAR_ACQ  MA_STATES.SAC_INI MA_STATES.REA_INI MA_STATES.TAR_HOL  MA_STATES.SAC_END MA_STATES.REA_END MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
%         MA_STATES.state_obs     = MA_STATES.TAR_ACQ;
%     case 5 % Match-to-sample task
%         MA_STATES.all_states    = [MA_STATES.INI_TRI  MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER  MA_STATES.MAT_ACQ MA_STATES.SAC_INI MA_STATES.REA_INI MA_STATES.MAT_HOL MA_STATES.SAC_END MA_STATES.REA_END MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
%         MA_STATES.state_obs     = MA_STATES.MAT_ACQ;
%     case 6 % Match-to-sample task with masked targets
%         MA_STATES.all_states    = [MA_STATES.INI_TRI  MA_STATES.FIX_ACQ  MA_STATES.FIX_HOL  MA_STATES.CUE_ON  MA_STATES.MEM_PER MA_STATES.MAT_ACQ_MSK MA_STATES.SAC_INI MA_STATES.REA_INI MA_STATES.MAT_HOL_MSK MA_STATES.SAC_END MA_STATES.REA_END MA_STATES.SUCCESS  MA_STATES.REWARD  MA_STATES.ITI];
%         MA_STATES.state_obs     = MA_STATES.MAT_ACQ_MSK;
% end
switch type
    case 1 %fixation only
        MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ MA_STATES.SAC_INI MA_STATES.SAC_END MA_STATES.REA_INI MA_STATES.REA_END    MA_STATES.FIX_HOL MA_STATES.SUCCESS MA_STATES.TRI_END MA_STATES.REWARD  MA_STATES.ITI ];
        MA_STATES.state_obs     = MA_STATES.FIX_HOL;
    case 2 % direct movement
        MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ MA_STATES.FIX_HOL MA_STATES.TAR_ACQ MA_STATES.SAC_INI MA_STATES.SAC_END    MA_STATES.REA_INI MA_STATES.REA_END MA_STATES.TAR_HOL MA_STATES.SUCCESS MA_STATES.TRI_END MA_STATES.REWARD  MA_STATES.ITI];
        MA_STATES.state_obs     = MA_STATES.TAR_ACQ;
    case 2.5 % direct movement with dimmed targets (same states as in memory!)
        MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ MA_STATES.FIX_HOL MA_STATES.CUE_ON MA_STATES.MEM_PER MA_STATES.TAR_ACQ     MA_STATES.SAC_INI MA_STATES.SAC_END MA_STATES.REA_INI MA_STATES.REA_END MA_STATES.TAR_HOL MA_STATES.SUCCESS MA_STATES.TRI_END MA_STATES.REWARD  MA_STATES.ITI];
        MA_STATES.state_obs     = MA_STATES.TAR_ACQ;
    case 3 % memory tasks
        MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ MA_STATES.FIX_HOL MA_STATES.CUE_ON MA_STATES.MEM_PER MA_STATES.TAR_ACQ_INV MA_STATES.SAC_INI MA_STATES.SAC_END MA_STATES.REA_INI MA_STATES.REA_END MA_STATES.TAR_HOL_INV MA_STATES.TAR_ACQ MA_STATES.TAR_HOL MA_STATES.SUCCESS MA_STATES.TRI_END MA_STATES.REWARD  MA_STATES.ITI];
    case 4 % delay response
        MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ MA_STATES.FIX_HOL MA_STATES.CUE_ON MA_STATES.DEL_PER MA_STATES.TAR_ACQ     MA_STATES.SAC_INI MA_STATES.SAC_END MA_STATES.REA_INI MA_STATES.REA_END MA_STATES.TAR_HOL MA_STATES.SUCCESS MA_STATES.TRI_END MA_STATES.REWARD  MA_STATES.ITI];
        MA_STATES.state_obs     = MA_STATES.TAR_ACQ;
    case 5 % Match-to-sample task
        MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ MA_STATES.FIX_HOL MA_STATES.CUE_ON MA_STATES.MEM_PER MA_STATES.MAT_ACQ     MA_STATES.SAC_INI MA_STATES.SAC_END MA_STATES.REA_INI MA_STATES.REA_END MA_STATES.MAT_HOL MA_STATES.SUCCESS MA_STATES.TRI_END MA_STATES.REWARD  MA_STATES.ITI];
        MA_STATES.state_obs     = MA_STATES.MAT_ACQ;
    case 6 % Match-to-sample task with masked targets
        MA_STATES.all_states    = [MA_STATES.INI_TRI MA_STATES.FIX_ACQ MA_STATES.FIX_HOL MA_STATES.CUE_ON MA_STATES.MEM_PER MA_STATES.MAT_ACQ_MSK MA_STATES.SAC_INI MA_STATES.SAC_END MA_STATES.REA_INI MA_STATES.REA_END MA_STATES.MAT_HOL_MSK MA_STATES.SUCCESS MA_STATES.TRI_END MA_STATES.REWARD  MA_STATES.ITI];
        MA_STATES.state_obs     = MA_STATES.MAT_ACQ_MSK;
end
MA_STATES.ALL                 =[MA_STATES.INI_TRI MA_STATES.FIX_ACQ MA_STATES.FIX_HOL MA_STATES.CUE_ON  MA_STATES.MEM_PER     MA_STATES.DEL_PER     MA_STATES.TAR_ACQ_INV  MA_STATES.TAR_HOL_INV...
                                MA_STATES.TAR_ACQ MA_STATES.TAR_HOL MA_STATES.MAT_ACQ MA_STATES.MAT_HOL MA_STATES.MAT_ACQ_MSK MA_STATES.MAT_HOL_MSK MA_STATES.SEN_RET      MA_STATES.SUCCESS_ABORT MA_STATES.SUCCESS MA_STATES.TRI_END MA_STATES.REWARD  MA_STATES.ITI...
    MA_STATES.SAC_INI MA_STATES.SAC_END MA_STATES.REA_INI MA_STATES.REA_END];
MA_STATES.ALL_NAMES         ={'Trial Initiation', 'Fixation Acquisition', 'Fixation Hold', 'Cue On', 'Memory period', 'Delay period', 'Target Acquisition (invisible)',...
    'Target Hold (invisible)','Target Acquisition', 'Target Hold', 'Match Aquisition', 'Match Hold', 'Match Aquisition (Masked)', 'Match Hold (Masked)', 'Return to Sensors', 'Not aborted', 'Success', 'Trial end','Reward', 'ITI'};
MA_STATES.LABELS            ={'INI','F acq', 'F hold', 'Cue', 'Mem ', 'Delay', 'TI acq', 'TI hold', 'T acq', 'T hold', 'T acq', 'T hold', 'M acq', 'T hold', 'S Ret', 'Suc', 'Suc', 'End','Rew', 'ITI', 'Peri S', 'Post S', 'Peri R', 'Post R'};
MA_STATES.ALL_CHANGE_NAMES  ={'Holding sensors(?)', 'fixation', 'fixation brightening', 'cue onset', 'cue offset', 'delay period',...
    'go signal', 'target acquired', 'targets visible', 'targets brightening', 'targets visible', 'targets brightening', 'masked targets visible', 'target revealed', 'Target sensor reached', 'success', 'trial ended', 'reward', 'ITI'};
%[label_idx ~]=ismember(MA_STATES.ALL,MA_STATES.all_states);
% removing reach or saccade related states dependent on effector
if ~ignore_effector
switch effector
    case {0,3}
        MA_STATES.all_states(ismember(MA_STATES.all_states,[MA_STATES.REA_INI MA_STATES.REA_END]))=[];
    case 4
        MA_STATES.all_states(ismember(MA_STATES.all_states,[MA_STATES.SAC_INI MA_STATES.SAC_END]))=[];
end
end
[~, label_idx]=ismember(MA_STATES.all_states,MA_STATES.ALL);
%MA_STATES.state_labels=MA_STATES.LABELS(label_idx);
MA_STATES.state_labels=MA_STATES.LABELS(label_idx);

end