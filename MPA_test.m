%% Batching logic
general_keys={'display',0};

% load a number of runs from the same session as one batch
O = monkeypsych_analyze_working({'Y:\Data\Feno\20251007',[1:4]},general_keys);

% alternatively, you can input the files individually
O = monkeypsych_analyze_working({'Y:\Data\Feno\20251007\Fen2025-10-07_01.mat','Y:\Data\Feno\20251007\Fen2025-10-07_02.mat'},general_keys);

% one batch combining several runs from different sessions
O = monkeypsych_analyze_working({'Y:\Data\Feno\20251007',[1:4],'Y:\Data\Feno\20251006',1},general_keys);

% two batches - one for each session
O = monkeypsych_analyze_working({'Y:\Data\Feno\20251007',[1:4]},general_keys,{'Y:\Data\Feno\20251006',1},general_keys);

% two batches - same session, but different keys
instructed_keys={'display',0,'choice',0};
choice_keys={'display',0,'choice',1};
O = monkeypsych_analyze_working({'Y:\Data\Feno\20251007',[1:4]},instructed_keys,{'Y:\Data\Feno\20251007',[1:4]},choice_keys);

% each run as a batch
runs_as_batches_keys={'display',0,'runs_as_batches',1};
O = monkeypsych_analyze_working({'Y:\Data\Feno\20251007',[1:4]},runs_as_batches_keys);

%% now summary plotting

plotoptions=O{1}.keys.plot_val;
plotoptions.summary=[1:10];             %% the summary plots you want to create
plotoptions.summary=[7];             %% the summary plots you want to create
for k=1:numel(O)
MPA_plot_summary(O{k},plotoptions)
end


