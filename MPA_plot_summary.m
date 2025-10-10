function OSt=MPA_plot_summary(out,plotoptions)
global P_par
global MA_STATES
MA_load_globals
OSt=struct();
saccades=out.saccades;
reaches=out.reaches;
correlation=out.correlation;
statistic=out.statistic;

task=out.task;
states=out.states;
selected=out.selected;
counts=out.counts;
binary=out.binary;
descriptions = load_descriptions(task,states,binary);
rundescriptions=out.rundescriptions;

%% Histograms
hp1 = hist2per(hist([saccades.lat]', P_par.bins));                     % Saccade latency
hp2 = hist2per(hist([reaches.lat]', P_par.bins));                      % Reach latency
hp3 = hist2per(hist([reaches.lat]'-[saccades.lat]', P_par.bins2));    % Reach - Saccade latency
hp4  = complex2histper([saccades([binary.eyetar_l]).accuracy_xy].',       P_par.bins3);    % Saccade precision in observed left
hp5  = complex2histper([saccades([binary.eyetar_r]).accuracy_xy].',       P_par.bins3);    % Saccade precision in observed right
hp6  = complex2histper([reaches([binary.hndtar_l]).accuracy_xy].',        P_par.bins3);    % Reach precision first touched left
hp7  = complex2histper([reaches([binary.hndtar_r]).accuracy_xy].',        P_par.bins3);    % Reach precision first touched right
hp8  = hist2per(hist(abs([saccades([binary.eyetar_l]).accuracy_xy].'),    P_par.bins3));   % Saccade euclidean distance from target in observed left
hp9  = hist2per(hist(abs([saccades([binary.eyetar_r]).accuracy_xy].'),    P_par.bins3));   % Saccade euclidean distance from target in observed right
hp10 = hist2per(hist(abs([reaches([binary.hndtar_l]).accuracy_xy].'),     P_par.bins3));   % Reach euclidean distance from target first touched left
hp11 = hist2per(hist(abs([reaches([binary.hndtar_r]).accuracy_xy].'),     P_par.bins3));   % Reach euclidean distance from target first touched right

% Histogram y-axis limits
hplim1=max(max([hp1 hp2 hp3 1]))+1;
hplim2=max([max([hp4 hp5 hp6  hp7 ]) 1])+1;
hplim3=max([max([hp8 hp9 hp10 hp11]) 1])+1;


task_description=unique({descriptions.task});
if numel(task_description)>1
    task_description=[strcat(task_description(1:end-1)', ' & ');task_description(end)];
    task_description=[strcat(task_description(1:end-1), ' & ');task_description(end)];
end
monkey_name=unique({rundescriptions.monkeyname});
if numel(monkey_name)>1
    monkey_name=[strcat(monkey_name(1:end-1), ' & ');monkey_name(end)];
end
choice_or_instructed=unique({descriptions.choice});
if numel(choice_or_instructed)>1
    choice_or_instructed=[strcat(choice_or_instructed(1:end-1), ' & ');choice_or_instructed(end)];
end
sacc_onset=unique({descriptions.sacc_onset});
if numel(sacc_onset)>1
    sacc_onset=[strcat(sacc_onset(1:end-1), '/'),sacc_onset(end)];
end
reach_onset=unique({descriptions.state_observed});
if numel(reach_onset)>1
    reach_onset=[strcat(reach_onset(1:end-1), '/'),reach_onset(end)];
end
selected_success = unique({descriptions.aborted});
if numel(selected_success)>1
    selected_success={' hits & errors'};
elseif strcmp(selected_success,'Success')
    selected_success = {' hits'};
else
    selected_success=strcat(' aborted after_', selected_success);
end
marker_cell={'o','s','^','v','>','<'};

% marker_values, fill_idx should be defined with structure and field, as in
% trial_history...!!??
% if isfield(task(1),plotoptions.color_parameter)
%     color_values=unique([task.(plotoptions.color_parameter)]);
% elseif isfield(binary(1),plotoptions.color_parameter)
%     color_values=unique([binary.(plotoptions.color_parameter)]);
% else
%     color_values=1;
% end
if isfield(task(1),plotoptions.marker_parameter)
    marker_values=unique([task.(plotoptions.marker_parameter)]);
else
    marker_values=unique([binary.(plotoptions.marker_parameter)]);
end
if isfield(task(1),plotoptions.fill_parameter)
    fill_idx=[task.(plotoptions.fill_parameter)]==plotoptions.fill_value;
else
    fill_idx=[binary.(plotoptions.fill_parameter)]==plotoptions.fill_value;
end

%% reach hand definition
if all([reaches.reach_hand] == 1)
    color_circle_2d='b';
    reachhand=' L hand';
elseif all([reaches.reach_hand] == 2)
    color_circle_2d='g';
    reachhand=' R hand';
else
    color_circle_2d='c';
    reachhand=' any hand';
end

title_print_out = sprintf([monkey_name{:}, selected_success{:}, choice_or_instructed{:},  plotoptions.additional_description, task_description{:}, reachhand, ' ',num2str(min([rundescriptions.session])), '/', num2str(min([rundescriptions.run])), ' - ', num2str(max([rundescriptions.session])), '/', num2str(max([rundescriptions.run]))]);  %?????


if ismember(2,plotoptions.summary)
    
    plot_title='endpoints 2D ';
    endpoints_2D_plot=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
    %% 2D saccades and reaches positions scatter plot
    
    markersize=35;
    color_saccades_2bo=[0.3 0 0];
    color_saccades_1bo=[0.6 0 0];
    color_saccades_obs=[1 0 0];
    %Reaches colors according to demanded hand and period
    
    %%%% not sure if it works....
    rea_N_idx=isnan([reaches.reach_hand]);
    rea_L_idx=[reaches.reach_hand]==1;
    rea_R_idx=[reaches.reach_hand]==2;
    
    reaches_N=reaches(isnan([reaches.reach_hand]));
    reaches_L=reaches([reaches.reach_hand]==1);
    reaches_R=reaches([reaches.reach_hand]==2);
    
    color_R_reaches_1st         =[0 0.3 0];
    color_R_reaches_ins         =[0 0.6 0];
    color_R_reaches_lst         =[0 1 0];
    color_L_reaches_1st         =[0 0 0.3];
    color_L_reaches_ins         =[0 0 0.6];
    color_L_reaches_las         =[0 0 1];
    color_N_reaches_1st         =[0 0.3 0.3];
    color_N_reaches_ins         =[0 0.6 0.6];
    color_N_reaches_las         =[0 1 1];
    
    if all([reaches.reach_hand] == 1)
        reach_targets_color='b';
    elseif all([reaches.reach_hand] == 2)
        reach_targets_color='g';
    else
        reach_targets_color='c';
    end
    saccade_targets_color='r';
    % Fixation and target circles according to radius
    
    circle_xy                           = exp(1i*(0:0.02:2 * pi))';
    circle_columns                      = numel(circle_xy);
    
    eye.fix_crc = unique([[saccades.fix_pos]; [saccades.fix_rad]]','rows')';
    eye.tar_crc = unique([[saccades.tar_pos]; [saccades.tar_rad]]','rows')';
    hnd.fix_crc = unique([[reaches.fix_pos]; [reaches.fix_rad]]','rows')';
    hnd.tar_crc = unique([[reaches.tar_pos]; [reaches.tar_rad]]','rows')';
    
    hold on
    eye.fix_ci = plot(circle_xy*eye.fix_crc(2,:)+repmat(eye.fix_crc(1,:),circle_columns,1), saccade_targets_color, 'LineWidth', P_par.LineWidth);                   % eye fixation
    eye.tar_ci = plot(circle_xy*eye.tar_crc(2,:)+repmat(eye.tar_crc(1,:),circle_columns,1), saccade_targets_color, 'LineWidth', P_par.LineWidth);                   % saccade target
    hnd.fix_ci = plot(circle_xy*hnd.fix_crc(2,:)+repmat(hnd.fix_crc(1,:),circle_columns,1), reach_targets_color, 'LineWidth', P_par.LineWidth);       % hand fixation
    hnd.tar_ci = plot(circle_xy*hnd.tar_crc(2,:)+repmat(hnd.tar_crc(1,:),circle_columns,1), reach_targets_color, 'LineWidth', P_par.LineWidth);       % reach target
    
    scatter(real([eye.fix_crc(1,:)]),imag([eye.fix_crc(1,:)]),markersize*3,saccade_targets_color,'+', 'LineWidth', P_par.LineWidth);
    scatter(real([eye.tar_crc(1,:)]),imag([eye.tar_crc(1,:)]),markersize*3,saccade_targets_color,'+', 'LineWidth', P_par.LineWidth);
    scatter(real([hnd.fix_crc(1,:)]),imag([hnd.fix_crc(1,:)]),markersize*3,reach_targets_color,'+', 'LineWidth', P_par.LineWidth);
    scatter(real([hnd.tar_crc(1,:)]),imag([hnd.tar_crc(1,:)]),markersize*3,reach_targets_color,'+', 'LineWidth', P_par.LineWidth);
    
    %     color_reach_hand_2bo=zeros(numel(reaches),3);
    %     color_reach_hand_1bo=zeros(numel(reaches),3);
    %     color_reach_hand_obs=zeros(numel(reaches),3);
    %     color_reach_hand_2bo([reaches.reach_hand]==1,3)=0.3;
    %     color_reach_hand_1bo([reaches.reach_hand]==1,3)=0.6;
    %     color_reach_hand_obs([reaches.reach_hand]==1,3)=1;
    %     color_reach_hand_2bo([reaches.reach_hand]==2,2)=0.3;
    %     color_reach_hand_1bo([reaches.reach_hand]==2,2)=0.6;
    %     color_reach_hand_obs([reaches.reach_hand]==2,2)=1;
    %     color_reach_hand_2bo(isnan([reaches.reach_hand]),2:3)=0.3;
    %     color_reach_hand_1bo(isnan([reaches.reach_hand]),2:3)=0.6;
    %     color_reach_hand_obs(isnan([reaches.reach_hand]),2:3)=1;
    
    %colorindex=1:size(color_reach_hand_2bo);
    
    
%     for color_index=1:numel(color_values)
%         if isfield(task(1),plotoptions.color_parameter) || isfield(binary(1),plotoptions.color_parameter)
%             allcolors=lines(numel(color_values));
%             current_color=allcolors(color_index,:);
%             [color_saccades_2bo,color_saccades_1bo,color_saccades_obs,color_R_reaches_1st,color_R_reaches_ins,color_R_reaches_lst,...
%                 color_L_reaches_1st,color_L_reaches_ins,color_L_reaches_las,color_N_reaches_1st,color_N_reaches_ins,color_N_reaches_las]=deal(current_color);
%         end
%         if isfield(task(1),plotoptions.color_parameter)
%             cc_idx=[task.(plotoptions.color_parameter)]==color_values(color_index);
%         elseif isfield(binary(1),plotoptions.color_parameter)
%             cc_idx=[binary.(plotoptions.color_parameter)]==color_values(color_index);
%         else
            cc_idx=true(size(binary))';
%        end
        for marker_index=1:numel(marker_values)
            if isfield(task(1),plotoptions.marker_parameter)
                tt_idx=[task.(plotoptions.marker_parameter)]==marker_values(marker_index);
            else
                tt_idx=[binary.(plotoptions.marker_parameter)]==marker_values(marker_index);
            end
            tc_idx=tt_idx & fill_idx  & cc_idx;
            tn_idx=tt_idx & ~fill_idx & cc_idx;
            
            current_marker=marker_cell{marker_index};
            % scatter plot instructed trials
            if plotoptions.show_trace || ~plotoptions.show_only_one_sac_per_trial
                sa(1)=scatter(real([saccades(tn_idx).endpos_2bo])',imag([saccades(tn_idx).endpos_2bo])',markersize,color_saccades_2bo, current_marker);
                sa(2)=scatter(real([saccades(tn_idx).endpos_1bo])',imag([saccades(tn_idx).endpos_1bo])',markersize,color_saccades_1bo, current_marker);
                sa(3)=scatter(real([saccades(tn_idx).endpos_obs])',imag([saccades(tn_idx).endpos_obs])',markersize,color_saccades_obs, current_marker);
                sa(4)=scatter(real([saccades(tc_idx).endpos_2bo])',imag([saccades(tc_idx).endpos_2bo])',markersize,color_saccades_2bo, current_marker,'fill');
                sa(5)=scatter(real([saccades(tc_idx).endpos_1bo])',imag([saccades(tc_idx).endpos_1bo])',markersize,color_saccades_1bo, current_marker,'fill');
                sa(6)=scatter(real([saccades(tc_idx).endpos_obs])',imag([saccades(tc_idx).endpos_obs])',markersize,color_saccades_obs, current_marker,'fill');
            else
                sa(3)=scatter(real([saccades(tn_idx).endpos])',imag([saccades(tn_idx).endpos])',markersize,color_saccades_obs, current_marker);
                sa(6)=scatter(real([saccades(tc_idx).endpos])',imag([saccades(tc_idx).endpos])',markersize,color_saccades_obs, current_marker,'fill');
            end
            
            rN(1)=scatter(real([reaches(tn_idx & rea_N_idx).pos_first])' , imag([reaches(tn_idx & rea_N_idx).pos_first])' ,markersize, color_N_reaches_1st, current_marker);
            rN(2)=scatter(real([reaches(tn_idx & rea_N_idx).pos_inside])', imag([reaches(tn_idx & rea_N_idx).pos_inside])',markersize, color_N_reaches_ins, current_marker);
            rN(3)=scatter(real([reaches(tn_idx & rea_N_idx).pos_last])'  , imag([reaches(tn_idx & rea_N_idx).pos_last])'  ,markersize, color_N_reaches_las, current_marker);
            rN(4)=scatter(real([reaches(tc_idx & rea_N_idx).pos_first])' , imag([reaches(tc_idx & rea_N_idx).pos_first])' ,markersize, color_N_reaches_1st, current_marker,'fill');
            rN(5)=scatter(real([reaches(tc_idx & rea_N_idx).pos_inside])', imag([reaches(tc_idx & rea_N_idx).pos_inside])',markersize, color_N_reaches_ins, current_marker,'fill');
            rN(6)=scatter(real([reaches(tc_idx & rea_N_idx).pos_last])'  , imag([reaches(tc_idx & rea_N_idx).pos_last])'  ,markersize, color_N_reaches_las, current_marker,'fill');
            
            rL(1)=scatter(real([reaches(tn_idx & rea_L_idx).pos_first])' , imag([reaches(tn_idx & rea_L_idx).pos_first])' ,markersize, color_L_reaches_1st, current_marker);
            rL(2)=scatter(real([reaches(tn_idx & rea_L_idx).pos_inside])', imag([reaches(tn_idx & rea_L_idx).pos_inside])',markersize, color_L_reaches_ins, current_marker);
            rL(3)=scatter(real([reaches(tn_idx & rea_L_idx).pos_last])'  , imag([reaches(tn_idx & rea_L_idx).pos_last])'  ,markersize, color_L_reaches_las, current_marker);
            rL(4)=scatter(real([reaches(tc_idx & rea_L_idx).pos_first])' , imag([reaches(tc_idx & rea_L_idx).pos_first])' ,markersize, color_L_reaches_1st, current_marker,'fill');
            rL(5)=scatter(real([reaches(tc_idx & rea_L_idx).pos_inside])', imag([reaches(tc_idx & rea_L_idx).pos_inside])',markersize, color_L_reaches_ins, current_marker,'fill');
            rL(6)=scatter(real([reaches(tc_idx & rea_L_idx).pos_last])'  , imag([reaches(tc_idx & rea_L_idx).pos_last])'  ,markersize, color_L_reaches_las, current_marker,'fill');
            
            rR(1)=scatter(real([reaches(tn_idx & rea_R_idx).pos_first])' , imag([reaches(tn_idx & rea_R_idx).pos_first])' ,markersize, color_R_reaches_1st, current_marker);
            rR(2)=scatter(real([reaches(tn_idx & rea_R_idx).pos_inside])', imag([reaches(tn_idx & rea_R_idx).pos_inside])',markersize, color_R_reaches_ins, current_marker);
            rR(3)=scatter(real([reaches(tn_idx & rea_R_idx).pos_last])'  , imag([reaches(tn_idx & rea_R_idx).pos_last])'  ,markersize, color_R_reaches_lst, current_marker);
            rR(4)=scatter(real([reaches(tc_idx & rea_R_idx).pos_first])' , imag([reaches(tc_idx & rea_R_idx).pos_first])' ,markersize, color_R_reaches_1st, current_marker,'fill');
            rR(5)=scatter(real([reaches(tc_idx & rea_R_idx).pos_inside])', imag([reaches(tc_idx & rea_R_idx).pos_inside])',markersize, color_R_reaches_ins, current_marker,'fill');
            rR(6)=scatter(real([reaches(tc_idx & rea_R_idx).pos_last])'  , imag([reaches(tc_idx & rea_R_idx).pos_last])'  ,markersize, color_R_reaches_lst, current_marker,'fill');
            
            if plotoptions.show_trace
                
                % scatter plot start positions
                scatter(real([saccades(tn_idx).startpos_2bo])',imag([saccades(tn_idx).startpos_2bo])',markersize,color_saccades_2bo, current_marker);
                scatter(real([saccades(tn_idx).startpos_1bo])',imag([saccades(tn_idx).startpos_1bo])',markersize,color_saccades_1bo, current_marker);
                scatter(real([saccades(tn_idx).startpos_obs])',imag([saccades(tn_idx).startpos_obs])',markersize,color_saccades_obs, current_marker);
                scatter(real([saccades(tc_idx).startpos_2bo])',imag([saccades(tc_idx).startpos_2bo])',markersize,color_saccades_2bo, current_marker,'fill');
                scatter(real([saccades(tc_idx).startpos_1bo])',imag([saccades(tc_idx).startpos_1bo])',markersize,color_saccades_1bo, current_marker,'fill');
                scatter(real([saccades(tc_idx).startpos_obs])',imag([saccades(tc_idx).startpos_obs])',markersize,color_saccades_obs, current_marker,'fill');
                
                % plot connective lines
                n_sacc_max=numel(saccades(1).endpos_obs);
                start_endpos_unshaped=vertcat([saccades.startpos_2bo],[saccades.endpos_2bo],[saccades.startpos_1bo],[saccades.endpos_1bo],[saccades.startpos_obs],[saccades.endpos_obs]);
                start_endpos=start_endpos_unshaped(:);
                trace_eye=reshape(start_endpos,6*n_sacc_max,numel(start_endpos)./(6*n_sacc_max)).';
                for k=1:size(trace_eye,1)
                    plot(real(trace_eye(k,~isnan(trace_eye(k,:))))',imag(trace_eye(k,~isnan(trace_eye(k,:))))','Color',color_saccades_obs);
                end
            end
            
        end;
    %end
    
    if plotoptions.show_sliding
        %plot(real([reaches.pos_first; reaches.pos_inside; reaches.pos_last]), imag([reaches.pos_first; reaches.pos_inside; reaches.pos_last]), 'Color',reach_targets_color)
        plot(real([reaches_N.pos_first; reaches_N.pos_inside; reaches_N.pos_last]), imag([reaches_N.pos_first; reaches_N.pos_inside; reaches_N.pos_last]), 'Color',color_N_reaches_las)
        plot(real([reaches_L.pos_first; reaches_L.pos_inside; reaches_L.pos_last]), imag([reaches_L.pos_first; reaches_L.pos_inside; reaches_L.pos_last]), 'Color',color_L_reaches_las)
        plot(real([reaches_R.pos_first; reaches_R.pos_inside; reaches_R.pos_last]), imag([reaches_R.pos_first; reaches_R.pos_inside; reaches_R.pos_last]), 'Color',color_R_reaches_lst)
        
    end
    if plotoptions.show_trial_number == 1;
        n_sacc_max=numel(saccades(1).endpos_obs);
        trialnumbers=repmat([selected.trials],n_sacc_max,1);
        string_trialnumbers=num2str(trialnumbers(:));
        text(real([saccades.endpos_2bo])' + 0.01, imag([saccades.endpos_2bo])' + 0.01, string_trialnumbers);
        text(real([saccades.endpos_1bo])' + 0.01, imag([saccades.endpos_1bo])' + 0.01, string_trialnumbers);
        text(real([saccades.endpos_obs])' + 0.01, imag([saccades.endpos_obs])' + 0.01, string_trialnumbers);
        text(double(real([reaches.pos_first])')     + 0.01, double(imag([reaches.pos_first])')  + 0.01, num2str([selected.trials]'));
        text(double(real([reaches.pos_inside])')    + 0.01, double(imag([reaches.pos_inside])') + 0.01, num2str([selected.trials]'));
        text(double(real([reaches.pos_last])')      + 0.01, double(imag([reaches.pos_last])')   + 0.01, num2str([selected.trials]'));
    end
    
    
    %P_options('Saccade endpoints','x [deg]','y [deg]',[-P_par.screen_w_deg/ 2 P_par.screen_w_deg/ 2],[P_par.screen_h_lim_bot/2 P_par.screen_h_lim_top/2]);
    P_options('Saccade endpoints','x [deg]','y [deg]',[-P_par.screen_w_deg/ 2 P_par.screen_w_deg/ 2],[-P_par.screen_h_deg/2 P_par.screen_h_deg/2]);
    %set(gca,'Ylim', Ylim_2dplot, 'Xlim', Xlim_2dplot, 'XLimMode', 'manual', 'YLimMode', 'manual', 'FontName', P_par.FontName, 'FontSize', P_par.FontSize);
    grid on
    axis equal
    
    title_and_save(endpoints_2D_plot,plot_title,title_print_out,plotoptions);
end

if ismember(1,plotoptions.summary)
    %% Initiation latencies, durations and positions of saccades & reaches plots
    plot_title='Summary timing ';
    summary_timing_figure=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
    
    %% Histograms
    % histogram for saccade initiation
    subplot(4,5,[1 6]);
    bar(P_par.bins, hp1/sum(hp1)*100, 1);
    P_options(['Saccade initiation after ' ,sacc_onset{:}], 'Time(s)', 'Percentage', P_par.xlim_e, [0 hplim1]);
    
    % histogram for reach initiation
    subplot(4,5,[11 16]);
    bar(P_par.bins, hp2/sum(hp2)*100, 1);
    P_options(['Reach initiation after', ' ', reach_onset{:}], 'Time(s)', 'Percentage', P_par.xlim_h, [0 hplim1]);
    
    
    %% Scatter plots for saccade and reaches initiations and durations
    current_structure={saccades reaches saccades reaches};
    current_fieldname={'lat','lat', 'dur','dur'};
    statistic_fieldname={'sac_lat','rea_lat','sac_dur','rea_dur'};
    subplot_title={'Saccade initiation per trial','Reach initiation per trial','Saccade duration per trial','Reach duration per trial'};
    subplot_number_array=[2 7; 12 17; 3 8; 13 18];
    refline_starts=[0 rundescriptions.run_ends];
    refline_ends=[rundescriptions.run_ends];
    for p_i=1:4
        subplot(4,5,subplot_number_array(p_i,:));
        hold on;
        for marker_index = 1:numel(marker_values)
            tt_idx=[task.(plotoptions.marker_parameter)]==marker_values(marker_index);
            plot(find(tt_idx & ~fill_idx), [current_structure{p_i}(tt_idx & ~fill_idx).(current_fieldname{p_i})]', marker_cell{marker_index});
            plot(find(tt_idx & fill_idx), [current_structure{p_i}(tt_idx & fill_idx).(current_fieldname{p_i})]', marker_cell{marker_index},'MarkerfaceColor','b');
            tt_idx=tt_idx & ~isnan( [current_structure{p_i}.(current_fieldname{p_i})]);
            tr=struct('n',num2cell(1:numel(tt_idx)));
            Paf=polyfit([tr(tt_idx & ~fill_idx).n], [current_structure{p_i}(tt_idx & ~fill_idx).(current_fieldname{p_i})],1);
            Puf=polyfit([tr(tt_idx &  fill_idx).n], [current_structure{p_i}(tt_idx &  fill_idx).(current_fieldname{p_i})],1); 
            hline=refline(Paf(1),Paf(2));set(hline,'Color','r','LineWidth',2);
            hline=refline(Puf(1),Puf(2));set(hline,'Color','r','LineWidth',2);
            text(numel(current_structure{p_i})/4,0.9,['slope '   , sprintf('%.4f',Paf(2))],       'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
            text(numel(current_structure{p_i})/4,0.8,['slope '   , sprintf('%.4f',Puf(2))],       'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);

        end;
        if plotoptions.show_run_ends
            plot([rundescriptions.run_ends;rundescriptions.run_ends],         P_par.ylim_2'*ones(1,numel(rundescriptions.run_ends)) ,    'Color', [0 0 1], 'LineWidth', P_par.LineWidth);
            plot([rundescriptions.session_ends;rundescriptions.session_ends], P_par.ylim_2'*ones(1,numel(rundescriptions.session_ends)), 'Color', [0 1 0], 'LineWidth', P_par.LineWidth);
            plot([rundescriptions.monkey_ends;rundescriptions.monkey_ends],   P_par.ylim_2'*ones(1,numel(rundescriptions.monkey_ends)),  'Color', [1 0 0], 'LineWidth', P_par.LineWidth);
        end
        
        P_options(subplot_title{p_i}, 'Trial', 'Time(ms)', [0 numel(current_structure{p_i})+1], P_par.ylim_2);
        %Stat_field=[statistic.(statistic_fieldname{p_i})];
        corrcon=[correlation.conditions];
        Corr_field=correlation(find([corrcon.success]==1,1,'first'));
        %hline=refline;
%         text(numel(current_structure{p_i})/4,0.9,['slope '   , sprintf('%.4f',Corr_field.slope_value)],       'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
        text(numel(current_structure{p_i})/4,0.7,['p '       , sprintf('%.4f',Corr_field.([current_fieldname{p_i} '_p']))], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
        text(numel(current_structure{p_i})/4,0.6,['Spearman ', sprintf('%.4f',Corr_field.([current_fieldname{p_i} '_r']))], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
        
%         for line_index=1:numel([Stat_field.slope_value]);
%             yend=Stat_field(line_index).intercept_value+Stat_field(line_index).slope_value.*(refline_ends(line_index)-refline_starts(line_index));
%             hline=line([refline_starts(line_index);refline_ends(line_index)],[Stat_field(line_index).intercept_value;yend]);
%             set(hline,'Color','r','LineWidth',2)
%         end
    end
    
    %% 2D saccades and reaches positions scatter plot
    
    %Reaches colors according to demanded hand and period
    
    color_reach_hand_03=zeros(numel(reaches),3);
    color_reach_hand_06=zeros(numel(reaches),3);
    color_reach_hand_10=zeros(numel(reaches),3);
    color_reach_hand_03([reaches.reach_hand]==1,3)=0.3;
    color_reach_hand_06([reaches.reach_hand]==1,3)=0.6;
    color_reach_hand_10([reaches.reach_hand]==1,3)=1;
    color_reach_hand_03([reaches.reach_hand]==2,2)=0.3;
    color_reach_hand_06([reaches.reach_hand]==2,2)=0.6;
    color_reach_hand_10([reaches.reach_hand]==2,2)=1;
    color_reach_hand_03(isnan([reaches.reach_hand]),2:3)=0.3;
    color_reach_hand_06(isnan([reaches.reach_hand]),2:3)=0.6;
    color_reach_hand_10(isnan([reaches.reach_hand]),2:3)=1;
    
    %colorindex=1:size(color_reach_hand_03);
    
    subplot(2,5,[4 5])
    hold on
    
    for marker_index=1:numel(marker_values)
        tt_idx=[task.(plotoptions.marker_parameter)]==marker_values(marker_index);
        tc_idx=tt_idx & fill_idx;
        tn_idx=tt_idx & ~fill_idx;
        
        current_marker=marker_cell{marker_index};
        % scatter plot instructed trials
        All_saccades_ini=vertcat(saccades.ini_all);
        All_saccades_endpos=vertcat(saccades.endpos_all);
        %All_saccades_ini=vertcat(saccades.ini_all);
        All_start_2bo=repmat(vertcat(states.start_2bo),1,size(All_saccades_ini,2));
        All_start_1bo=repmat(vertcat(states.start_1bo),1,size(All_saccades_ini,2));
        All_start_obs=repmat(vertcat(states.start_obs),1,size(All_saccades_ini,2));
        All_start_1ao=repmat(vertcat(states.start_1ao),1,size(All_saccades_ini,2));
        sac_2bo_idx=All_saccades_ini >= All_start_2bo & All_saccades_ini < All_start_1bo;
        sac_1bo_idx=All_saccades_ini >= All_start_1bo & All_saccades_ini < All_start_obs;
        sac_obs_idx=All_saccades_ini >= All_start_obs & All_saccades_ini < All_start_1ao;
        sac_1ao_idx=All_saccades_ini >= All_start_1ao;
        
        midx_n=repmat(tn_idx',1,size(All_saccades_ini,2));
        midx_c=repmat(tc_idx',1,size(All_saccades_ini,2));
        
        if plotoptions.show_trace
            
            scatter(real(All_saccades_endpos(sac_2bo_idx & midx_n))',imag(All_saccades_endpos(sac_2bo_idx & midx_n))',15,[0.3 0 0], current_marker);
            scatter(real(All_saccades_endpos(sac_1bo_idx & midx_n))',imag(All_saccades_endpos(sac_1bo_idx & midx_n))',15,[0.6 0 0], current_marker);
            scatter(real(All_saccades_endpos(sac_obs_idx & midx_n))',imag(All_saccades_endpos(sac_obs_idx & midx_n))',15,[1 0 0], current_marker);
            scatter(real(All_saccades_endpos(sac_1ao_idx & midx_n))',imag(All_saccades_endpos(sac_1ao_idx & midx_n))',15,[1 0 0], current_marker);
            
            scatter(real(All_saccades_endpos(sac_2bo_idx & midx_c))',imag(All_saccades_endpos(sac_2bo_idx & midx_c))',15,[0.3 0 0], current_marker,'fill');
            scatter(real(All_saccades_endpos(sac_1bo_idx & midx_c))',imag(All_saccades_endpos(sac_1bo_idx & midx_c))',15,[0.6 0 0], current_marker,'fill');
            scatter(real(All_saccades_endpos(sac_obs_idx & midx_c))',imag(All_saccades_endpos(sac_obs_idx & midx_c))',15,[1 0 0],   current_marker,'fill');
            scatter(real(All_saccades_endpos(sac_1ao_idx & midx_c))',imag(All_saccades_endpos(sac_1ao_idx & midx_c))',15,[1 0 0],   current_marker,'fill');
        elseif plotoptions.show_only_one_sac_per_trial
            scatter(real([saccades(tn_idx).endpos])',imag([saccades(tn_idx).endpos])',15,[1 0 0], current_marker);
            scatter(real([saccades(tc_idx).endpos])',imag([saccades(tc_idx).endpos])',15,[1 0 0], current_marker,'fill');
        else
            if plotoptions.show_sac_2bo
                scatter(real(All_saccades_endpos(sac_2bo_idx & midx_n))',imag(All_saccades_endpos(sac_2bo_idx & midx_n))',15,[0.3 0 0], current_marker);
                scatter(real(All_saccades_endpos(sac_2bo_idx & midx_c))',imag(All_saccades_endpos(sac_2bo_idx & midx_c))',15,[0.3 0 0], current_marker,'fill');
            end
            if plotoptions.show_sac_1bo
                scatter(real(All_saccades_endpos(sac_1bo_idx & midx_n))',imag(All_saccades_endpos(sac_1bo_idx & midx_n))',15,[0.6 0 0], current_marker);
                scatter(real(All_saccades_endpos(sac_1bo_idx & midx_c))',imag(All_saccades_endpos(sac_1bo_idx & midx_c))',15,[0.6 0 0], current_marker,'fill');
            end
            if plotoptions.show_sac_obs
                scatter(real(All_saccades_endpos(sac_obs_idx & midx_n))',imag(All_saccades_endpos(sac_obs_idx & midx_n))',15,[1 0 0], current_marker);
                scatter(real(All_saccades_endpos(sac_obs_idx & midx_c))',imag(All_saccades_endpos(sac_obs_idx & midx_c))',15,[1 0 0],   current_marker,'fill');
            end
            if plotoptions.show_sac_1ao
                scatter(real(All_saccades_endpos(sac_1ao_idx & midx_n))',imag(All_saccades_endpos(sac_1ao_idx & midx_n))',15,[1 0 0], current_marker);
                scatter(real(All_saccades_endpos(sac_1ao_idx & midx_c))',imag(All_saccades_endpos(sac_1ao_idx & midx_c))',15,[1 0 0],   current_marker,'fill');
            end
        end
        
        
        if plotoptions.show_trace  % probably possible to simplify that!
            
            % plot connective lines
            start_endpos_unshaped_unsorted=[vertcat(saccades.startpos_all),vertcat(saccades.endpos_all)];
            n_sacc_max=size(All_saccades_ini,2);
            for k=1:n_sacc_max
                start_endpos_unshaped(:,2*k-1:2*k)=start_endpos_unshaped_unsorted(:,[k, n_sacc_max+k]);
            end
            %start_endpos_unshaped=vertcat([saccades.startpos_2bo],[saccades.endpos_2bo],[saccades.startpos_1bo],[saccades.endpos_1bo],[saccades.startpos_obs],[saccades.endpos_obs]);
            start_endpos=start_endpos_unshaped(:);
            trace_eye=reshape(start_endpos,2*n_sacc_max,numel(start_endpos)./(2*n_sacc_max)).';
            for k=1:size(trace_eye,1)
                plot(real(trace_eye(k,~isnan(trace_eye(k,:))))',imag(trace_eye(k,~isnan(trace_eye(k,:))))','Color',[1 0 0]);
            end
        end
        
        
        
        if plotoptions.show_sliding
            %     line(reaches.pos_plot(:, [1,3,5])', reaches.pos_plot(:, [2,4,6])', 'Color',[0 1 0])
            
            %line(real([reaches.pos_first; reaches.pos_inside; reaches.pos_last]), imag([reaches.pos_first; reaches.pos_inside; reaches.pos_last]), 'Color',[0 1 0])
            %calcoptions.
            scatter(real([reaches(tn_idx).pos_first])', imag([reaches(tn_idx).pos_first])',15, color_reach_hand_03(tn_idx,:), current_marker);
            scatter(real([reaches(tn_idx).pos_inside])', imag([reaches(tn_idx).pos_inside])',15, color_reach_hand_06(tn_idx,:), current_marker);
            scatter(real([reaches(tn_idx).pos_last])', imag([reaches(tn_idx).pos_last])',15, color_reach_hand_10(tn_idx,:), current_marker);
            
            % scatter plot choice trials
            scatter(real([reaches(tc_idx).pos_first])',  imag([reaches(tc_idx).pos_first])',15,  color_reach_hand_03(tc_idx,:), current_marker,'fill');
            scatter(real([reaches(tc_idx).pos_inside])', imag([reaches(tc_idx).pos_inside])',15, color_reach_hand_06(tc_idx,:), current_marker,'fill');
            scatter(real([reaches(tc_idx).pos_last])',   imag([reaches(tc_idx).pos_last])',15,   color_reach_hand_10(tc_idx,:), current_marker,'fill');
            
            plot(real([reaches.pos_first; reaches.pos_inside; reaches.pos_last]), imag([reaches.pos_first; reaches.pos_inside; reaches.pos_last]), 'Color',color_circle_2d)
            
        end
        
        scatter(real([reaches(tn_idx).endpos])', imag([reaches(tn_idx).endpos])',15, color_reach_hand_10(tn_idx,:), current_marker);
        scatter(real([reaches(tc_idx).endpos])',  imag([reaches(tc_idx).endpos])',15,  color_reach_hand_10(tc_idx,:), current_marker,'fill');
        
    end;
    if plotoptions.show_trial_number == 1;
        n_sacc_max=numel(saccades(1).endpos_obs);
        trialnumbers=repmat([selected.trials],n_sacc_max,1);
        string_trialnumbers=num2str(trialnumbers(:));
        if plotoptions.show_sac_2bo
            text(real(All_saccades_endpos(sac_2bo_idx))' + 0.01, imag(All_saccades_endpos(sac_2bo_idx))' + 0.01, string_trialnumbers(sac_2bo_idx(:),:));
        end
        if plotoptions.show_sac_1bo
            text(real(All_saccades_endpos(sac_1bo_idx))' + 0.01, imag(All_saccades_endpos(sac_1bo_idx))' + 0.01, string_trialnumbers(sac_1bo_idx(:),:));
        end
        if plotoptions.show_sac_obs
            text(real(All_saccades_endpos(sac_obs_idx))' + 0.01, imag(All_saccades_endpos(sac_obs_idx))' + 0.01, string_trialnumbers(sac_obs_idx(:),:));
        end
        if plotoptions.show_sac_1ao
            text(real(All_saccades_endpos(sac_1ao_idx))' + 0.01, imag(All_saccades_endpos(sac_1ao_idx))' + 0.01, string_trialnumbers(sac_1ao_idx(:),:));
        end
        
        if plotoptions.show_sliding
            text(double(real([reaches.pos_first])')     + 0.01, double(imag([reaches.pos_first])')  + 0.01, num2str([selected.trials]'));
            text(double(real([reaches.pos_inside])')    + 0.01, double(imag([reaches.pos_inside])') + 0.01, num2str([selected.trials]'));
            text(double(real([reaches.pos_last])')      + 0.01, double(imag([reaches.pos_last])')   + 0.01, num2str([selected.trials]'));
        else
            text(double(real([reaches.endpos])')     + 0.01, double(imag([reaches.endpos])')  + 0.01, num2str([selected.trials]'));
            
            
        end
    end
    
    
    % Fixation and target circles according to radius
    
    circle_xy                           = exp(1i*(0:0.02:2 * pi))';
    circle_columns                      = numel(circle_xy);
    
    eye.fix_crc = unique([[saccades.fix_pos]; [saccades.fix_rad]]','rows')';
    eye.tar_crc = unique([[saccades.tar_pos]; [saccades.tar_rad]]','rows')';
    hnd.fix_crc = unique([[reaches.fix_pos]; [reaches.fix_rad]]','rows')';
    hnd.tar_crc = unique([[reaches.tar_pos]; [reaches.tar_rad]]','rows')';
    
    eye.fix_ci = plot(circle_xy*eye.fix_crc(2,:)+repmat(eye.fix_crc(1,:),circle_columns,1), 'r', 'LineWidth', P_par.LineWidth -1);                   % eye fixation
    eye.tar_ci = plot(circle_xy*eye.tar_crc(2,:)+repmat(eye.tar_crc(1,:),circle_columns,1), 'r', 'LineWidth', P_par.LineWidth -1);                   % saccade target
    hnd.fix_ci = plot(circle_xy*hnd.fix_crc(2,:)+repmat(hnd.fix_crc(1,:),circle_columns,1), color_circle_2d, 'LineWidth', P_par.LineWidth -1);       % hand fixation
    hnd.tar_ci = plot(circle_xy*hnd.tar_crc(2,:)+repmat(hnd.tar_crc(1,:),circle_columns,1), color_circle_2d, 'LineWidth', P_par.LineWidth -1);       % reach target
    
    grid on
    axis equal
    fix_height=mean(imag(~isnan([saccades.fix_pos [reaches.fix_pos]])));
    P_options('Eye and hand position','x(deg)','y(deg)',[-P_par.screen_w_deg/ 2 P_par.screen_w_deg/ 2],[fix_height - P_par.screen_h_deg/2 fix_height + P_par.screen_h_deg/2]);
    %set(gca,'Ylim', Ylim_2dplot, 'Xlim', Xlim_2dplot, 'XLimMode', 'manual', 'YLimMode', 'manual', 'FontName', P_par.FontName, 'FontSize', P_par.FontSize);
    
    % correlation saccade and reach initiation residuals
    subplot(4,5,14);
    
    rea_lat_stat=statistic.rea_lat;
    sac_lat_stat=statistic.sac_lat;
    if numel([rea_lat_stat.residuals]) == numel([sac_lat_stat.residuals])
        plot([rea_lat_stat.residuals],[sac_lat_stat.residuals],'o')
        hline = refline ;%%%??? (correlation.lat_stat_slope.value,correlation.lat_stat_intercept.value);
    set(hline,'Color','r','LineWidth',2)
    end
    axis equal
    text(-0.4,0.4,['r ', sprintf('%.4f',correlation.lat_r)], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    %text(-0.4,0.3,['significance ', sprintf('%.4f',correlation.lat_sig)], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    P_options('Residual correlation in initiation', 'Reaches', 'Saccades', [-0.5 0.5], [-0.5 0.5]);
    
    % correlation saccade and reach initiation
    subplot(4,5,19);
    if numel(reaches) == numel(saccades)
        plot([reaches.lat]',[saccades.lat]','o')
        hline = refline ;%%%??? (correlation.lat_slope.value,correlation.lat_intercept.value);
    set(hline,'Color','r','LineWidth',2)
    end
    axis equal
    text(0.1,0.9,['r ', sprintf('%.4f',correlation.lat_r)], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    %text(0.1,0.8,['significance ', sprintf('%.4f',correlation.lat_sig)], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    P_options('Latency correlation from raw data', 'Reaches', 'Saccades', [0 1], [0 1]);
    
    subplot(4, 5, [15 20]); % histogram for saccade initiation
    bar(P_par.bins2, hp3, 1);
    hold on
    P_options(['R - S latency after' reach_onset{:}], 'Time(s)', 'Percentage', P_par.xlim_h-0.2, [0 hplim1]);
    
    %print_out2 = sprintf([monkey_name{:}, selected_success{:}, choice_or_instructed{:},  plotoptions.additional_description, task_description{:}, ' ',num2str(min([rundescriptions.session])), '/', num2str(min([rundescriptions.run])), ' - ', num2str(max([rundescriptions.session])), '/', num2str(max([rundescriptions.run]))]);  %?????
    
    title_and_save(summary_timing_figure,plot_title,title_print_out,plotoptions)
    
end

if ismember(3,plotoptions.summary)
    %% Precision plot
    plot_title='Summary precision ';
    summary_precision_figure=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
    
    subplot(4,5,[1 6]);
    hold on
    bar(P_par.bins3, hp4(:,1), 1, 'FaceColor', 'yellow');
    bar(P_par.bins3, hp4(:,2), 1, 'FaceColor','red');
    P_options('Saccade x and y precision left', '', 'Percentage', P_par.xlim_fig_2, [0 hplim2]);
    legend('X','Y');
    alpha(0.5);
    
    subplot(4,5,[2 7]);
    hold on
    bar(P_par.bins3, hp5(:,1), 1, 'FaceColor', 'yellow');
    bar(P_par.bins3, hp5(:,2), 1, 'FaceColor','red');
    P_options('Saccade x and y precision right', '', 'Percentage', P_par.xlim_fig_2, [0 hplim2]);
    legend('X','Y');
    alpha(0.5);
    
    subplot(4,5,[11 16]);
    hold on
    bar(P_par.bins3, hp6(:,1), 1, 'FaceColor', 'yellow');
    bar(P_par.bins3, hp6(:,2), 1, 'FaceColor','red');
    P_options('Reach x and y precision left', 'Overshoot(deg)   Undershoot(deg)', 'Percentage', P_par.xlim_fig_2, [0 hplim2]);
    legend('X','Y');
    alpha(0.5);
    
    subplot(4,5,[12 17]);
    hold on
    bar(P_par.bins3, hp7(:,1), 1, 'FaceColor', 'yellow');
    bar(P_par.bins3, hp7(:,2), 1, 'FaceColor','red');
    P_options('Reach x and y precision right', 'Undershot(deg)   Overshoot(deg)', 'Percentage', P_par.xlim_fig_2, [0 hplim2]);
    legend('X','Y');
    alpha(0.5);
    
    subplot(4,5,[3 8]);
    dat=tabulate({descriptions.aborted});
    [~,sorting_idx]=sort([dat{:,2}]);
    for rowidx=1:size(dat,1)
        text(0.1,rowidx,dat(sorting_idx(rowidx),2), 'FontSize', P_par.FontSize-5) ;
        text(0.8,rowidx,dat(sorting_idx(rowidx),1), 'FontSize', P_par.FontSize-5) ;
        %text(4,rowidx,dat(rowidx,3)) ;
    end
    
    text(0.1,rowidx+1,'#') ;
    text(0.8,rowidx+1, 'states') ;
    P_options('Errors in states', '', '', [0,5], [0,rowidx+2]);
    set(gca,'xtick',[],'ytick',[]);
    set(gca,'xcolor',[1 1 1],'ycolor',[1 1 1])
    
    subplot(4,5,[13 18]);
    dat=tabulate({descriptions.abort_code});
    [~,sorting_idx]=sort([dat{:,2}]);
    for rowidx=1:size(dat,1)
        text(0.1,rowidx,dat(sorting_idx(rowidx),2), 'FontSize', P_par.FontSize-5) ;
        text(0.8,rowidx,dat(sorting_idx(rowidx),1), 'FontSize', P_par.FontSize-5,'interpreter','none') ;
    end
    
    text(0.1,rowidx+1,'#') ;
    text(0.8,rowidx+1, 'errors') ;
    P_options('Error codes', '', '', [0,5], [0,rowidx+2]);
    set(gca,'xtick',[],'ytick',[]);
    set(gca,'xcolor',[1 1 1],'ycolor',[1 1 1])
    
    % cnames = {'State','Ocassions','Percentage'};
    % uitable('Data',dat,'ColumnName',cnames,'Position',[790 590 290 370]); %'Position',[left bottom width height]
    % P_options('Ending of trials', ' ', ' ', P_par.xlim_fig_2, [0 max(hp1)+0.1]);
    
    %dat2=tabulate({descriptions.abort_code});
    %cnames = {'Error type                                        ','Ocassions','Percentage'};
    %uitable('Data',dat2,'ColumnName',cnames,'Position',[790 180 290 370]); %'Position',[left bottom width height]
    % P_options('Ending of trials', ' ', ' ', P_par.xlim_fig_2, [0 max(hp1)+0.1]);
    
    subplot(4,5,4);
    bar([(counts.sac_abo_inst_l+counts.rea_abo_inst_l)*100/(counts.sac_tot_inst_l+counts.rea_tot_inst_l) (counts.sac_suc_inst_l+counts.rea_suc_inst_l)*100/(counts.sac_tot_inst_l+counts.rea_tot_inst_l)], 0.5);
    P_options('Success rate left for instructed trials', '', 'Percentage', P_par.xlim_fig_3, [0 100]);
    set(gca,'XTickLabel',{'Aborted';'Successful'})
    text(0.55,75,['Targets viewed on the left for instructed trials ' sprintf('%.0f',counts.left_inst_saw)], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    
    subplot(4,5,5);
    bar([(counts.rea_abo_inst_r+counts.sac_abo_inst_r)*100/(counts.sac_tot_inst_r+counts.rea_tot_inst_r) (counts.rea_suc_inst_r+counts.sac_suc_inst_r)*100/(counts.sac_tot_inst_r+counts.rea_tot_inst_r)], 0.5);
    P_options('Success rate right for instructed trials', '', 'Percentage', P_par.xlim_fig_3, [0 100]);
    set(gca,'XTickLabel',{'Aborted';'Successful'})
    text(0.55,80,['Targets viewed on the right for instructed trials ' sprintf('%.0f',counts.right_inst_saw)], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    
    subplot(4,5,[9 10]);
    bar([counts.left_chosen*100/counts.total_chosen counts.right_chosen*100/counts.total_chosen], 0.5);
    
    %bar([(counts.rea_suc_choi_l+counts.sac_suc_choi_l)*100/(counts.tot_choi) (counts.rea_suc_choi_r+counts.sac_suc_choi_r)*100/(counts.tot_choi)], 0.5);
    P_options('Percentage of choices in successful trials', '', 'Percentage', P_par.xlim_fig_3, [0 100]);
    set(gca,'XTickLabel',{'Left';'Right'})
    text(1.26,75,['Right chosen ' sprintf('%.2f',counts.right_chosen*100/counts.total_chosen) '%'], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    text(1.26,85,['Right chosen ' sprintf('%.2f',counts.right_chosen) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    text(1.26,95,['Total choices ' sprintf('%.2f',counts.tot_choi) ], 'FontSize', P_par.FontSize-3, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    
    %
    %     % percentage of right selected all
    % counts.right_choice_percentage_right_large          = counts.right_choice_ratio_right_large*100;
    % counts.right_choice_percentage_right_normal         = counts.right_choice_ratio_right_normal*100;
    % counts.right_choice_percentage_right_small          = counts.right_choice_ratio_right_small*100;
    % % percentage of right selected aborted
    % counts.right_choice_percentage_right_large_abo      = counts.right_choice_ratio_right_large_abo*100;
    % counts.right_choice_percentage_right_normal_abo     = counts.right_choice_ratio_right_normal_abo*100;
    % counts.right_choice_percentage_right_small_abo      = counts.right_choice_ratio_right_small_abo*100;
    % % percentage of right selected success
    % counts.right_choice_percentage_right_large_suc      = counts.right_choice_ratio_right_large_suc*100;
    % counts.right_choice_percentage_right_normal_suc     = counts.right_choice_ratio_right_normal_suc*100;
    % counts.right_choice_percentage_right_small_suc      = counts.right_choice_ratio_right_small_suc*100;
    %
    % % percentage of left selected all
    % counts.left_choice_percentage_left_large          = counts.left_choice_ratio_left_large*100;
    % counts.left_choice_percentage_left_normal         = counts.left_choice_ratio_left_normal*100;
    % counts.left_choice_percentage_left_small          = counts.left_choice_ratio_left_small*100;
    % % percentage of left selected aborted
    % counts.left_choice_percentage_left_large_abo      = counts.left_choice_ratio_left_large_abo*100;
    % counts.left_choice_percentage_left_normal_abo     = counts.left_choice_ratio_left_normal_abo*100;
    % counts.left_choice_percentage_left_small_abo      = counts.left_choice_ratio_left_small_abo*100;
    % % percentage of left selected success
    % counts.left_choice_percentage_left_large_suc      = counts.left_choice_ratio_left_large_suc*100;
    % counts.left_choice_percentage_left_normal_suc     = counts.left_choice_ratio_left_normal_suc*100;
    % counts.left_choice_percentage_left_small_suc      = counts.left_choice_ratio_left_small_suc*100;
    
    
    
    
    
    
    
    
    subplot(4,5,14);
    hold on
    bar(P_par.bins3, hp8, 1, 'FaceColor', 'blue');
    P_options('Saccade euclidean distance left', '','Percentage', P_par.xlim_fig_2, [0 hplim3]);
    
    subplot(4,5,15);
    hold on
    bar(P_par.bins3, hp9, 1, 'FaceColor', 'blue');
    P_options('Saccade euclidean distance right', '', 'Percentage', P_par.xlim_fig_2, [0 hplim3]);
    
    subplot(4,5,19);
    hold on
    bar(P_par.bins3, hp10, 1, 'FaceColor', 'blue');
    P_options('Reach euclidean distance left', '', 'Percentage', P_par.xlim_fig_2, [0 hplim3]);
    
    subplot(4,5,20);
    hold on
    bar(P_par.bins3, hp11, 1, 'FaceColor', 'blue');
    P_options('Reach euclidean distance right', '', 'Percentage', P_par.xlim_fig_2, [0 hplim3]);
    
    
    %% -- %%
    % nanpar9={NaN(1,4)};
    %printout_rea = struct('rt_median', [], 'rt_mean', [], 'rt_std', [], 'precision_lxy_rxy_mean', nanpar9, 'precision_lxy_rxy_std', nanpar9);
    
    %printout_sac = struct('rt_median', [], 'rt_mean', [], 'rt_std', [], 'precision_lxy_rxy_mean', nanpar9, 'precision_lxy_rxy_std', nanpar9);
    
    % statistics preparation
    printout_sac.rt_median = nanmedian([saccades.lat]);
    printout_sac.rt_mean   = nanmean([saccades.lat]);
    printout_sac.rt_std    = nanstd([saccades.lat]);
    printout_sac.precision_lxy_rxy_mean = abs(nanmean([saccades([binary.eyetar_l]).accuracy_xy saccades([binary.eyetar_r]).accuracy_xy]));
    printout_sac.precision_lxy_rxy_std = abs(nanstd([saccades([binary.eyetar_l]).accuracy_xy saccades([binary.eyetar_r]).accuracy_xy]));
    
    printout_rea.rt_median = nanmedian([reaches.lat]);
    printout_rea.rt_mean   = nanmean([reaches.lat]);
    printout_rea.rt_std    = nanstd([reaches.lat]);
    printout_rea.precision_lxy_rxy_mean = abs(nanmean([reaches([binary.hndtar_l]).accuracy_xy reaches([binary.hndtar_r]).accuracy_xy]));
    printout_rea.precision_lxy_rxy_std = abs(nanstd([reaches([binary.hndtar_l]).accuracy_xy reaches([binary.hndtar_r]).accuracy_xy]));
    
%     disp('Saccades')
%     struct2table(printout_sac)
%     
%     disp('Reaches')
%     struct2table(printout_rea)
    title_and_save(summary_precision_figure,plot_title,title_print_out,plotoptions);
end

if ismember(4,plotoptions.summary)
    plothandsseperately=0;
    if plothandsseperately
        n_rows=4;
    else
        n_rows=3;
    end
    
    
    
    %     if any([reaches.reach_hand]==1) && any([reaches.reach_hand]==2)
    %
    %         undershoot.bar_rh = [counts.sac_ushoot_rh_l counts.rea_ushoot_rh_l counts.sac_ushoot_rh_r counts.rea_ushoot_rh_r];
    %         undershoot.bar_lh = [counts.sac_ushoot_lh_l counts.rea_ushoot_lh_l counts.sac_ushoot_lh_r counts.rea_ushoot_lh_r];
    %         overshoot.bar_rh =  [counts.sac_oshoot_rh_l counts.rea_oshoot_rh_l counts.sac_oshoot_rh_r counts.rea_oshoot_rh_r];
    %         overshoot.bar_lh =  [counts.sac_oshoot_lh_l counts.rea_oshoot_lh_l counts.sac_oshoot_lh_r counts.rea_oshoot_lh_r];
    %
    %         subplot(4,5,4)
    %         bh_hu_rh=bar(-undershoot.bar_rh);
    %         ch_hu_rh=get(bh_hu_rh,'children');
    %         cd_hu_rh=repmat(1:numel(undershoot.bar_rh),5,1);
    %         cd_hu_rh=[cd_hu_rh(:);nan];
    %         set(ch_hu_rh,'facevertexcdata',cd_hu_rh);
    %         colormap([[1,0,0];[0,1,0];[1,0,0];[0,1,0]])
    %         set(get(bh_hu_rh(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
    %
    %         hold on
    %         bh_ho_rh=bar(overshoot.bar_rh);
    %         ch_ho_rh=get(bh_ho_rh,'children');
    %         cd_ho_rh=repmat(1:numel(overshoot.bar_rh),5,1);
    %         cd_ho_rh=[cd_ho_rh(:);nan];
    %         set(ch_ho_rh,'facevertexcdata',cd_ho_rh);
    %         colormap([[1,0,0];[0,1,0];[1,0,0];[0,1,0]])
    %         set(get(bh_ho_rh(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
    %
    %         if sum([overshoot.bar_rh undershoot.bar_rh]) > 0
    %             max_dim_r = max(abs([overshoot.bar_rh undershoot.bar_rh]));
    %             axis([0 5 -max_dim_r max_dim_r]);
    %         end
    %
    %         ylabel('Undershoot / Overshoot', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    %         set(gca,'XTick',[1 2 3 4])
    %         set(gca,'XTickLabel',{'saccades left' 'reaches left' 'saccades right' 'reaches right'},'FontName',P_par.FontName,'FontSize',P_par.FontSize);
    %         title('Right hand', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    %
    %
    %         subplot(4,5,5)
    %
    %         bh_hu_lh=bar(-undershoot.bar_lh);
    %         ch_hu_lh=get(bh_hu_lh,'children');
    %         cd_hu_lh=repmat(1:numel(undershoot.bar_lh),5,1);
    %         cd_hu_lh=[cd_hu_lh(:);nan];
    %         set(ch_hu_lh,'facevertexcdata',cd_hu_lh);
    %         colormap([[1,0,0];[0,0,1];[1,0,0];[0,0,1]])
    %         set(get(bh_hu_lh(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
    %
    %         hold on
    %         bh_ho_lh=bar(overshoot.bar_lh);
    %         ch_ho_lh=get(bh_ho_lh,'children');
    %         cd_ho_lh=repmat(1:numel(overshoot.bar_lh),5,1);
    %         cd_ho_lh=[cd_ho_lh(:);nan];
    %         set(ch_ho_lh,'facevertexcdata',cd_ho_lh);
    %         colormap([[1,0,0];[0,0,1];[1,0,0];[0,0,1]])
    %         set(get(bh_ho_lh(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
    %
    %         if sum([overshoot.bar_lh undershoot.bar_lh]) > 0
    %             max_dim_l = max(abs([overshoot.bar_lh undershoot.bar_lh]));
    %             axis([0 5 -max_dim_l max_dim_l]);
    %         end
    %
    %         ylabel('Undershoot / Overshoot', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    %         set(gca,'XTick',[1 2 3 4])
    %         set(gca,'XTickLabel',{'saccades left' 'reaches left' 'saccades right' 'reaches right'},'FontName',P_par.FontName,'FontSize',P_par.FontSize);
    %         title('Left hand', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    %
    %     else
    %         subplot(4,5,[4 5])
    %         overshoot.bar  = [counts.sac_oshoot_l counts.rea_oshoot_l counts.sac_oshoot_r counts.rea_oshoot_r];
    %         undershoot.bar = [counts.sac_ushoot_l counts.rea_ushoot_l counts.sac_ushoot_r counts.rea_ushoot_r];
    %
    %         bh_hu=bar(-undershoot.bar);
    %         ch_hu=get(bh_hu,'children');
    %         cd_hu=repmat(1:numel(undershoot.bar),5,1);
    %         cd_hu=[cd_hu(:);nan];
    %         set(ch_hu,'facevertexcdata',cd_hu);
    %         colormap([[1,0,0];[0,1,1];[1,0,0];[0,1,1]])
    %         set(get(bh_hu(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
    %
    %         hold on
    %         bh_ho=bar(overshoot.bar);
    %         ch_ho=get(bh_ho,'children');
    %         cd_ho=repmat(1:numel(overshoot.bar),5,1);
    %         cd_ho=[cd_ho(:);nan];
    %         set(ch_ho,'facevertexcdata',cd_ho);
    %         colormap([[1,0,0];[0,1,1];[1,0,0];[0,1,1]])
    %         set(get(bh_ho(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
    %
    %         if sum([overshoot.bar undershoot.bar]) > 0
    %             max_dim = max(abs([overshoot.bar undershoot.bar]));
    %             axis([0 5 -max_dim max_dim]);
    %         end
    %
    %         ylabel('Undershoot / Overshoot', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    %         set(gca,'XTick',[1 2 3 4])
    %         set(gca,'XTickLabel',{'saccades left' 'reaches left' 'saccades right' 'reaches right'},'FontName',P_par.FontName,'FontSize',P_par.FontSize);
    %
    %         mtit(summary_errors_figure,print_out2, 'fontsize', 12, 'color', 'xoff', 0.0, 'yoff', 0.04, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    %     end
    
    loglefthandindex=[reaches.reach_hand]==1;
    logrighthandindex=[reaches.reach_hand]==2;
    log_eye_fix_rad=~isnan([saccades.fix_rad]);
    log_eye_tar_rad=~isnan([saccades.tar_rad]);
    log_hnd_fix_rad=~isnan([reaches.fix_rad]);
    log_hnd_tar_rad=~isnan([reaches.tar_rad]);
    abort_codes={task.abort_code};
    logidx_break= ismember([states.state_abo],[MA_STATES.FIX_HOL,MA_STATES.CUE_ON,MA_STATES.DEL_PER,MA_STATES.MEM_PER,MA_STATES.TAR_HOL,MA_STATES.TAR_HOL_INV]);
    for type=unique([task.type])
        logidx_type=[task.type]==type;
        
        for effector=unique([task.effector])
            logidx_effector=[task.effector]==effector;
            eye_fix_radii   =   unique([saccades(logidx_type & logidx_effector & log_eye_fix_rad).fix_rad]);
            lhd_fix_radii   =   unique([reaches(logidx_type & logidx_effector & log_hnd_fix_rad & loglefthandindex).fix_rad]);
            rhd_fix_radii   =   unique([reaches(logidx_type & logidx_effector & log_hnd_fix_rad & logrighthandindex).fix_rad]);
            ahd_fix_radii   =   unique([reaches(logidx_type & logidx_effector & log_hnd_fix_rad).fix_rad]);
            eye_tar_radii   =   unique([saccades(logidx_type & logidx_effector & log_eye_tar_rad).tar_rad]);
            lhd_tar_radii   =   unique([reaches(logidx_type & logidx_effector & log_hnd_tar_rad & loglefthandindex).tar_rad]);
            rhd_tar_radii   =   unique([reaches(logidx_type & logidx_effector & log_hnd_tar_rad & logrighthandindex).tar_rad]);
            ahd_tar_radii   =   unique([reaches(logidx_type & logidx_effector & log_hnd_tar_rad).tar_rad]);
            sessions        = unique([selected.session]);
            sessionidx      = 1:numel(sessions);
            inprecision_ls_eye =[];
            inprecision_up_eye =[];
            inprecision_do_eye =[];
            inprecision_rs_eye =[];
            inprecision_ls_lhd =[];
            inprecision_up_lhd =[];
            inprecision_do_lhd =[];
            inprecision_rs_lhd =[];
            inprecision_ls_rhd =[];
            inprecision_up_rhd =[];
            inprecision_do_rhd =[];
            inprecision_ls_ahd =[];
            inprecision_up_ahd =[];
            inprecision_do_ahd =[];
            inprecision_rs_ahd =[];
            
            fixation_breaks_tar_ahd =[];
            fixation_breaks_tiv_ahd =[];
            fixation_breaks_tar_lhd =[];
            fixation_breaks_tiv_lhd =[];
            fixation_breaks_tar_rhd =[];
            fixation_breaks_tiv_rhd =[];
            fixation_breaks_tar_eye =[];
            fixation_breaks_tiv_eye =[];
            
            for idx=sessionidx   %max([selected.num_file])
                
                
                %logfileindex=[selected.num_file]==idx;
                logsessionindex=[selected.session]==sessions(idx);
                %sessions(idx)=unique([selected(logfileindex).session]);
                %runs(idx)=unique([selected(logfileindex).run]);
                
                %logidx_combined= logfileindex & logidx_type & logidx_effector;
                logidx_combined= logsessionindex & logidx_type & logidx_effector;
                
                logidx_inprecise_eye=[binary.sac_inprecise]==1;
                logidx_inprecise_ahd=[binary.rea_inprecise]==1;
                logidx_inprecise_lhd=[binary.rea_inprecise]==1 & loglefthandindex;
                logidx_inprecise_rhd=[binary.rea_inprecise]==1 & logrighthandindex;
                
                
                %total_errors(idx)                    =sum([binary.success]==0 & logidx_combined);
                total_trials(idx)                    =sum(logidx_combined);
                total_hits(idx)                      =sum([binary.success]==1 & logidx_combined);
                total_not_initiated(idx)             =sum([states.state_abo]==MA_STATES.FIX_ACQ & logidx_combined);
                total_errors(idx)                    =sum([binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ & logidx_combined);
                
                valid_totals(idx)=                  sum(logidx_combined)~=0;
                total_errorrate(idx)=                total_errors(idx)/sum(logidx_combined)*100;
                total_breaks(idx)=                   sum(logidx_break & logidx_combined & ~logidx_inprecise_eye & ~logidx_inprecise_ahd)/sum(logidx_combined)*100;
                total_inprecise(idx)=                sum((logidx_inprecise_eye|logidx_inprecise_ahd) & logidx_combined & [binary.success]==0)/sum(logidx_combined)*100;
                total_prec_err(idx)=                 sum((logidx_inprecise_eye|logidx_inprecise_ahd) & logidx_combined & [binary.success]==0)/sum(logidx_combined)*100;
                
                total_nogo(idx)=                     sum(([binary.sac_doesntgo]|[binary.sac_nottotarget]|[binary.rea_doesntgo]|[binary.rea_nottotarget]) & logidx_combined)/sum(logidx_combined)*100;
                total_sensor_errors(idx)=            sum((strcmp(abort_codes,'ABORT_RELEASE_SENSOR_HOLD_STATE')|strcmp(abort_codes,'ABORT_DIRTY_SENSORS')|strcmp(abort_codes,'ABORT_USE_INCORRECT_HAND')) & logidx_combined)/sum(logidx_combined)*100;
                total_moved(idx)=                    sum((strcmp(abort_codes,'ABORT_JAW')|strcmp(abort_codes,'ABORT_BODY')) & logidx_combined)/sum(logidx_combined)*100;
                
                no_move_eye(idx)=            sum([binary.sac_doesntgo]       & logidx_combined)/ total_errors(idx)*100;
                nottotarget_eye(idx)=        sum([binary.sac_nottotarget]    & logidx_combined)/ total_errors(idx)*100;
                no_move_ahd(idx)=            sum([binary.rea_doesntgo]       & logidx_combined)/ total_errors(idx)*100;
                nottotarget_ahd(idx)=        sum([binary.rea_nottotarget]    & logidx_combined)/ total_errors(idx)*100;
                no_move_lhd(idx)=            sum([binary.rea_doesntgo]       & logidx_combined & loglefthandindex)/  total_errors(idx)*100;
                no_move_rhd(idx)=            sum([binary.rea_doesntgo]       & logidx_combined & logrighthandindex)/ total_errors(idx)*100;
                nottotarget_lhd(idx)=        sum([binary.rea_nottotarget]    & logidx_combined & loglefthandindex)/  total_errors(idx)*100;
                nottotarget_rhd(idx)=        sum([binary.rea_nottotarget]    & logidx_combined & logrighthandindex)/ total_errors(idx)*100;
                
                
                rl_limit=0.1;
                total_rad_errors=0;
                idx_rad=ones(size([saccades.fix_rad]));
                for radius_index=1:numel(eye_fix_radii)
                    idx_rad=[saccades.fix_rad]==eye_fix_radii(radius_index);
                    total_rad_errors=sum(idx_rad & logidx_combined & [binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ);
                    fixation_breaks_fix_eye(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_EYE_FIX_HOLD_STATE')     & logidx_combined)/total_rad_errors*100; %% & idx_rad
                    fixation_breaks_cue_eye(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_EYE_CUE_ON_STATE')       & logidx_combined)/total_rad_errors*100;
                    fixation_breaks_mem_eye(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_EYE_MEM_PER_STATE')      & logidx_combined)/total_rad_errors*100;
                    fixation_breaks_del_eye(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_EYE_DEL_PER_STATE')      & logidx_combined)/total_rad_errors*100;
                end
                
                fixation_breaks_tar_ahd(idx)=sum(strcmp(abort_codes,'ABORT_HND_TAR_HOLD_STATE')     & ~ logidx_inprecise_ahd & logidx_combined)/total_rad_errors*100;
                fixation_breaks_tiv_ahd(idx)=sum(strcmp(abort_codes,'ABORT_HND_TAR_HOLD_INV_STATE') & ~ logidx_inprecise_ahd & logidx_combined)/total_rad_errors*100;
                fixation_breaks_tar_lhd(idx)=sum(strcmp(abort_codes,'ABORT_HND_TAR_HOLD_STATE')     & ~ logidx_inprecise_ahd & logidx_combined  & loglefthandindex)/total_rad_errors*100;
                fixation_breaks_tiv_lhd(idx)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_TAR_HOLD_INV_STATE') & ~ logidx_inprecise_ahd & logidx_combined  & loglefthandindex)/total_rad_errors*100;
                fixation_breaks_tar_rhd(idx)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_TAR_HOLD_STATE')     & ~ logidx_inprecise_ahd & logidx_combined  & logrighthandindex)/total_rad_errors*100;
                fixation_breaks_tiv_rhd(idx)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_TAR_HOLD_INV_STATE') & ~ logidx_inprecise_ahd & logidx_combined  & logrighthandindex)/total_rad_errors*100;
                
                %                 for radius_index=1:numel(ahd_fix_radii)
                %                     idx_rad=[reaches.fix_rad]==ahd_fix_radii(radius_index);
                %                     fixation_breaks_fix_ahd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_FIX_HOLD_STATE')     & logidx_combined)/total_errors(idx)*100;
                %                     fixation_breaks_cue_ahd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_CUE_ON_STATE')       & logidx_combined)/total_errors(idx)*100;
                %                     fixation_breaks_mem_ahd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_MEM_PER_STATE')      & logidx_combined)/total_errors(idx)*100;
                %                     fixation_breaks_del_ahd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_DEL_PER_STATE')      & logidx_combined)/total_errors(idx)*100;
                %                 end
                %                 for radius_index=1:numel(lhd_fix_radii)
                %                     idx_rad=[reaches.fix_rad]==lhd_fix_radii(radius_index);
                %                     fixation_breaks_fix_lhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_FIX_HOLD_STATE')     & logidx_combined & loglefthandindex)/total_errors(idx)*100;
                %                     fixation_breaks_cue_lhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_CUE_ON_STATE')       & logidx_combined & loglefthandindex)/total_errors(idx)*100;
                %                     fixation_breaks_mem_lhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_MEM_PER_STATE')      & logidx_combined & loglefthandindex)/total_errors(idx)*100;
                %                     fixation_breaks_del_lhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_DEL_PER_STATE')      & logidx_combined & loglefthandindex)/total_errors(idx)*100;
                %                 end
                %                 for radius_index=1:numel(rhd_fix_radii)
                %                     idx_rad=[reaches.fix_rad]==rhd_fix_radii(radius_index);
                %                     fixation_breaks_fix_rhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_FIX_HOLD_STATE')     & logidx_combined & logrighthandindex)/total_errors(idx)*100;
                %                     fixation_breaks_cue_rhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_CUE_ON_STATE')       & logidx_combined & logrighthandindex)/total_errors(idx)*100;
                %                     fixation_breaks_mem_rhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_MEM_PER_STATE')      & logidx_combined & logrighthandindex)/total_errors(idx)*100;
                %                     fixation_breaks_del_rhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_DEL_PER_STATE')      & logidx_combined & logrighthandindex)/total_errors(idx)*100;
                %                 end
                fixation_breaks_fix_ahd(idx)=sum(strcmp(abort_codes,'ABORT_HND_FIX_HOLD_STATE')     & logidx_combined)/total_errors(idx)*100;
                fixation_breaks_cue_ahd(idx)=sum(strcmp(abort_codes,'ABORT_HND_CUE_ON_STATE')       & logidx_combined)/total_errors(idx)*100;
                fixation_breaks_mem_ahd(idx)=sum(strcmp(abort_codes,'ABORT_HND_MEM_PER_STATE')      & logidx_combined)/total_errors(idx)*100;
                fixation_breaks_del_ahd(idx)=sum(strcmp(abort_codes,'ABORT_HND_DEL_PER_STATE')      & logidx_combined)/total_errors(idx)*100;
                fixation_breaks_fix_lhd(idx)=sum(strcmp(abort_codes,'ABORT_HND_FIX_HOLD_STATE')     & logidx_combined & loglefthandindex)/total_errors(idx)*100;
                fixation_breaks_cue_lhd(idx)=sum(strcmp(abort_codes,'ABORT_HND_CUE_ON_STATE')       & logidx_combined & loglefthandindex)/total_errors(idx)*100;
                fixation_breaks_mem_lhd(idx)=sum(strcmp(abort_codes,'ABORT_HND_MEM_PER_STATE')      & logidx_combined & loglefthandindex)/total_errors(idx)*100;
                fixation_breaks_del_lhd(idx)=sum(strcmp(abort_codes,'ABORT_HND_DEL_PER_STATE')      & logidx_combined & loglefthandindex)/total_errors(idx)*100;
                fixation_breaks_fix_rhd(idx)=sum(strcmp(abort_codes,'ABORT_HND_FIX_HOLD_STATE')     & logidx_combined & logrighthandindex)/total_errors(idx)*100;
                fixation_breaks_cue_rhd(idx)=sum(strcmp(abort_codes,'ABORT_HND_CUE_ON_STATE')       & logidx_combined & logrighthandindex)/total_errors(idx)*100;
                fixation_breaks_mem_rhd(idx)=sum(strcmp(abort_codes,'ABORT_HND_MEM_PER_STATE')      & logidx_combined & logrighthandindex)/total_errors(idx)*100;
                fixation_breaks_del_rhd(idx)=sum(strcmp(abort_codes,'ABORT_HND_DEL_PER_STATE')      & logidx_combined & logrighthandindex)/total_errors(idx)*100;
                for radius_index=1:numel(eye_tar_radii)
                    idx_rad=[saccades.tar_rad]==eye_tar_radii(radius_index);
                    total_rad_errors=sum(idx_rad & logidx_combined & [binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ);
                    fixation_breaks_tar_eye(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_EYE_TAR_HOLD_STATE')     & ~ logidx_inprecise_eye & logidx_combined)/total_rad_errors*100;
                    fixation_breaks_tiv_eye(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_EYE_TAR_HOLD_INV_STATE') & ~ logidx_inprecise_eye & logidx_combined)/total_rad_errors*100;
                    inprecision_ls_eye(idx,radius_index)=sum(idx_rad & real([saccades.tar_pos]-[saccades.fix_pos])<=-rl_limit                               & logidx_inprecise_eye & logidx_combined)/total_rad_errors*100;
                    inprecision_rs_eye(idx,radius_index)=sum(idx_rad & real([saccades.tar_pos]-[saccades.fix_pos])>=rl_limit                                & logidx_inprecise_eye & logidx_combined)/total_rad_errors*100;
                    inprecision_up_eye(idx,radius_index)=sum(idx_rad & imag([saccades.tar_pos]-[saccades.fix_pos])>=rl_limit                                & logidx_inprecise_eye & logidx_combined)/total_rad_errors*100;
                    inprecision_do_eye(idx,radius_index)=sum(idx_rad & imag([saccades.tar_pos]-[saccades.fix_pos])<=-rl_limit                               & logidx_inprecise_eye & logidx_combined)/total_rad_errors*100;
                    inprecision_ud_eye(idx,radius_index)=sum(idx_rad & real([saccades.tar_pos]-[saccades.fix_pos])>-rl_limit & real([saccades.tar_pos]-[saccades.fix_pos])<rl_limit    & logidx_inprecise_eye & logidx_combined)/total_rad_errors*100;
                end
                for radius_index=1:numel(ahd_tar_radii)
                    idx_rad=[reaches.tar_rad]==ahd_tar_radii(radius_index);
                    total_rad_errors=sum(idx_rad & logidx_combined & [binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ);
                    %                 fixation_breaks_tar_ahd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_TAR_HOLD_STATE')     & ~ logidx_inprecise_ahd & logidx_combined)/total_rad_errors*100;
                    %                 fixation_breaks_tiv_ahd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_TAR_HOLD_INV_STATE') & ~ logidx_inprecise_ahd & logidx_combined)/total_rad_errors*100;
                    inprecision_ls_ahd(idx,radius_index)=sum(idx_rad & real([reaches.tar_pos]-[reaches.fix_pos])<=-rl_limit                              & logidx_inprecise_ahd & logidx_combined)/total_rad_errors*100;
                    inprecision_rs_ahd(idx,radius_index)=sum(idx_rad & real([reaches.tar_pos]-[reaches.fix_pos])>=rl_limit                               & logidx_inprecise_ahd & logidx_combined)/total_rad_errors*100;
                    inprecision_up_ahd(idx,radius_index)=sum(idx_rad & imag([reaches.tar_pos]-[reaches.fix_pos])>=rl_limit                               & logidx_inprecise_ahd & logidx_combined)/total_rad_errors*100;
                    inprecision_do_ahd(idx,radius_index)=sum(idx_rad & imag([reaches.tar_pos]-[reaches.fix_pos])<=-rl_limit                              & logidx_inprecise_ahd & logidx_combined)/total_rad_errors*100;
                    inprecision_ud_ahd(idx,radius_index)=sum(idx_rad & real([reaches.tar_pos]-[reaches.fix_pos])>-rl_limit & real([reaches.tar_pos]-[reaches.fix_pos])<rl_limit    & logidx_inprecise_ahd & logidx_combined)/total_rad_errors*100;
                end
                for radius_index=1:numel(lhd_tar_radii)
                    idx_rad=[reaches.tar_rad]==lhd_tar_radii(radius_index);
                    total_rad_errors=sum(idx_rad & logidx_combined & [binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ);
                    %                 fixation_breaks_tar_lhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_TAR_HOLD_STATE')     & ~ logidx_inprecise_lhd & logidx_combined & loglefthandindex)/total_rad_errors*100;
                    %                 fixation_breaks_tiv_lhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_TAR_HOLD_INV_STATE') & ~ logidx_inprecise_lhd & logidx_combined & loglefthandindex)/total_rad_errors*100;
                    inprecision_ls_lhd(idx,radius_index)=sum(idx_rad & real([reaches.tar_pos]-[reaches.fix_pos])<=-rl_limit                               & logidx_inprecise_lhd & logidx_combined)/total_rad_errors*100;
                    inprecision_rs_lhd(idx,radius_index)=sum(idx_rad & real([reaches.tar_pos]-[reaches.fix_pos])>=rl_limit                                & logidx_inprecise_lhd & logidx_combined)/total_rad_errors*100;
                    inprecision_up_lhd(idx,radius_index)=sum(idx_rad & imag([reaches.tar_pos]-[reaches.fix_pos])>=rl_limit                                & logidx_inprecise_lhd & logidx_combined)/total_rad_errors*100;
                    inprecision_do_lhd(idx,radius_index)=sum(idx_rad & imag([reaches.tar_pos]-[reaches.fix_pos])<=-rl_limit                               & logidx_inprecise_lhd & logidx_combined)/total_rad_errors*100;
                    inprecision_ud_lhd(idx,radius_index)=sum(idx_rad & real([reaches.tar_pos]-[reaches.fix_pos])>-rl_limit & real([reaches.tar_pos]-[reaches.fix_pos])<rl_limit    & logidx_inprecise_lhd & logidx_combined)/total_rad_errors*100;
                end
                for radius_index=1:numel(rhd_tar_radii)
                    idx_rad=[reaches.tar_rad]==rhd_tar_radii(radius_index);
                    total_rad_errors=sum(idx_rad & logidx_combined & [binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ);
                    %                 fixation_breaks_tar_rhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_TAR_HOLD_STATE')     & ~ logidx_inprecise_rhd & logidx_combined & logrighthandindex)/total_rad_errors*100;
                    %                 fixation_breaks_tiv_rhd(idx,radius_index)=sum(idx_rad & strcmp(abort_codes,'ABORT_HND_TAR_HOLD_INV_STATE') & ~ logidx_inprecise_rhd & logidx_combined & logrighthandindex)/total_rad_errors*100;
                    inprecision_ls_rhd(idx,radius_index)=sum(idx_rad & real([reaches.tar_pos]-[reaches.fix_pos])<=-rl_limit                               & logidx_inprecise_rhd & logidx_combined)/total_rad_errors*100;
                    inprecision_rs_rhd(idx,radius_index)=sum(idx_rad & real([reaches.tar_pos]-[reaches.fix_pos])>=rl_limit                                & logidx_inprecise_rhd & logidx_combined)/total_rad_errors*100;
                    inprecision_up_rhd(idx,radius_index)=sum(idx_rad & imag([reaches.tar_pos]-[reaches.fix_pos])>=rl_limit                                & logidx_inprecise_rhd & logidx_combined)/total_rad_errors*100;
                    inprecision_do_rhd(idx,radius_index)=sum(idx_rad & imag([reaches.tar_pos]-[reaches.fix_pos])<=-rl_limit                               & logidx_inprecise_rhd & logidx_combined)/total_rad_errors*100;
                    inprecision_ud_rhd(idx,radius_index)=sum(idx_rad & real([reaches.tar_pos]-[reaches.fix_pos])>-rl_limit & real([reaches.tar_pos]-[reaches.fix_pos])<rl_limit    & logidx_inprecise_rhd & logidx_combined)/total_rad_errors*100;
                end
            end
            
            
            valid_errors=total_errors~=0;
            sessionidx_errors=sessionidx(valid_errors);
            sessionidx_totals=sessionidx(valid_totals);
            for idx=sessionidx
                logsessionindex=[selected.session]==sessions(idx);
                logidx_combined= logsessionindex & logidx_type & logidx_effector;
                for radius_index=1:numel(eye_fix_radii)
                    idx_rad=[saccades.fix_rad]==eye_fix_radii(radius_index);
                    valid_fix_rad_errors(idx,radius_index)=sum(idx_rad & logidx_combined & [binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ)~=0;
                end
                for radius_index=1:numel(eye_tar_radii)
                    idx_rad=[saccades.tar_rad]==eye_tar_radii(radius_index);
                    valid_tar_rad_errors(idx,radius_index)=sum(idx_rad & logidx_combined & [binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ)~=0;
                end
                
            end
            
            eye_fix_colors=autumn(numel(eye_fix_radii));
            eye_tar_colors=autumn(numel(eye_tar_radii));
            ahd_tar_colors=winter(numel(ahd_tar_radii));
            lhd_tar_colors=winter(numel(rhd_tar_radii));
            rhd_tar_colors=summer(numel(lhd_tar_radii));
            
            plot_title='Summary errors ';
            summary_errors_figure=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
            subplot(n_rows,5,1)
            hold on
            area(sessionidx_totals,total_hits(valid_totals)+total_errors(valid_totals)+total_not_initiated(valid_totals),'FaceColor','r');
            area(sessionidx_totals,total_hits(valid_totals)+total_errors(valid_totals),'FaceColor','b');
            area(sessionidx_totals,total_hits(valid_totals),'FaceColor','g');
            set(gca,'xtick',[1:numel(sessionidx_totals)])
            legend({'Total','Initiated','Hits'},'Location','Best');
            title('Total Trials');
            ylabel('Amount of trials');
            xlabel('Session');
            
            
            subplot(n_rows,5,2)
            hold on
            
            area(sessionidx_errors,total_inprecise(valid_errors)+total_breaks(valid_errors)+total_nogo(valid_errors)+total_sensor_errors(valid_errors)+total_moved(valid_errors),'FaceColor','r');
            area(sessionidx_errors,total_inprecise(valid_errors)+total_breaks(valid_errors)+total_nogo(valid_errors)+total_sensor_errors(valid_errors),'FaceColor','m');
            area(sessionidx_errors,total_inprecise(valid_errors)+total_breaks(valid_errors)+total_nogo(valid_errors),'FaceColor','c');
            area(sessionidx_errors,total_inprecise(valid_errors)+total_breaks(valid_errors),'FaceColor','b');
            area(sessionidx_errors,total_inprecise(valid_errors),'FaceColor','g');
            
            plot(sessionidx_errors,total_errorrate(valid_errors),'k');
            %legend({'Inprecise','+Fix Breaks','+Doesnt go','+Sensor errors','+Moving'},'Location','Best');
            legend({'Moving','Sensor errors','Doesnt go','Fixation breaks','Inprecise'},'Location','Best');
            title('Errors');
            ylabel('Percent');
            xlabel('Session');
            
            
            subplot(n_rows,5,3)
            hold on
            plot(sessionidx_errors,no_move_eye(valid_errors),'color',[1 0 0]);
            plot(sessionidx_errors,nottotarget_eye(valid_errors),'color',[0.5 0 0]);
            if plothandsseperately
                plot(sessionidx_errors,no_move_lhd(valid_errors),'color',[0 0 1]);
                plot(sessionidx_errors,no_move_rhd(valid_errors),'color',[0 1 0]);
                plot(sessionidx_errors,nottotarget_lhd(valid_errors),'color',[0 0 0.5]);
                plot(sessionidx_errors,nottotarget_rhd(valid_errors),'color',[0 0.5 0]);
                legend({'Eye stay','Eye nottotarget','L hnd stay','L hnd nottotarget','R hnd stay','R hnd nottotarget'},'Location','Best');
            else
                plot(sessionidx_errors,no_move_ahd(valid_errors),'color',[0 1 1]);
                plot(sessionidx_errors,nottotarget_ahd(valid_errors),'color',[0 0.5 0.5]);
                legend({'Eye stay','Eye nottotarget','Hnd stay','Hnd nottotarget'},'Location','Best');
            end
            title('Target response errors');
            ylabel('Percent');
            xlabel('Session');
            
            subplot(n_rows,5,4)
            hold on
            legend_eye={};
            for radius_index=1:numel(eye_fix_radii)
                idx_rad=[saccades.fix_rad]==eye_fix_radii(radius_index);
                plot(sessionidx(valid_fix_rad_errors(:,radius_index)),fixation_breaks_fix_eye(valid_fix_rad_errors(:,radius_index),radius_index),'color',eye_fix_colors(radius_index,:))
                legend_eye=[legend_eye,{['Eye rad = ',num2str(double(eye_fix_radii(radius_index)))]}];
            end
            if plothandsseperately
                plot(sessionidx_errors,fixation_breaks_fix_lhd(valid_errors),'b');
                plot(sessionidx_errors,fixation_breaks_fix_rhd(valid_errors),'g');
                legend([legend_eye,{'L hand', 'R hand'}],'Location','Best');
            else
                plot(sessionidx_errors,fixation_breaks_fix_ahd(valid_errors),'c');
                legend([legend_eye,{'Hand'}],'Location','Best');
            end
            title('Fixation breaks in FIX');
            ylabel('% of errors / radius and effectors');
            xlabel('Session');
            
            subplot(n_rows,5,5)
            hold on
            legend_eye={};
            for radius_index=1:numel(eye_fix_radii)
                idx_rad=[saccades.fix_rad]==eye_fix_radii(radius_index);
                %valid_fix_rad_errors=sum(idx_rad & logidx_combined & [binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ)~=0;
                plot(sessionidx(valid_fix_rad_errors(:,radius_index)),fixation_breaks_cue_eye(valid_fix_rad_errors(:,radius_index),radius_index)+...
                    fixation_breaks_mem_eye(valid_fix_rad_errors(:,radius_index),radius_index)+fixation_breaks_del_eye(valid_fix_rad_errors(:,radius_index),radius_index),...
                    'color',eye_fix_colors(radius_index,:));
                legend_eye=[legend_eye,{['Eye rad = ',num2str(double(eye_fix_radii(radius_index)))]}];
            end
            if plothandsseperately
                plot(sessionidx_errors,fixation_breaks_cue_lhd(valid_errors)+fixation_breaks_mem_lhd(valid_errors)+fixation_breaks_del_lhd(valid_errors),'b');
                plot(sessionidx_errors,fixation_breaks_cue_rhd(valid_errors)+fixation_breaks_mem_rhd(valid_errors)+fixation_breaks_del_rhd(valid_errors),'g');
                legend([legend_eye,{'L hand', 'R hand'}],'Location','Best');
            else
                plot(sessionidx_errors,fixation_breaks_cue_ahd(valid_errors)+fixation_breaks_mem_ahd(valid_errors)+fixation_breaks_del_ahd(valid_errors),'c');
                legend([legend_eye,{'Hand'}],'Location','Best');
            end
            title('Fixation breaks CUE/MEM/DEL');
            ylabel('% of errors / radius and effectors');
            xlabel('Session');
            
            subplot(n_rows,5,6)
            hold on
            legend_eye={};
            for radius_index=1:numel(eye_tar_radii)
                idx_rad=[saccades.tar_rad]==eye_tar_radii(radius_index);
                plot(sessionidx(valid_tar_rad_errors(:,radius_index)),fixation_breaks_tiv_eye(valid_tar_rad_errors(:,radius_index),radius_index)+...
                    fixation_breaks_tar_eye(valid_tar_rad_errors(:,radius_index),radius_index),'color',eye_tar_colors(radius_index,:));
                legend_eye=[legend_eye,{['Eye rad = ',num2str(double(eye_tar_radii(radius_index)))]}];
            end
            if plothandsseperately
                plot(sessionidx_errors,fixation_breaks_tiv_lhd(valid_errors)+fixation_breaks_tar_lhd(valid_errors),'b');
                plot(sessionidx_errors,fixation_breaks_tiv_rhd(valid_errors)+fixation_breaks_tar_rhd(valid_errors),'g');
                legend([legend_eye,{'L hand', 'R hand'}],'Location','Best');
            else
                plot(sessionidx_errors,fixation_breaks_tiv_ahd(valid_errors)+fixation_breaks_tar_ahd(valid_errors),'c');
                legend([legend_eye,{'Hand'}],'Location','Best');
            end
            title('Fixation breaks TAR');
            ylabel('% of errors / radius and effectors');
            xlabel('Session');
            
            
            %         hold on
            %         for radius_index=1:numel(eye_fix_radii)
            %             %valid_rad_errors=sum(idx_rad & logidx_combined & [binary.success]==0 & [states.state_abo]~=MA_STATES.FIX_ACQ)~=0;
            %             plot(sessionidx(valid_rad_errors),fixation_breaks_cue_eye(valid_rad_errors,radius_index)+fixation_breaks_mem_eye(valid_rad_errors,radius_index)+fixation_breaks_del_eye(valid_rad_errors,radius_index))
            %         end
            %         if plothandsseperately
            %             plot(sessionidx_errors,fixation_breaks_cue_lhd(valid_errors)+fixation_breaks_mem_lhd(valid_errors)+fixation_breaks_del_lhd(valid_errors));
            %             plot(sessionidx_errors,fixation_breaks_cue_rhd(valid_errors)+fixation_breaks_mem_rhd(valid_errors)+fixation_breaks_del_rhd(valid_errors));
            %         else
            %             plot(sessionidx_errors,fixation_breaks_cue_ahd(valid_errors)+fixation_breaks_mem_ahd(valid_errors)+fixation_breaks_del_ahd(valid_errors));
            %         end
            
            if plothandsseperately
                prec_plo_idx=[7,8,9,10,12,13,14,15,17,18,19,20];
                parameters_to_plot={inprecision_ls_eye,inprecision_up_eye,inprecision_do_eye,inprecision_rs_eye,inprecision_ls_lhd,inprecision_up_lhd,inprecision_do_lhd,inprecision_rs_lhd,...
                    inprecision_ls_rhd,inprecision_up_rhd,inprecision_do_rhd,inprecision_rs_rhd};
                selected_radii={eye_tar_radii,eye_tar_radii,eye_tar_radii,eye_tar_radii,lhd_tar_radii,lhd_tar_radii,lhd_tar_radii,lhd_tar_radii,rhd_tar_radii,rhd_tar_radii,rhd_tar_radii,rhd_tar_radii};
                colors={eye_tar_colors,eye_tar_colors,eye_tar_colors,eye_tar_colors,lhd_tar_colors,lhd_tar_colors,lhd_tar_colors,lhd_tar_colors,rhd_tar_colors,rhd_tar_colors,rhd_tar_colors,rhd_tar_colors};
                titles={'Precision errors eye L','Precision errors eye U','Precision errors eye D','Precision errors eye R',...
                    'Precision errors L hand L','Precision errors L hand U','Precision errors L hand D','Precision errors L hand R',...
                    'Precision errors R hand L','Precision errors R hand U','Precision errors R hand D','Precision errors R hand R'};
                compare_eye_idx=[1,2,3,4];
            else
                prec_plo_idx=[7,8,9,10,12,13,14,15];
                parameters_to_plot={inprecision_ls_eye,inprecision_up_eye,inprecision_do_eye,inprecision_rs_eye,inprecision_ls_ahd,inprecision_up_ahd,inprecision_do_ahd,inprecision_rs_ahd};
                selected_radii={eye_tar_radii,eye_tar_radii,eye_tar_radii,eye_tar_radii,ahd_tar_radii,ahd_tar_radii,ahd_tar_radii,ahd_tar_radii};
                colors={eye_tar_colors,eye_tar_colors,eye_tar_colors,eye_tar_colors,ahd_tar_colors,ahd_tar_colors,ahd_tar_colors,ahd_tar_colors};
                titles={'Precision errors eye L','Precision errors eye U','Precision errors eye D','Precision errors eye R',...
                    'Precision errors hand L','Precision errors hand U','Precision errors hand D','Precision errors hand R'};
                compare_eye_idx=[1,2,3,4];
            end
            for plotidx=1:numel(prec_plo_idx)
                legend_cell={};
                subplot(n_rows,5,prec_plo_idx(plotidx))
                hold on
                for radius_index=1:numel(selected_radii{plotidx})
                    if ismember(plotidx,compare_eye_idx)
                        idx_rad=[saccades.tar_rad]==selected_radii{plotidx}(radius_index);
                    else
                        idx_rad=[reaches.tar_rad]==selected_radii{plotidx}(radius_index);
                    end
                    legend_cell=[legend_cell,{['Tar rad = ' num2str(selected_radii{plotidx}(radius_index))]}];
                    valid_idx=~isinf(parameters_to_plot{plotidx}(:,radius_index)) & ~isnan(parameters_to_plot{plotidx}(:,radius_index));
                    plot(sessionidx(valid_idx),parameters_to_plot{plotidx}(valid_idx,radius_index),'color',colors{plotidx}(radius_index,:))
                    
                end
                title(titles{plotidx});
                ylabel('% of errors / radius and effectors');
                xlabel('Session');
                legend(legend_cell,'Location','Best');
            end
            
            if plothandsseperately
                
                undershoot.bar_rh = [counts.sac_ushoot_rh_l counts.rea_ushoot_rh_l counts.sac_ushoot_rh_r counts.rea_ushoot_rh_r];
                undershoot.bar_lh = [counts.sac_ushoot_lh_l counts.rea_ushoot_lh_l counts.sac_ushoot_lh_r counts.rea_ushoot_lh_r];
                overshoot.bar_rh =  [counts.sac_oshoot_rh_l counts.rea_oshoot_rh_l counts.sac_oshoot_rh_r counts.rea_oshoot_rh_r];
                overshoot.bar_lh =  [counts.sac_oshoot_lh_l counts.rea_oshoot_lh_l counts.sac_oshoot_lh_r counts.rea_oshoot_lh_r];
                
                subplot(n_rows,5,11)
                bh_hu_rh=bar(-undershoot.bar_rh);
                ch_hu_rh=get(bh_hu_rh,'children');
                cd_hu_rh=repmat(1:numel(undershoot.bar_rh),5,1);
                cd_hu_rh=[cd_hu_rh(:);nan];
                set(ch_hu_rh,'facevertexcdata',cd_hu_rh);
                colormap([[1,0,0];[0,1,0];[1,0,0];[0,1,0]])
                set(get(bh_hu_rh(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
                
                hold on
                bh_ho_rh=bar(overshoot.bar_rh);
                ch_ho_rh=get(bh_ho_rh,'children');
                cd_ho_rh=repmat(1:numel(overshoot.bar_rh),5,1);
                cd_ho_rh=[cd_ho_rh(:);nan];
                set(ch_ho_rh,'facevertexcdata',cd_ho_rh);
                colormap([[1,0,0];[0,1,0];[1,0,0];[0,1,0]])
                set(get(bh_ho_rh(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
                
                if sum([overshoot.bar_rh undershoot.bar_rh]) > 0
                    max_dim_r = max(abs([overshoot.bar_rh undershoot.bar_rh]));
                    axis([0 5 -max_dim_r max_dim_r]);
                end
                
                ylabel('Undershoot / Overshoot', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
                set(gca,'XTick',[1 2 3 4])
                set(gca,'XTickLabel',{'Sac L' 'Rea L' 'Sac R' 'Rea R'},'FontName',P_par.FontName,'FontSize',P_par.FontSize);
                title('Right hand', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
                
                
                subplot(n_rows,5,16)
                
                bh_hu_lh=bar(-undershoot.bar_lh);
                ch_hu_lh=get(bh_hu_lh,'children');
                cd_hu_lh=repmat(1:numel(undershoot.bar_lh),5,1);
                cd_hu_lh=[cd_hu_lh(:);nan];
                set(ch_hu_lh,'facevertexcdata',cd_hu_lh);
                colormap([[1,0,0];[0,0,1];[1,0,0];[0,0,1]])
                set(get(bh_hu_lh(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
                
                hold on
                bh_ho_lh=bar(overshoot.bar_lh);
                ch_ho_lh=get(bh_ho_lh,'children');
                cd_ho_lh=repmat(1:numel(overshoot.bar_lh),5,1);
                cd_ho_lh=[cd_ho_lh(:);nan];
                set(ch_ho_lh,'facevertexcdata',cd_ho_lh);
                colormap([[1,0,0];[0,0,1];[1,0,0];[0,0,1]])
                set(get(bh_ho_lh(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
                
                if sum([overshoot.bar_lh undershoot.bar_lh]) > 0
                    max_dim_l = max(abs([overshoot.bar_lh undershoot.bar_lh]));
                    axis([0 5 -max_dim_l max_dim_l]);
                end
                
                ylabel('Undershoot / Overshoot', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
                set(gca,'XTick',[1 2 3 4])
                set(gca,'XTickLabel',{'saccades left' 'reaches left' 'saccades right' 'reaches right'},'FontName',P_par.FontName,'FontSize',P_par.FontSize);
                title('Left hand', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
                
            else
                subplot(n_rows,5,11)
                overshoot.bar  = [counts.sac_oshoot_l counts.rea_oshoot_l counts.sac_oshoot_r counts.rea_oshoot_r];
                undershoot.bar = [counts.sac_ushoot_l counts.rea_ushoot_l counts.sac_ushoot_r counts.rea_ushoot_r];
                
                bh_hu=bar(-undershoot.bar);
                ch_hu=get(bh_hu,'children');
                cd_hu=repmat(1:numel(undershoot.bar),5,1);
                cd_hu=[cd_hu(:);nan];
                set(ch_hu,'facevertexcdata',cd_hu);
                colormap([[1,0,0];[0,1,1];[1,0,0];[0,1,1]])
                set(get(bh_hu(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
                
                hold on
                bh_ho=bar(overshoot.bar);
                ch_ho=get(bh_ho,'children');
                cd_ho=repmat(1:numel(overshoot.bar),5,1);
                cd_ho=[cd_ho(:);nan];
                set(ch_ho,'facevertexcdata',cd_ho);
                colormap([[1,0,0];[0,1,1];[1,0,0];[0,1,1]])
                set(get(bh_ho(1),'BaseLine'),'LineWidth',2,'LineStyle',':')
                
                if sum([overshoot.bar undershoot.bar]) > 0
                    max_dim = max(abs([overshoot.bar undershoot.bar]));
                    axis([0 5 -max_dim max_dim]);
                end
                
                ylabel('Undershoot / Overshoot', 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
                set(gca,'XTick',[1 2 3 4])
                set(gca,'XTickLabel',{'saccades left' 'reaches left' 'saccades right' 'reaches right'},'FontName',P_par.FontName,'FontSize',P_par.FontSize);
                
            end
            print_out3 = sprintf(['Error analysis', monkey_name{:}, ', type = ', num2str(type), ', effector = ', num2str(effector), ',  sessions: ', num2str(min([rundescriptions.session])), '/', num2str(min([rundescriptions.run])), ' - ', num2str(max([rundescriptions.session])), '/', num2str(max([rundescriptions.run]))]);  %?????
            
            title_and_save(summary_errors_figure,plot_title,title_print_out,plotoptions);
            %mtit(summary_errors_figure,print_out3, 'fontsize', 12, 'color', 'xoff', 0.0, 'yoff', 0.04, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
        end
    end
    
end

if ismember(5,plotoptions.summary)
    
    plot_title='Reward modulation ';
    reward_modulation_figure=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
    
    subplot(3,4,[1 2])
    left_large_right_small_bar = bar([counts.left_choice_percentage_left_large counts.right_choice_percentage_right_small],'FaceColor','k');
    set(gca,'Xtick',1:2,'xticklabel',{'Left','Right'},'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    set(gca,'Xlim',[0,3],'ylim',[0 100],'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    ylabel('Percentage targets chosen','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    title('Left large','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    subplot(3,4,[5 6])
    left_normal_right_normal_bar = bar([counts.left_choice_percentage_left_normal counts.right_choice_percentage_right_normal],'FaceColor','k');
    set(gca,'Xtick',1:2,'xticklabel',{'Left','Right'},'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    set(gca,'Xlim',[0,3],'ylim',[0 100],'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    ylabel('Percentage targets chosen','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    title('Left equal','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    subplot(3,4,[9 10])
    left_small_right_large_bar = bar([counts.left_choice_percentage_left_small counts.right_choice_percentage_right_large],'FaceColor','k');
    set(gca,'Xtick',1:2,'xticklabel',{'Left','Right'},'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    set(gca,'Xlim',[0,3],'ylim',[0 100],'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    ylabel('Percentage targets chosen','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    title('Left small','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    
    
    subplot(3,4,3)
    left_large_right_small_bar = bar([counts.left_choice_percentage_left_large_LA counts.right_choice_percentage_right_small_LA],'FaceColor','b');
    set(gca,'Xtick',1:2,'xticklabel',{'Left','Right'},'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    set(gca,'Xlim',[0,3],'ylim',[0 100],'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    ylabel('Percentage targets chosen','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    title('Left large, LH','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    subplot(3,4,7)
    left_normal_right_normal_bar = bar([counts.left_choice_percentage_left_normal_LA counts.right_choice_percentage_right_normal_LA],'FaceColor','b');
    set(gca,'Xtick',1:2,'xticklabel',{'Left','Right'},'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    set(gca,'Xlim',[0,3],'ylim',[0 100],'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    ylabel('Percentage targets chosen','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    title('Left equal, LH','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    subplot(3,4,11)
    left_small_right_large_bar = bar([counts.left_choice_percentage_left_small_LA counts.right_choice_percentage_right_large_LA],'FaceColor','b');
    set(gca,'Xtick',1:2,'xticklabel',{'Left','Right'},'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    set(gca,'Xlim',[0,3],'ylim',[0 100],'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    ylabel('Percentage targets chosen','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    title('Left small, LH','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    
    subplot(3,4,4)
    left_large_right_small_bar = bar([counts.left_choice_percentage_left_large_RA counts.right_choice_percentage_right_small_RA],'FaceColor','g');
    set(gca,'Xtick',1:2,'xticklabel',{'Left','Right'},'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    set(gca,'Xlim',[0,3],'ylim',[0 100],'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    ylabel('Percentage targets chosen','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    title('Left large, RH','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    subplot(3,4,8)
    left_normal_right_normal_bar = bar([counts.left_choice_percentage_left_normal_RA counts.right_choice_percentage_right_normal_RA],'FaceColor','g');
    set(gca,'Xtick',1:2,'xticklabel',{'Left','Right'},'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    set(gca,'Xlim',[0,3],'ylim',[0 100],'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    ylabel('Percentage targets chosen','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    title('Left equal, RH','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    subplot(3,4,12)
    left_small_right_large_bar = bar([counts.left_choice_percentage_left_small_RA counts.right_choice_percentage_right_large_RA],'FaceColor','g');
    set(gca,'Xtick',1:2,'xticklabel',{'Left','Right'},'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    set(gca,'Xlim',[0,3],'ylim',[0 100],'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    ylabel('Percentage targets chosen','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    title('Left small, RH','FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
    
    
    title_and_save(reward_modulation_figure,plot_title,title_print_out,plotoptions);
    %mtit(summary_errors_figure,title_print_out, 'fontsize', 12, 'color', 'xoff', 0.0, 'yoff', 0.04, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
end

OSt = MA_Postprocessing(out);
tasktypeeffector=mode([out.task.effector]);
dyn_win=5;
temp= round([OSt.TarSel_SR{1,:}]*100);
temp(isnan(temp))=0; % for NaN vlaues I put 0
[sorted_SR, sorted_SR_idx] = sort(temp);

if ismember(6,plotoptions.summary)
    % figure 6: success and selection of each target, error table
    plot_title='targetwise errors ';
    targetwise_errors_figure=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
    
    %scatter(real(OSt.unq_tarpos(IX)), imag(OSt.unq_tarpos(IX)), 1000, jet(length(imag(OSt.unq_tarpos(IX)))),'o', 'LineWidth',4)
    subplot(5,4,[5,6,9,10,13,14]);
    [indexed, N_uniquedata, N_data]= DAG_unique_indexing(sorted_SR');
    cmap = colormap(jet); %  %cmap=cmap([min max],:); % set your range here
    COL=cmap(round(size(cmap,1) - ((size(cmap,1)-1)*(100-sorted_SR)/100)), :);
    %rows = uint16(linspace(1, N_uniquedata, size(cmap,1))) ;
    %cmap = cmap(rows, :);
    %sorted_SR(sorted_SR==0)=1; %%% just for choosing coldest color
    %col= cmap(sorted_SR,:);  %cmap(1:round(size(cmap,1)/N_uniquedata):end ,:);% col= jet(N_uniquedata);
    %COL=col(indexed,:);
    %COL=cmap(indexed,:)
    ctr=0;
    for pos=sorted_SR_idx % 1:numel(sorted_SR_idx)
        ctr=ctr+1;
        hold on; plot(real(OSt.unq_tarpos(pos)),imag(OSt.unq_tarpos(pos)), 'MarkerEdgeColor', 'k', 'MarkerFaceColor', COL(ctr,:),'MarkerSize',30, 'Marker', 'o','LineWidth',1)
        text(real(OSt.unq_tarpos(pos))-1,imag(OSt.unq_tarpos(pos))+0.5,[num2str(round(OSt.TarSel_SR{1,pos}*100)) '%'],'fontsize',6)
        text(real(OSt.unq_tarpos(pos))-1,imag(OSt.unq_tarpos(pos)),[num2str(round(OSt.TarSel_mRT_cell{1,pos}*1000)) 'ms'],'fontsize',6)
        %text(real(OSt.unq_tarpos(pos))-1,imag(OSt.unq_tarpos(pos))-0.6,[num2str(OSt.TarSel_Nt{1,pos}(1)) '#'],'fontsize',6)
        text(real(OSt.unq_tarpos(pos))-1,imag(OSt.unq_tarpos(pos))-0.5, OSt.TarSel_Nt_str{1, pos},'fontsize',6)
    end
    xlim([min(real(OSt.unq_tarpos))-10 max(real(OSt.unq_tarpos))+10]);
    ylim([min(imag(OSt.unq_tarpos))-10 max(imag(OSt.unq_tarpos))+10]);
    
    %     if ChoiceTrials
    %         title(sprintf('%s\n%s (choice)    demandedHand: %s', Maintitle,  num2str(unique(OSt.demandedHand))),'fontsize',12, 'fontweight', 'bold')
    %     else
    %         title(sprintf('%s\n%s (inst)      demandedHand: %s', Maintitle,  num2str(unique(OSt.demandedHand))),'fontsize',12, 'fontweight', 'bold')
    %     end
    title('Successrate per target','fontsize',12, 'fontweight', 'bold')
    
    Tar_X_unq= unique(real(OSt.unq_tarpos));
    Tar_Y_unq= unique(imag(OSt.unq_tarpos));
    
    graceTime_eye= [out.timing(1).grace_time_eye];
    graceTime_hnd= [out.timing(1).grace_time_hand];
    text(-25, max(Tar_Y_unq)+5, ['N(cor/tot):   '  OSt.TarSel_N_lft_rgt{1}]);
    text(10,max(Tar_Y_unq)+5,  OSt.TarSel_N_lft_rgt{2});
    
    ylabel('Target position Y','fontsize',12, 'fontweight', 'bold');
    xlabel('Target position X','fontsize',12, 'fontweight', 'bold')
    colorbar;
    set(gca, 'CLim', [0 100]);
    box on
    %         caxis([0 100])
    %         colorbar('YTick',sorted_SR)
    %         h = colorbar;    set(h, 'ylim', [100 150])
    %legend('targets', 'lowest perf')
    %         margpos= get(gca, 'Position')
    %         margpos(1) = 0.055; margpos(3) = 0.40;
    %         set(gca, 'Position', margpos)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
    subplot(5,4,[15,16,19,20])
    tmp_col_norm= size(cmap, 1) / size(OSt.ErrorAnalysis.Abort_code_shortsummary, 1);
    PiChart_Error_COL= cmap(round([1:size(OSt.ErrorAnalysis.Abort_code_shortsummary, 1)] .* tmp_col_norm), :);
    for ll=1:length( OSt.mean_error_byN)
        hold on;
        h= bar(ll, OSt.mean_error_byN(ll) );
        set(h, 'facecolor', PiChart_Error_COL( OSt.taskEffector_errorINX(ll), :))
    end
    % h= bar( OSt.mean_error_byN);
    %set(h, 'facecolor', [0.4 0.5 0.6])
    text([1:size( OSt.mean_error_byN,1)]'-0.4, 8+ OSt.mean_error_byN, num2str(nansum( OSt.N_abortcodes(:,:),2)))
    text(12, 80, ['Tot Suc rate: ' num2str(round( OSt.perc_abortcodes(1)*100)) ' %'], 'fontweight','b','fontsize',12)
    if graceTime_hnd>0 ; text(12, 88, ['graceTime (ms): ' num2str(graceTime_hnd*1000)]); end
    set(gca,'XTickLabel','')
    t = text([1:size( OSt.mean_error_byN,1)]-0.3, zeros(1,size( OSt.mean_error_byN,1)), OSt.AbortcodesList(1:end), 'fontweight','b','fontsize',8);
    set(t,'HorizontalAlignment','right','VerticalAlignment','top', ...
        'Rotation',45);
    xlim([0 size( OSt.mean_error_byN,1)+1]); ylim([0 100]); set(gca,'YGrid','on')
    set(gca,'YGrid','on')
    ylabel('mean error percentage (cal by NTrials)','fontsize',12,'fontweight','b')
    box on
    
    %%  loop pi chart for error of eac target
    subplot(5,4,[3,4,7,8,11,12])
    
    for pos=sorted_SR_idx
        hold on;
        ErrorPiChart_h= DAG_pie_chart(cell2mat( OSt.ErrorAnalysis.TarSel{1,pos}.Abort_code_shortsummary(:,5)), 2.5, PiChart_Error_COL, [real(OSt.unq_tarpos(pos)),imag(OSt.unq_tarpos(pos))], 1.3); axis on;
        PiChartLegend= OSt.ErrorAnalysis.TarSel{1,1}.Abort_code_shortsummary( cell2mat(OSt.ErrorAnalysis.TarSel{1,1}.Abort_code_shortsummary(:,5))>0,4);
        % legend(ErrorPiChart_h([1,23,45]), PiChartLegend)
        %legend(ErrorPiChart_h(find(cell2mat(OSt.ErrorAnalysis.TarSel{u,1}.Abort_code_shortsummary(:,5))>0).*2-1), PiChartLegend)
        xlim([min(real(OSt.unq_tarpos))-10 max(real(OSt.unq_tarpos))+10]);
        ylim([min(imag(OSt.unq_tarpos))-10 max(imag(OSt.unq_tarpos))+10]);
    end
    ylabel('Target position Y','fontsize',12, 'fontweight', 'bold');
    xlabel('Target position X','fontsize',12, 'fontweight', 'bold');
    title('percentage of error types for each target','fontsize',10, 'fontweight', 'bold')
    margpos= get(gca, 'Position');
    margpos(1) = 0.55; margpos(3) = 0.42;
    set(gca, 'Position', margpos)
    box on
    title_and_save(targetwise_errors_figure,plot_title,title_print_out,plotoptions);
    % mtit(targetwise_errors_figure,title_print_out, 'fontsize', 12, 'color', 'xoff', 0.0, 'yoff', 0.04, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    
    
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%
end

if ismember(7,plotoptions.summary)
    % figure 7: RT plots
    plot_title=['RT_distribution '];
    RT_distribution_figure=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
    
    subplot(5,7,[1]);
    Data=  OSt.Tar_Side_Selection_perc; % [ OSt.Tar_Side_Selection_perc(2,:).* OSt.Tar_Side_Selection_perc(1,:)]/100
    h=bar(Data(1,:));
    set(h, 'facecolor', [0.4 0.2 0.3])
    hold on;
    h=bar([Data(2,:).*Data(1,:)]/100);
    set(h, 'facecolor', [0.8 0.4 0.6])
    text(1, 70, sprintf('%0.0f \n%0.0f ', Data(1,1), Data(2,1)), 'fontsize',8)
    text(2, 70, sprintf('%0.0f %%\n%0.0f %%', Data(1,2), Data(2,2)), 'fontsize',8)
    title(' side selection ', 'fontsize',10,'fontweight','b')
    set(gca,'XTick', [1:2]);
    set(gca,'XTickLabel', {'left', 'right'}, 'fontsize',9,'fontweight','b');
    ylim([0 100]);          ylabel('percentage %')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    subplot(5,7,[8, 9]);
    bins= [-20:40:500];
    hist1=hist( OSt.Effector_RT_toL_toR{1,1}*1000, bins);
    plot(bins,hist1/sum(hist1), 'Color', [0 0.6 0.8], 'MarkerSize', 3, 'LineWidth',2)
    vline(nanmean( OSt.Effector_RT_toL_toR{1,1}*1000,2), 'b')
    hist2=hist( OSt.Effector_RT_toL_toR{1,2}*1000, bins);
    hold on; plot(bins, hist2/sum(hist2),'Color', [0.1 1 0.4], 'MarkerSize', 3, 'LineWidth',2)
    vline(nanmean( OSt.Effector_RT_toL_toR{1,2}*1000,2), 'g')
    xlim([min(bins) max(bins)]);
    set(gca,'XTick', [0:100: max(bins)]); xlabel('time (ms)', 'fontsize',9,'fontweight','b')
    title([' RT to L or R side, N:' num2str(size( OSt.Effector_RT_toL_toR{1,1},2)) ' - ' num2str(size( OSt.Effector_RT_toL_toR{1,2},2))], 'fontsize',9,'fontweight','b')
    counts = hist([ OSt.Effector_RT_toL_toR{1,1}  OSt.Effector_RT_toL_toR{1,2}]*1000, bins);
    counts=counts/sum(counts);
    text(0 , max(counts)+0.1, 'left', 'Color', [0 0.6 0.8], 'fontsize',8);
    text(80, max(counts)+0.1, 'right', 'Color', [0.1 1 0.4], 'fontsize',8);
    ylim([0 1]);   ylabel('percentage %');         set(gca, 'fontsize',8,'fontweight','b');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    if ismember(tasktypeeffector, [1,4,6]) % reach tasks
        subplot(5,7,[3,4]);
        Data=  OSt.Tar_Hand_Side_Selection_perc; % [ OSt.Tar_Side_Selection_perc(2,:).* OSt.Tar_Side_Selection_perc(1,:)]/100
        h=bar(Data(1,:));
        set(h, 'facecolor', [0.4 0.2 0.3])
        hold on;
        h=bar([Data(2,:).*Data(1,:)]/100);
        set(h, 'facecolor', [0.8 0.4 0.6])
        %text(1, 70, sprintf('%0.0f\n%0.0f', Data(1,1), Data(2,1)))
        %text(2, 70, sprintf('%0.0f\n%0.0f', Data(1,2), Data(2,2)))
        %text(3, 70, sprintf('%0.0f\n%0.0f', Data(1,3), Data(2,3)))
        %text(4, 70, sprintf('%0.0f\n%0.0f', Data(1,4), Data(2,4)))
        %title(' side selection ', 'fontsize',9,'fontweight','b')
        set(gca,'XTick', [1:4]); set(gca,'XTickLabel', {'LHLT', 'RHLT','LHRT', 'RHRT'}, 'fontsize',9,'fontweight','b');
        ylim([0 1]);  ylabel('percentage %')
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        subplot(5,7,[10, 11])
        counts = hist([ OSt.Effector_RT_toL_toR{1,3}  OSt.Effector_RT_toL_toR{1,4}]*1000, bins);
        counts=counts/sum(counts);
        plot(bins, counts, 'Color', [0 0.6 0.8], 'MarkerSize', 3, 'LineWidth',2)
        counts = hist([ OSt.Effector_RT_toL_toR{1,5}  OSt.Effector_RT_toL_toR{1,6}]*1000, bins);
        counts=counts/sum(counts);
        hold on; plot(bins, counts,'Color', [0.1 1 0.4], 'MarkerSize', 3, 'LineWidth',2)
        vline(nanmean([ OSt.Effector_RT_toL_toR{1,3}  OSt.Effector_RT_toL_toR{1,4}]*1000,2), 'b')
        vline(nanmean([ OSt.Effector_RT_toL_toR{1,5}  OSt.Effector_RT_toL_toR{1,6}]*1000,2), 'g')
        xlim([min(bins) max(bins)]); set(gca,'XTick', [0:100: max(bins)]);
        title([' hand RT  , N:' num2str(size([ OSt.Effector_RT_toL_toR{1,3}  OSt.Effector_RT_toL_toR{1,4}],2)) ...
            ' - ' num2str(size([ OSt.Effector_RT_toL_toR{1,5}  OSt.Effector_RT_toL_toR{1,6}],2))], 'fontsize',9,'fontweight','b')
        text(0, max(counts)+0.1, 'left', 'Color', [0 0.6 0.8], 'fontsize',8);
        text(80, max(counts)+0.1, 'right', 'Color', [0.1 1 0.4], 'fontsize',8);
        ylim([0 1]);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        clear temp_data;
        for H_T_sp=1:3
            switch H_T_sp
                case 1; subplot_num= [15:18]; temp_data=  OSt.Effector_RT_toL_toR;     xlbl_txt='Target Reaction time (ms)';
                case 2; subplot_num= [22:25]; temp_data=  OSt.Effector_FixRT_toL_toR;  xlbl_txt='Fixation Reaction time (ms)';
                case 3; subplot_num= [29:32]; temp_data=  OSt.Effector_Fixdur_toL_toR; xlbl_txt='Fixation duration (ms)';
            end
            
            subplot(5,7,subplot_num);
            [cnt1, cnt2, cnt3, cnt4]= deal(NaN);
            for kkk=3:6
                counts = hist(temp_data{1, kkk}*1000, bins);
                counts=counts/sum(counts);
                switch kkk
                    case 3; colcol= [0 0.1 0.8]; cnt1= size(temp_data{1, kkk},2);
                    case 4; colcol= [0 0.6 0.8]; cnt2= size(temp_data{1, kkk},2);
                    case 5; colcol= [0 1 0.1];   cnt3= size(temp_data{1, kkk},2);
                    case 6; colcol= [0 0.7 0.2]; cnt4= size(temp_data{1, kkk},2);
                end
                
                hold on; plot(bins, counts, 'Color', colcol, 'LineWidth',3)
            end
            box on;
            %hold on; plot(bins, counts,'Color', [0.1 1 0.4], 'MarkerSize', 3, 'LineWidth',2)
            xlim([min(bins) max(bins)]);
            %legend(sprintf('LH LT %d', cnt1), 'LH RT', 'RH LT', 'RH RT')
            legend(sprintf('LH LT %d', cnt1), sprintf('LH RT %d', cnt2), ...
                sprintf('RH LT %d', cnt3), sprintf('RH RT %d', cnt4), 'Location', 'Best')
            legend('boxoff')
            xlabel(xlbl_txt, 'fontsize',9,'fontweight','b'); ylabel('count')
            ylim([0 1])
            set(gca, 'fontsize',8,'fontweight','b');
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if ismember(tasktypeeffector, [1,2,4])
        sp_movavrg_Loop=4; idx_to_refer=[3 4 5 6];
    else
        sp_movavrg_Loop=2; idx_to_refer=[1 2];
    end
    
    for sp_movavrg=1:sp_movavrg_Loop
        switch sp_movavrg
            case 1; subplot_num= [ 12:14];
                % 3:LTLH   4:RTLH   5:LTRH   6:RTRH
                if sp_movavrg_Loop==4; ylbl_txt='LH LT'; colcol= [0 0.1 0.8];
                else
                    ylbl_txt='RT left side'; colcol= [0 0.6 0.8];
                end
                
            case 2; subplot_num= [19:21];
                if sp_movavrg_Loop==4; ylbl_txt='LH RT'; colcol= [0 0.6 0.8];
                else
                    ylbl_txt='RT right side'; colcol= [0.1 1 0.4];
                end
                
            case 3; subplot_num= [26:28];
                ylbl_txt='RH LT'; colcol= [0 1 0.1];
                
            case 4; subplot_num= [33:35];
                ylbl_txt='RH RT'; colcol= [0 0.7 0.2];
                
        end
        
        
        dat= OSt.Eff_RT_dyn{1, idx_to_refer(sp_movavrg)}*1000;
        dat= [nan(ceil(dyn_win/2),1); dat; nan(floor(dyn_win/2),1)]; %% floor/ceil might not be correct...
        
        if any(~isnan(dat)) && size(dat,1)-dyn_win>2
            subplot(5,7, subplot_num);
            plot( OSt.Effector_RT_toL_toR{1,idx_to_refer(sp_movavrg)}'*1000, 'o-k', 'LineWidth',1, 'MarkerSize',2)
            SlopeTest=Ourexpregr(1:size(dat,1),dat',0,1); %OSt.Eff_RT_dyn{u,2}
            FIG= SlopeTest.figure;
            hold on; plot(1:size(dat,1),dat', '-o', 'Color',colcol, 'MarkerSize',1, 'LineWidth',2.5)
            hold on; plot(FIG.xtmp, FIG.ystar, FIG.xtmp, FIG.cir, 'r:', FIG.xtmp, FIG.cir2, 'm:');
            
            if SlopeTest.slopetest.P<0.05  %SlopeTest.slopetest.t > SlopeTest.slopetest.cv  % SlopeTest.slopetest.p<0.05
                text(dyn_win/2+2,max(dat)+30, sprintf('slope= %.5f   Pears=%.3f  P=%.5f', SlopeTest.slope.value, SlopeTest.pearson.value, SlopeTest.slopetest.P ), 'Color' , 'r', 'FontSize', 8);
            else
                text(dyn_win/2+2,max(dat)+30 , sprintf('slope = 0   Pears=%.3f', SlopeTest.pearson.value), 'Color' , 'b', 'FontSize', 8);
            end
            xlim([0 size( OSt.Effector_RT_toL_toR{1,idx_to_refer(sp_movavrg)},2)])
            ylim([min(dat)-150 max(dat)+150])
            box on;
            ylabel(ylbl_txt, 'fontsize',10, 'fontweight', 'bold','fontsize',10, 'fontweight', 'bold', 'Color', colcol)
        end
        
        margpos= get(gca, 'Position');
        margpos(1) = 0.62; margpos(3) = 0.35;
        set(gca, 'Position', margpos)
    end
    
    title_and_save(RT_distribution_figure,plot_title,title_print_out,plotoptions);
    %mtit(RT_distribution_figure,title_print_out, 'fontsize', 12, 'color', 'xoff', 0.0, 'yoff', 0.04, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
end

if ismember(8,plotoptions.summary)
    %% Rt distribution for each target colormap shows the Success rate (hottest color= highest SR)
    plot_title='RT_distribution per target ';
    RT_distribution_per_target_figure=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
    
    bins= [-20:40:500];
    sp_N_x= size(unique(real(OSt.unq_tarpos)),2);
    sp_N_y= size(unique(imag(OSt.unq_tarpos)),2);
    ctr=0;
    x_y_sp=[];
    
    for ysp= fliplr(unique(imag(OSt.unq_tarpos)))
        for xsp= unique(real(OSt.unq_tarpos))
            ctr=ctr+1;
            x_y_sp= [x_y_sp; xsp ysp ctr];
        end
    end
    ctr=0; sp=[];
    for pos= sorted_SR_idx % 1:numel(sorted_SR_idx)
        
        sp = x_y_sp(x_y_sp(:,1)==real(OSt.unq_tarpos(pos)) &   x_y_sp(:,2)==imag(OSt.unq_tarpos(pos)), 3);
        subplot(sp_N_y, sp_N_x, sp);
        title(['RT distribution for target ' num2str(pos)]);
        switch tasktypeeffector
            case {0}
                
                ctr=ctr+1;
                %bins= [-20:25:500];
                counts = hist(OSt.TarSel_RT_cell{1,pos}*1000, bins);
                counts=counts/sum(counts);
                plot(bins, counts', 'Color', COL(ctr,:), 'LineWidth',2)
                ylim([0 1])
                
                xlim([min(bins) max(bins)]);
                set(gca,'XTick', [0:100: max(bins)]);
                set(gca,'XTickLabel', num2str([0:100: max(bins)]'/100))
                set(gca,'fontsize',8);   set(gca, 'TickDir', 'Out');
                subplot(sp_N_y, sp_N_x, 1);   colorbar;   set(gca, 'CLim', [0 100]);  %axis off;
            case {1,3,4,6}
                
                counts = hist(OSt.TarSel_RT_hand_target.leftHand{pos}*1000, bins);
                counts=counts/sum(counts);
                hold on; plot(bins, counts,'-b', 'LineWidth',2)
                counts = hist(OSt.TarSel_RT_hand_target.rightHand{pos}*1000, bins);
                counts=counts/sum(counts);
                hold on; plot(bins, counts,'-g', 'LineWidth',2)
                box on;
                
                ylim([0 1]); XXX=0.8;
                text(0,   XXX, sprintf('Nt: %d\n SR: %0.0f', ...
                    OSt.TarSel_RT_hand_target.leftHand_Nt{pos}(2),  OSt.TarSel_RT_hand_target.leftHand_SR{pos}*100), 'fontsize',8)
                text(400, XXX, sprintf(' %d\n  %0.0f', ...
                    OSt.TarSel_RT_hand_target.rightHand_Nt{pos}(2), OSt.TarSel_RT_hand_target.rightHand_SR{pos}*100), 'fontsize',8)
                xlim([min(bins) max(bins)]);
                set(gca,'XTick', [0:100: max(bins)]);
                set(gca,'XTickLabel', num2str([0:100: max(bins)]'/100))
                set(gca,'fontsize',8);   set(gca, 'TickDir', 'Out');
        end
        
    end
    %subplot(sp_N_y, sp_N_x, 1); title('RT distribution for each target');
    
    title_and_save(RT_distribution_per_target_figure,plot_title,title_print_out,plotoptions);
    %mtit(RT_distribution_per_target_figure,title_print_out, 'fontsize', 12, 'color', 'xoff', 0.0, 'yoff', 0.04, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    
    %%
end

if ismember(9,plotoptions.summary)
    plot_title='running averages ';
    running_averages_figure=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
    
    for jj=1:9
        
        switch jj
            case 1; tit= 'all trials';
            case 2; tit= 'left target';
            case 3; tit= 'right target';
            case 4; tit= 'left hand';
            case 5; tit= 'right hand';
            case 6; tit= 'Left Hand Left Target';
            case 7; tit= 'Left Hand Right Target';
            case 8; tit= 'Right Hand Left Target';
            case 9; tit= 'Right Hand Right Target';
        end
        
        if ~isempty(OSt.SuccRate_movingavg{1,jj})
            xxx= OSt.SuccRate_movingavg{1,jj};
            
            [p,S] = polyfit(1:size(xxx,1), xxx', 1);
            yyy= polyval(p,1:size(xxx,1));
            
            subplot(3,3,jj)
            plot(1: size(xxx,1), xxx, 'o-r')
            hold on;
            plot(1: size(xxx,1), yyy, '-.r','LineWidth',3)
            axis square
            xlim([0 length(xxx)])
            ylim([0 1])
            title(tit, 'FontWeight', 'Bold', 'FontSize', 12)
            ylabel('running average success rate (10 tr)', 'FontWeight', 'Bold', 'FontSize', 10)
            xlabel('10 trials window',  'FontWeight', 'Bold', 'FontSize', 10)
        end
        % [R,P] = corrcoef([1:10 ; 0 1 2 3 0 1 4 3 2 5]')
    end
    
    title_and_save(running_averages_figure,plot_title,title_print_out,plotoptions);
    %mtit(running_averages_figure,title_print_out, 'fontsize', 12, 'color', 'xoff', 0.0, 'yoff', 0.04, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
end

if ismember(10,plotoptions.summary)
    
    plot_title='errors over time ';
    errors_per_time_figure=figure('Name', [plot_title title_print_out],'units','normalized','outerposition',[0 0 1 1]);
    
    XXX= double(cell2mat(OSt.ErrorAnalysis.Abort_code_fullsummary(:,7)')');
    XXX= XXX([1 3 4 6 7 9:16 18:33 ], :);
    X= 1:size(XXX,2);
    
    for jj=1:size(XXX,1)
        hold on;
        
        tmp= XXX(jj,:);
        tmp1= X(tmp==0);
        tmp2= X(tmp==1);
        
        scatter(tmp1, ones(1,length(tmp1))*jj, 5,   XXX(jj,tmp1), 'filled', 'MarkerFaceColor', [1 1 1])
        hold on
        scatter(tmp2, ones(1,length(tmp2))*jj, 5,   XXX(jj,tmp2), 'filled', 'MarkerFaceColor', [0 0 0])
        
    end
    
    set(gca,'YTick',[1:33])
    set(gca,'YTickLabel', OSt.ErrorAnalysis.Abort_code_fullsummary([1 3 4 6 7 9:16 18:33 ],4))
    xlabel('trials','fontsize',12, 'fontweight', 'bold')
    box on
    title('Errors over time','fontsize',12, 'fontweight', 'bold')
    
    title_and_save(errors_per_time_figure,plot_title,title_print_out,plotoptions);
    %mtit(errors_per_time_figure,title_print_out, 'fontsize', 12, 'color', 'xoff', 0.0, 'yoff', 0.04, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
    
end

end

function OSt = MA_Postprocessing(out)

ChoiceTrials= any([out.binary.choice]);
tasktypeeffector=mode([out.task.effector]);
dyn_win=5;
%% loop to calculate interesting variables
% save timings
OSt.outcomp_timing= fieldnames(out.timing);
OSt.rewardvalues= [[out.task.tar_rew_low]; [out.task.tar_rew_high]];

for kk=1:size(OSt.outcomp_timing,1)
    OSt.outcomp_timing{kk,2}= eval(  ['[out.timing(:,1).' OSt.outcomp_timing{kk,1} ']'] );
end
OSt.idx_Choice= [out.binary(:).choice];  % sum(OSt.idx_Choice)

if isnan(ChoiceTrials); ChoiceTrials=0; end
if ~isnan(ChoiceTrials);
    if ChoiceTrials; OSt.idx_Choice= OSt.idx_Choice;
    else OSt.idx_Choice= ~OSt.idx_Choice;
    end
end

OSt.idx_Succ=[out.binary(:).success]; % sum(OSt.idx_Succ)

switch tasktypeeffector
    case {0,3}
        effector='saccades';
        OSt.Effector_FixRT=    nan(size(out.(effector)))'; % double([out.saccades(:).ini_fix]);
        OSt.Effector_Fixdur=   nan(size(out.(effector)))'; % double([out.saccades(:).dur_fix]);
        
    case {1,4}
        effector='reaches';
        OSt.Effector_FixRT=    double([out.reaches.ini_fix]);
        OSt.Effector_Fixdur=   double([out.reaches.dur_fix]);
        
    case 6
        effector='reaches';
        OSt.Effector_FixRT=    double([out.reaches.ini_fix]);
        OSt.Effector_Fixdur=   double([out.reaches.dur_fix]);
        
        
end
OSt.Effector_RT_Sac6=    double([out.saccades.lat]);
OSt.Effector_dur_Sac6=   double([out.saccades.dur]);
OSt.idx_tar_left         =  [out.(effector).tar_pos] - [out.(effector).fix_pos]>0;
OSt.idx_tar_right        =  [out.(effector).tar_pos] - [out.(effector).fix_pos]<0;
OSt.Effector_RT          =  double([out.(effector).lat]);
OSt.Effector_RT(OSt.Effector_RT<0)=0;
OSt.Effector_dur         =   double([out.(effector).dur]);
%     OSt.Effector_FixRT       =   double([out.(effector).ini_fix]);
%     OSt.Effector_Fixdur      =   double([out.(effector).dur_fix]);
OSt.tar_pos              =   double([out.(effector).tar_pos]);
OSt.tar_notchosen_pos    =   double([out.(effector).nct_pos]);
OSt.Saccade_nSac         =   [out.saccades.num_sac];

%%

OSt.Reaction_Time_List{1,1}= OSt.Effector_RT;

OSt.demandedHand= [out.task(:).demanded_hand];
OSt.ReachHand= [out.task(:).reach_hand];

OSt.Hand_left=[out.binary(:).left_hand];
OSt.Hand_right=[out.binary(:).right_hand];

OSt.Reach_lat_dur= [OSt.Effector_FixRT; OSt.Effector_Fixdur; OSt.Effector_RT; OSt.Effector_dur]';

OSt.unq_tar_notchosen_pos= unique(OSt.tar_notchosen_pos);
OSt.unq_tar_notchosen_pos = OSt.unq_tar_notchosen_pos(~isnan(OSt.unq_tar_notchosen_pos));

OSt.unq_tarpos= unique(OSt.tar_pos);
OSt.unq_tarpos = OSt.unq_tarpos(~isnan(OSt.unq_tarpos));


for pos=1:size(OSt.unq_tarpos,2)
    OSt.TarSel_Nt_str{1,pos}= [num2str(sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice)) '/' num2str(sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Choice))];
    OSt.TarSel_Nt{1,pos}= [sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice), sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Choice)];
    OSt.TarSel_SR{1,pos}=  sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice)/ sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Choice);
    
    OSt.TarSel_RT_cell{1,pos}=  OSt.Effector_RT(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice);
    OSt.TarSel_dur_cell{1,pos}=  OSt.Effector_dur(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice);
    OSt.TarSel_mRT_cell{1,pos}= nanmean(OSt.Effector_RT(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice));
    OSt.TarSel_mdur_cell{1,pos}= nanmean(OSt.Effector_dur(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice));
    
    OSt.TarSel_RT_hand_target.leftHand{pos} = OSt.Effector_RT(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_left);
    OSt.TarSel_RT_hand_target.rightHand{pos}= OSt.Effector_RT(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_right);
    OSt.TarSel_RT_hand_target.leftHand_mRT{pos} =   nanmean(OSt.Effector_RT(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_left));
    OSt.TarSel_RT_hand_target.rightHand_mRT{pos}=   nanmean(OSt.Effector_RT(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_right));
    
    OSt.TarSel_RT_hand_target.leftHand_Nt{pos} = [sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_left), ...
        sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Choice & OSt.Hand_left)];
    OSt.TarSel_RT_hand_target.leftHand_SR{pos} = sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_left)/ ...
        sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Choice & OSt.Hand_left);
    
    OSt.TarSel_RT_hand_target.rightHand_Nt{pos}= [sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_right), ...
        sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Choice & OSt.Hand_right)];
    OSt.TarSel_RT_hand_target.rightHand_SR{pos}= sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_right)/ ...
        sum(OSt.tar_pos==OSt.unq_tarpos(pos) & OSt.idx_Choice & OSt.Hand_right);
    
    labels_positions{1,pos}=[sprintf('%6.2f \n %6.2f',real(OSt.unq_tarpos(pos)), imag(OSt.unq_tarpos(pos)))];
    
    XXXX.task=out.task(OSt.tar_pos==OSt.unq_tarpos(pos));
    XXXX.binary=out.binary(OSt.tar_pos==OSt.unq_tarpos(pos));
    [    OSt.ErrorAnalysis.TarSel{1,pos}.Abort_codes, ...
        OSt.ErrorAnalysis.TarSel{1,pos}.Table_Abort_code, ...
        OSt.ErrorAnalysis.TarSel{1,pos}.Abort_code_fullsummary, ...
        OSt.ErrorAnalysis.TarSel{1,pos}.Abort_code_shortsummary, ...
        OSt.ErrorAnalysis.TarSel{1,pos}.idx_Abortcode_each_trial]= MA_error_types_working(XXXX );
    
end

%%%%%%%%%%%
OSt.TarSel_N_lft_rgt= {
    [num2str(sum(OSt.idx_tar_left& OSt.idx_Succ & OSt.idx_Choice)) '/' num2str(sum(OSt.idx_tar_left& OSt.idx_Choice)) ], ...
    [num2str(sum(OSt.idx_tar_right& OSt.idx_Succ & OSt.idx_Choice)) '/' num2str(sum(OSt.idx_tar_right& OSt.idx_Choice)) ]};

OSt.Tar_Side_Selection_perc= [
    sum(OSt.idx_Choice & OSt.idx_tar_left) /sum(OSt.idx_Choice & (OSt.idx_tar_left | OSt.idx_tar_right)), ...
    sum(OSt.idx_Choice & OSt.idx_tar_right)/sum(OSt.idx_Choice & (OSt.idx_tar_left | OSt.idx_tar_right)); ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.idx_tar_left) /sum(OSt.idx_Choice & OSt.idx_tar_left) , ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.idx_tar_right) /sum(OSt.idx_Choice & OSt.idx_tar_right); ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.idx_tar_left) / sum(OSt.idx_Choice & OSt.idx_Succ & (OSt.idx_tar_left | OSt.idx_tar_right)), ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.idx_tar_right)/ sum(OSt.idx_Choice & OSt.idx_Succ & (OSt.idx_tar_left | OSt.idx_tar_right))  ]*100;

% [ OSt.Tar_Side_Selection_perc(2,:).* OSt.Tar_Side_Selection_perc(1,:)]/100
%  OSt.Tar_Side_Selection_perc:
% first row: percentage of total prefence for right and left target
% 2nd row: percentage of successful prefence for each side seperately,
% i.e, if  OSt.Tar_Side_Selection_perc(2,1)=20% means 20% of those choice trials in
% which he selected left target were successful
% 3rd row: percentage of successful preference from total successful
% right or left selected targets


OSt.Tar_Hand_Selection_perc= [
    sum(OSt.idx_Choice & OSt.Hand_left) /sum(OSt.idx_Choice & (OSt.Hand_left | OSt.Hand_right)), ...
    sum(OSt.idx_Choice & OSt.Hand_right)/sum(OSt.idx_Choice & (OSt.Hand_left | OSt.Hand_right)); ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.Hand_left)  / sum(OSt.idx_Choice & OSt.Hand_left) , ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.Hand_right) / sum(OSt.idx_Choice & OSt.Hand_right); ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.Hand_left)  / sum(OSt.idx_Choice & OSt.idx_Succ & (OSt.Hand_left | OSt.Hand_right)), ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.Hand_right) / sum(OSt.idx_Choice & OSt.idx_Succ & (OSt.Hand_left | OSt.Hand_right))  ]*100;

OSt.Tar_Hand_Side_Selection_perc= [
    sum(OSt.idx_Choice & OSt.idx_tar_left  & OSt.Hand_left) / sum(OSt.idx_Choice & (OSt.idx_tar_left | OSt.idx_tar_right)), ...
    sum(OSt.idx_Choice & OSt.idx_tar_left  & OSt.Hand_right) /sum(OSt.idx_Choice & (OSt.idx_tar_left | OSt.idx_tar_right)), ...
    sum(OSt.idx_Choice & OSt.idx_tar_right & OSt.Hand_left) / sum(OSt.idx_Choice & (OSt.idx_tar_left | OSt.idx_tar_right)), ...
    sum(OSt.idx_Choice & OSt.idx_tar_right & OSt.Hand_right) /sum(OSt.idx_Choice & (OSt.idx_tar_left | OSt.idx_tar_right)); ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.idx_tar_left  & OSt.Hand_left) / sum(OSt.idx_Choice & OSt.idx_tar_left  & OSt.Hand_left), ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.idx_tar_left  & OSt.Hand_right)/ sum(OSt.idx_Choice & OSt.idx_tar_left  & OSt.Hand_right), ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.idx_tar_right & OSt.Hand_left) / sum(OSt.idx_Choice & OSt.idx_tar_right & OSt.Hand_left), ...
    sum(OSt.idx_Choice & OSt.idx_Succ & OSt.idx_tar_right & OSt.Hand_right)/ sum(OSt.idx_Choice & OSt.idx_tar_right & OSt.Hand_right)]*100;

% [OSt.TarSel_Nt{1:12}]
min_hit_rate = min([OSt.TarSel_SR{1,:}]);
position_of_minhitrate=[OSt.TarSel_SR{1,:}]==min([OSt.TarSel_SR{1,:}]);

% RT of movemment to target
OSt.Effector_RT_toL_toR{1,1}=  double(OSt.Effector_RT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & ~isnan(OSt.Effector_RT)));
OSt.Effector_RT_toL_toR{1,2}=  double(OSt.Effector_RT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & ~isnan(OSt.Effector_RT)));
% duration of movement to target
OSt.Effector_dur_toL_toR{1,1}= double(OSt.Effector_dur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & ~isnan(OSt.Effector_dur)));
OSt.Effector_dur_toL_toR{1,2}= double(OSt.Effector_dur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & ~isnan(OSt.Effector_dur)));
% RT of movement to fixation point
OSt.Effector_FixRT_toL_toR{1,1}=  double(OSt.Effector_FixRT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & ~isnan(OSt.Effector_FixRT)));
OSt.Effector_FixRT_toL_toR{1,2}=  double(OSt.Effector_FixRT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & ~isnan(OSt.Effector_FixRT)));
% duration of movement to fixation
OSt.Effector_Fixdur_toL_toR{1,1}= double(OSt.Effector_Fixdur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & ~isnan(OSt.Effector_Fixdur)));
OSt.Effector_Fixdur_toL_toR{1,2}= double(OSt.Effector_Fixdur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & ~isnan(OSt.Effector_Fixdur)));

if ismember(tasktypeeffector, [1,2,4,6]) %tasktypeeffector{2}==1 | tasktypeeffector{2}==4
    %  OSt.Effector_RT_toL_toR
    % 1:LT  2:RT   3:LTLH   4:RTLH   5:LTRH   6:RTRH  7:LH  8:RH
    OSt.Effector_RT_toL_toR{1,3}=  double(OSt.Effector_RT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & OSt.Hand_left  & ~isnan(OSt.Effector_RT)));
    OSt.Effector_RT_toL_toR{1,4}=  double(OSt.Effector_RT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & OSt.Hand_left  & ~isnan(OSt.Effector_RT)));
    OSt.Effector_RT_toL_toR{1,5}=  double(OSt.Effector_RT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & OSt.Hand_right & ~isnan(OSt.Effector_RT)));
    OSt.Effector_RT_toL_toR{1,6}=  double(OSt.Effector_RT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & OSt.Hand_right & ~isnan(OSt.Effector_RT)));
    OSt.Effector_RT_toL_toR{1,7}=  double(OSt.Effector_RT(OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_left   & ~isnan(OSt.Effector_RT)));
    OSt.Effector_RT_toL_toR{1,8}=  double(OSt.Effector_RT(OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_right  & ~isnan(OSt.Effector_RT)));
    
    OSt.Effector_dur_toL_toR{1,3}= double(OSt.Effector_dur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & OSt.Hand_left & ~isnan(OSt.Effector_dur)));
    OSt.Effector_dur_toL_toR{1,4}= double(OSt.Effector_dur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & OSt.Hand_left & ~isnan(OSt.Effector_dur)));
    OSt.Effector_dur_toL_toR{1,5}= double(OSt.Effector_dur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & OSt.Hand_right & ~isnan(OSt.Effector_dur)));
    OSt.Effector_dur_toL_toR{1,6}= double(OSt.Effector_dur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & OSt.Hand_right & ~isnan(OSt.Effector_dur)));
    OSt.Effector_dur_toL_toR{1,7}= double(OSt.Effector_dur(OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_left   & ~isnan(OSt.Effector_dur)));
    OSt.Effector_dur_toL_toR{1,8}= double(OSt.Effector_dur(OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_right  & ~isnan(OSt.Effector_dur)));
    
    OSt.Effector_FixRT_toL_toR{1,3}=  double(OSt.Effector_FixRT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & OSt.Hand_left  & ~isnan(OSt.Effector_FixRT)));
    OSt.Effector_FixRT_toL_toR{1,4}=  double(OSt.Effector_FixRT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & OSt.Hand_left  & ~isnan(OSt.Effector_FixRT)));
    OSt.Effector_FixRT_toL_toR{1,5}=  double(OSt.Effector_FixRT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & OSt.Hand_right & ~isnan(OSt.Effector_FixRT)));
    OSt.Effector_FixRT_toL_toR{1,6}=  double(OSt.Effector_FixRT(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & OSt.Hand_right & ~isnan(OSt.Effector_FixRT)));
    OSt.Effector_FixRT_toL_toR{1,7}=  double(OSt.Effector_FixRT(OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_left   & ~isnan(OSt.Effector_FixRT)));
    OSt.Effector_FixRT_toL_toR{1,8}=  double(OSt.Effector_FixRT(OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_right  & ~isnan(OSt.Effector_FixRT)));
    
    OSt.Effector_Fixdur_toL_toR{1,3}= double(OSt.Effector_Fixdur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & OSt.Hand_left & ~isnan(OSt.Effector_Fixdur)));
    OSt.Effector_Fixdur_toL_toR{1,4}= double(OSt.Effector_Fixdur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & OSt.Hand_left & ~isnan(OSt.Effector_Fixdur)));
    OSt.Effector_Fixdur_toL_toR{1,5}= double(OSt.Effector_Fixdur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left   & OSt.Hand_right & ~isnan(OSt.Effector_Fixdur)));
    OSt.Effector_Fixdur_toL_toR{1,6}= double(OSt.Effector_Fixdur(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right  & OSt.Hand_right & ~isnan(OSt.Effector_Fixdur)));
    OSt.Effector_Fixdur_toL_toR{1,7}= double(OSt.Effector_Fixdur(OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_left   & ~isnan(OSt.Effector_Fixdur)));
    OSt.Effector_Fixdur_toL_toR{1,8}= double(OSt.Effector_Fixdur(OSt.idx_Succ & OSt.idx_Choice & OSt.Hand_right  & ~isnan(OSt.Effector_Fixdur)));
    
    dd_loop= size( OSt.Effector_dur_toL_toR,2);
else
    dd_loop= 2;
end

% RT moving average

for dd=1: dd_loop
    temp_data=  OSt.Effector_RT_toL_toR{1, dd}';
    temp_data= temp_data(~isnan(temp_data));
    OSt.Eff_RT_dyn{1, dd}= movingAverage(temp_data, dyn_win);
    
    temp_data=  OSt.Effector_dur_toL_toR{1, dd}';
    temp_data= temp_data(~isnan(temp_data));
    OSt.Eff_dur_dyn{1, dd}= movingAverage(temp_data, dyn_win);
    
    temp_data=  OSt.Effector_FixRT_toL_toR{1, dd}';
    temp_data= temp_data(~isnan(temp_data));
    OSt.Eff_FixRT_dyn{1, dd}= movingAverage(temp_data, dyn_win);
    
    temp_data=  OSt.Effector_Fixdur_toL_toR{1, dd}';
    temp_data= temp_data(~isnan(temp_data));
    OSt.Eff_Fixdur_dyn{1, dd}= movingAverage(temp_data, dyn_win);
end

% success rate moving average
correctness= double(OSt.idx_Succ)';
OSt.SuccRate_movingavg{1,1}= movingAverage(correctness, 10);
OSt.SuccRate_movingavg{1,2}= movingAverage(correctness(OSt.idx_tar_left),  10);
OSt.SuccRate_movingavg{1,3}= movingAverage(correctness(OSt.idx_tar_right), 10);
OSt.SuccRate_movingavg{1,4}= movingAverage(correctness(OSt.Hand_left),  10);
OSt.SuccRate_movingavg{1,5}= movingAverage(correctness(OSt.Hand_right), 10);

OSt.SuccRate_movingavg{1,6}= movingAverage(correctness(OSt.Hand_left & OSt.idx_tar_left) ,  10);
OSt.SuccRate_movingavg{1,7}= movingAverage(correctness(OSt.Hand_left & OSt.idx_tar_right), 10);
OSt.SuccRate_movingavg{1,8}= movingAverage(correctness(OSt.Hand_right & OSt.idx_tar_left),  10);
OSt.SuccRate_movingavg{1,9}= movingAverage(correctness(OSt.Hand_right & OSt.idx_tar_right), 10);

% num Saccades for left or right targets
OSt.Sac_nSac_toL_toR{1,1}=  OSt.Saccade_nSac(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_left);
OSt.Sac_nSac_toL_toR{1,2}= OSt.Saccade_nSac(OSt.idx_Succ & OSt.idx_Choice & OSt.idx_tar_right);


%% error analysis
[   OSt.ErrorAnalysis.Abort_codes, ...
    OSt.ErrorAnalysis.Table_Abort_code, ...
    OSt.ErrorAnalysis.Abort_code_fullsummary, ...
    OSt.ErrorAnalysis.Abort_code_shortsummary, ...
    OSt.ErrorAnalysis.idx_Abortcode_each_trial]= MA_error_types_working(out );

%% plot

AbortTable_1=[OSt.ErrorAnalysis.Abort_code_fullsummary];

switch tasktypeeffector
    case 0    % saccade
        
        OSt.taskEffector_errorINX= [1,3,4,6,7,13,21:28,32,33]; % direct and mem saccade
        
    case 1    % reach
        OSt.taskEffector_errorINX= [1,3,4,6,7,9:16, 18,19, 32,33]; % direct and mem reaches
        
    case 2    % joint sac reach
        
    case 3    % dissociated Sac
        %OSt.taskEffector_errorINX= [1,3,4,6,7,17,9,10,11,12,13,21:24, 32,33];  % direct
        OSt.taskEffector_errorINX= [1,3,4,6,7,9:17,21:28, 32,33]; % mem
    case {4,6}    % dissociated Rea
        % OSt.taskEffector_errorINX= [1,3,4,6,7,17,9,10,11,12,13,21:24, 32,33]; % direct
        OSt.taskEffector_errorINX=   [1,3,4,6,7,9:17,21:28, 32,33]; % mem
end

AbortTable_2= AbortTable_1( OSt.taskEffector_errorINX,:);
OSt.AbortcodesList= AbortTable_2(:,4);
OSt.N_abortcodes= cell2mat(AbortTable_2(:, 5:5:end));
OSt.perc_abortcodes= cell2mat(AbortTable_2(:, 6:5:end));

OSt.mean_error_byN= 100*nansum( OSt.N_abortcodes,2)/ sum(nansum( OSt.N_abortcodes,2));
OSt.mean_error_byperc= 100*nanmean( OSt.perc_abortcodes,2);
OSt.SE_error_byperc= 100*nanstd( OSt.perc_abortcodes,0,2)/sqrt(size( OSt.perc_abortcodes,2));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end

function descriptions = load_descriptions(task,states,binary,varargin)
n_trials=numel(task);

global MA_STATES
STATE_matrix = repmat(MA_STATES.ALL,n_trials,1);
type_matrix  = [1 2 2.5 3 4 5 6];

empty_cell   = repmat({''},n_trials,1);

descriptions=struct('choice', empty_cell, 'task', empty_cell, 'aborted', empty_cell,'state_observed', empty_cell,...
    'sacc_onset', empty_cell, 'runname', empty_cell, 'abort_code', empty_cell);

effector_details    = {' saccade', ' free gaze reaching', ' joint movement', ' saccade with fixed hand position', ' reaching with eye fixation', '', ' free gaze reach with fixation'};
type_details        = {' fixation only', ' direct', ' semi memory', ' memory', ' delayed', ' M2S', ' M2S masked'};

choice_detail       = {' instructed', ' choice'};
task_type_num=[task.type];
for k=1:n_trials
    %task_type_bin(k)=type_matrix==task_type_num(k)
    task_type(k)           = type_details(type_matrix==task_type_num(k));
end
task_type=task_type';

task_effector       = effector_details([task.effector]+1)';
task_description    = strcat(task_type, task_effector);

[n_state_obs,~]=find(ismember(STATE_matrix',[states.state_obs]'));
[n_aborted_state,~]=find(STATE_matrix'==ones(size(STATE_matrix,2),1)*[states.state_abo]);
[n_sac_state,~]=find(ismember(STATE_matrix',[states.state_sac]'));

[descriptions.choice]           = choice_detail{[binary.choice]+1};
[descriptions.task]             = task_description{:};
[descriptions.abort_code]       = task.abort_code;
[descriptions.aborted]          = MA_STATES.ALL_NAMES{n_aborted_state};
[descriptions.state_observed]   = MA_STATES.ALL_CHANGE_NAMES{n_state_obs};

if ~isempty(n_sac_state)
    %     sacconsetdescriptions=cellstr(MA_STATES.ALL_NAMES(n_sac_state));
    % [descriptions.sacc_onset]       = sacconsetdescriptions{:};
    [descriptions.sacc_onset]       = MA_STATES.ALL_NAMES{n_sac_state};
else
    [descriptions.sacc_onset]       = empty_cell{:};
end
if numel(varargin) > 0
    [descriptions.runname]          = deal(varargin);
end
end

function hpc = complex2histper(complex_input,nbins)
% hpc	- converts complex vector data into a (normalized) histogram of two datasets (for real and imaginary part)

hpc(:,1) =hist(real(complex_input),nbins)./(numel(real(complex_input))-sum(isnan(real(complex_input))))*100;
hpc(:,2) =hist(imag(complex_input),nbins)./(numel(real(complex_input))-sum(isnan(real(complex_input))))*100;

if isreal(complex_input)
    hpc=[hpc(:,1) hpc(:,1)];
end
end

%% Plot formatting subfunctions

function P_options(P_title,P_xlabel,P_ylabel,P_Xlim,P_Ylim)
global P_par;

title(P_title, 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
xlabel(P_xlabel, 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
ylabel(P_ylabel, 'FontSize', P_par.FontSize, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName)
set(gca, 'FontName', P_par.FontName, 'FontSize', P_par.FontSize, 'Xlim', P_Xlim, 'Ylim', P_Ylim);
end

function par=mtit(varargin)
%MTIT		creates a major title in a figure with many axes
%
%		MTIT
%		- creates a major title above all
%		  axes in a figure
%		- preserves the stack order of
%		  the axis handles
%
%SYNTAX
%-------------------------------------------------------------------------------
%		P = MTIT(TXT,[OPT1,...,OPTn])
%		P = MTIT(FH,TXT,[OPT1,...,OPTn])
%
%INPUT
%-------------------------------------------------------------------------------
%    FH	:	a valid figure handle		[def: gcf]
%   TXT	:	title string
%
% OPT	:	argument
% -------------------------------------------
%  xoff	:	+/- displacement along X axis
%  yoff	:	+/- displacement along Y axis
%  zoff	:	+/- displacement along Z axis
%
%		title modifier pair(s)
% -------------------------------------------
%   TPx	:	TVx
%		see: get(text) for possible
%		     parameters/values
%
%OUTPUT
%-------------------------------------------------------------------------------
% par	:	parameter structure
%  .pos :	position of surrounding axis
%   .oh	:	handle of last used axis
%   .ah :	handle of invisible surrounding axis
%   .th :	handle of main title
%
%EXAMPLE
%-------------------------------------------------------------------------------
%	subplot(2,3,[1 3]);		title('PLOT 1');
%	subplot(2,3,4); 		title('PLOT 2');
%	subplot(2,3,5); 		title('PLOT 3');
%	axes('units','inches',...
%	     'color',[0 1 .5],...
%	     'position',[.5 .5 2 2]);	title('PLOT 41');
%	axes('units','inches',...
%	     'color',[0 .5 1],...
%	     'position',[3.5 .5 2 2]);	title('PLOT 42');
%	shg;
%	p=mtit('the BIG title',...
%	     'fontsize',14,'color',[1 0 0],...
%	     'xoff',-.1,'yoff',.025);
% % refine title using its handle <p.th>
%	set(p.th,'edgecolor',.5*[1 1 1]);

% created:
%	us	24-Feb-2003		/ R13
% modified:
%	us	24-Feb-2003		/ CSSM
%	us	06-Apr-2003		/ TMW
%	us	13-Nov-2009 17:38:17

defunit='normalized';
if	nargout
    par=[];
end

% check input
if	nargin < 1
    help(mfilename);
    return;
end
if	isempty(get(0,'currentfigure'))
    disp('MTIT> no figure');
    return;
end

vl=true(size(varargin));
if	ischar(varargin{1})
    vl(1)=false;
    figh=gcf;
    txt=varargin{1};
elseif	any(ishandle(varargin{1}(:)))		&&...
        ischar(varargin{2})
    vl(1:2)=false;
    figh=varargin{1};
    txt=varargin{2};
else
    error('MTIT> invalid input');
end
vin=varargin(vl);
[off,vout]=get_off(vin{:});

% find surrounding box
ah=findall(figh,'type','axes');
if	isempty(ah)
    disp('MTIT> no axis');
    return;
end
oah=ah(1);

ou=get(ah,'units');
set(ah,'units',defunit);
ap=get(ah,'position');
if	iscell(ap)
    ap=cell2mat(get(ah,'position'));
end
ap=[	min(ap(:,1)),max(ap(:,1)+ap(:,3)),...
    min(ap(:,2)),max(ap(:,2)+ap(:,4))];
ap=[	ap(1),ap(3),...
    ap(2)-ap(1),ap(4)-ap(3)];

% create axis...
xh=axes('position',ap);
% ...and title
th=title(txt,'interpreter', 'none',vout{:});
tp=get(th,'position');
set(th,'position',tp+off);
set(xh,'visible','off','hittest','on');
set(th,'visible','on');

% reset original units
ix=find(~strcmpi(ou,defunit));
if	~isempty(ix)
    for	i=ix(:).'
        set(ah(i),'units',ou{i});
    end
end

% ...and axis' order
uistack(xh,'bottom');
axes(oah);				%#ok

if	nargout
    par.pos=ap;
    par.oh=oah;
    par.ah=xh;
    par.th=th;
end

    function	[off,vout]=get_off(varargin)
        
        % search for pairs <.off>/<value>
        
        off=zeros(1,3);
        io=0;
        for	mode={'xoff','yoff','zoff'};
            ix=strcmpi(varargin,mode);
            if	any(ix)
                io=io+1;
                yx=find(ix);
                ix(yx+1)=1;
                off(1,io)=varargin{yx(end)+1};
                varargin=varargin(xor(ix,1));
            end
        end
        vout=varargin;
    end
end

function title_and_save(figure_handle,plot_title,print_out,plotoptions)
global P_par
mtit(figure_handle,[plot_title, print_out], 'fontsize', 12, 'color', 'xoff', 0.0, 'yoff', 0.04, [0 0 0], 'FontSize', P_par.FontSize + 2, 'FontWeight', P_par.FontWeight, 'FontName', P_par.FontName);
stampit;
%saveas(gcf,[GLO.folder_to_save plot_title print_out]);
if plotoptions.create_pdf
    switch plotoptions.append_pdfs
        case 0
            export_fig([plotoptions.folder_to_save plot_title print_out], '-pdf','-transparent') % pdf by run
        case 1
            export_fig([plotoptions.folder_to_save plot_title, 'appended batches'], '-pdf', '-append','-transparent') % pdf by run
    end
    
    if plotoptions.close_figures_after_saving
        close(figure_handle)
    end
end
end
