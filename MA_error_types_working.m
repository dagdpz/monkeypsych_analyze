
function [Abort_codes, Table_Abort_code, Abort_code_fullsummary, Abort_code_shortsummary, idx_Abortcode]= MA_error_types_working(out_comp )


% only input is the OUT_COMP from monkypsychAnalyze code

%%
% Danial
% first modified: 20140813
% Last modified: 20150430

%% all possible errors

Table_Abort_code= tabulate({out_comp.task.abort_code});

Abort_codes= {
'NO ABORT', 1;
'ABORT_USE_INCORRECT_HAND' ,2;  
'ABORT_HND_FIX_ACQ_STATE'  ,3; 
'ABORT_HND_FIX_HOLD_STATE' ,4;
'ABORT_HND_TAR_ACQ_STATE'  ,5;
'ABORT_HND_TAR_HOLD_STATE' ,6;
'ABORT_RELEASE_SENSOR_HOLD_STATE' ,7;
'ABORT_HND_TAR_ACQ_INV_STATE'  ,8;
'ABORT_HND_TAR_HOLD_INV_STATE' ,9;
'ABORT_HND_CUE_ON_STATE' ,10;
'ABORT_HND_MEM_PER_STATE',11;
'ABORT_HND_DEL_PER_STATE',12;
'ABORT_EYE_FIX_ACQ_STATE',13; 
'ABORT_EYE_FIX_HOLD_STATE',14;
'ABORT_EYE_TAR_ACQ_STATE',15;
'ABORT_EYE_TAR_HOLD_STATE',16;
'ABORT_EYE_TAR_ACQ_INV_STATE',17;
'ABORT_EYE_TAR_HOLD_INV_STATE',18;
'ABORT_EYE_CUE_ON_STATE',19;
'ABORT_EYE_MEM_PER_STATE',20;
'ABORT_EYE_DEL_PER_STATE',21;
'ABORT_JAW',22;
'ABORT_BODY',23;
'UNKNOWN ERROR CODE',24;
'ABORT_DIRTY_SENSORS', 25;
};

%%
    
%%
abort_code_List= {out_comp.task(:).abort_code}';
[~,idx_Abortcode]=ismember(abort_code_List,Abort_codes(:,1));
Demanded_Hand= [out_comp.task(:).demanded_hand]';
DemandHand_LH= Demanded_Hand==1;
DemandHand_RH= Demanded_Hand==2;
Reach_Hand= [out_comp.task(:).reach_hand]';
% HAND_Tar_r= [out_comp.binary(:).hndtar_r]';
% HAND_Tar_l= [out_comp.binary(:).hndtar_l]';
% EYE_Tar_r= [out_comp.binary(:).eyetar_r]';
% EYE_Tar_l= [out_comp.binary(:).eyetar_l]';
% 

%%
Nt= size(out_comp.task,1);

Abort_code_fullsummary= {
1,'NO ABORT'                           ,1, 'No Abort', sum(idx_Abortcode==1), sum(idx_Abortcode==1)/Nt, idx_Abortcode==1, find(idx_Abortcode==1);
2,'ABORT_USE_INCORRECT_HAND'           ,2, 'incor Hnd', sum(idx_Abortcode==2), sum(idx_Abortcode==2)/Nt, idx_Abortcode==2, find(idx_Abortcode==2);
3,'ABORT_USE_INCORRECT_LH'             ,2, 'incor LH', sum(idx_Abortcode==2 & Demanded_Hand==1), sum(idx_Abortcode==2 & Demanded_Hand==1)/Nt, (idx_Abortcode==2 & Demanded_Hand==1), find(idx_Abortcode==2 & Demanded_Hand==1);
%nansum(idx_IncorHnd_error_LorR(:,2)==1), nansum(idx_IncorHnd_error_LorR(:,2)==1)/Nt, ???;
4,'ABORT_USE_INCORRECT_RH'             ,2, 'incor RH', sum(idx_Abortcode==2 & Demanded_Hand==2), sum(idx_Abortcode==2 & Demanded_Hand==2)/Nt, (idx_Abortcode==2 & Demanded_Hand==2), find(idx_Abortcode==2 & Demanded_Hand==2);
%nansum(idx_IncorHnd_error_LorR(:,2)==2), nansum(idx_IncorHnd_error_LorR(:,2)==2)/Nt, ???;

5,'ABORT_HND_FIX_ACQ_STATE'            ,3, 'h FixAcq', sum(idx_Abortcode==3), sum(idx_Abortcode==3)/Nt, idx_Abortcode==3, find(idx_Abortcode==3);
6,'ABORT_HND_FIX_ACQ_move'             ,3, 'h move FixAcq', sum(idx_Abortcode==3 & ~isnan(Reach_Hand)),  sum(idx_Abortcode==3 & ~isnan(Reach_Hand))/Nt, (idx_Abortcode==3 & ~isnan(Reach_Hand)), find(idx_Abortcode==3 & ~isnan(Reach_Hand));
7,'ABORT_HND_no_movement'              ,3, 'h nomove FixAcq', sum(idx_Abortcode==3 & isnan(Reach_Hand)), sum(idx_Abortcode==3 & isnan(Reach_Hand))/Nt,  (idx_Abortcode==3 & isnan(Reach_Hand)), find(idx_Abortcode==3 & isnan(Reach_Hand));

8,'ABORT_HND_FIX_HOLD_STATE'           ,4, 'h FixHold', sum(idx_Abortcode==4), sum(idx_Abortcode==4)/Nt, idx_Abortcode==4, find(idx_Abortcode==4);
9,'ABORT_HND_FIX_HOLD_LH'              ,4, 'h FixHold LH', sum(idx_Abortcode==4 & Demanded_Hand==1), sum(idx_Abortcode==4 & Demanded_Hand==1)/Nt, (idx_Abortcode==4 & Demanded_Hand==1), find(idx_Abortcode==4 & Demanded_Hand==1);
10,'ABORT_HND_FIX_HOLD_RH'             ,4, 'h FixHold RH', sum(idx_Abortcode==4 & Demanded_Hand==2), sum(idx_Abortcode==4 & Demanded_Hand==2)/Nt, (idx_Abortcode==4 & Demanded_Hand==2), find(idx_Abortcode==4 & Demanded_Hand==2);

11,'ABORT_HND_TAR_ACQ_STATE'           ,5, 'h TarAcq', sum(idx_Abortcode==5), sum(idx_Abortcode==5)/Nt, idx_Abortcode==5, find(idx_Abortcode==5);

12,'ABORT_HND_TAR_HOLD_STATE'          ,6, 'h TarHold', sum(idx_Abortcode==6), sum(idx_Abortcode==6)/Nt, idx_Abortcode==6, find(idx_Abortcode==6);

13,'ABORT_RELEASE_SENSOR_HOLD_STATE'   ,7, 'sen Hold', sum(idx_Abortcode==7), sum(idx_Abortcode==7)/Nt, idx_Abortcode==7, find(idx_Abortcode==7);

14,'ABORT_HND_TAR_ACQ_INV_STATE'       ,8, 'h INVTarAcq', sum(idx_Abortcode==8), sum(idx_Abortcode==8)/Nt, idx_Abortcode==8, find(idx_Abortcode==8);

15,'ABORT_HND_TAR_HOLD_INV_STATE'      ,9, 'h INVTarHold', sum(idx_Abortcode==9), sum(idx_Abortcode==9)/Nt, idx_Abortcode==9, find(idx_Abortcode==9);

16,'ABORT_HND_CUE_ON_STATE'            ,10, 'h CUE', sum(idx_Abortcode==10), sum(idx_Abortcode==10)/Nt, idx_Abortcode==10, find(idx_Abortcode==10);

17,'ABORT_HND_MEM_PER_STATE'           ,11, 'h MEM', sum(idx_Abortcode==11), sum(idx_Abortcode==11)/Nt, idx_Abortcode==11, find(idx_Abortcode==11);
18,'ABORT_HND_MEM_PER_LH'              ,11, 'h MEM LH',  nansum(idx_Abortcode==11 & DemandHand_LH), nansum(idx_Abortcode==11 & DemandHand_LH)/Nt, (idx_Abortcode==11 & DemandHand_LH), find(idx_Abortcode==11 & DemandHand_LH);
19,'ABORT_HND_MEM_PER_RH'              ,11, 'h MEM RH',  nansum(idx_Abortcode==11 & DemandHand_RH), nansum(idx_Abortcode==11 & DemandHand_RH)/Nt, (idx_Abortcode==11 & DemandHand_RH), find(idx_Abortcode==11 & DemandHand_RH);

20,'ABORT_HND_DEL_PER_STATE'           ,12, 'h DEL', sum(idx_Abortcode==12), sum(idx_Abortcode==12)/Nt, idx_Abortcode==12, find(idx_Abortcode==12);

21,'ABORT_EYE_FIX_ACQ_STATE'           ,13, 'e FixAcq', sum(idx_Abortcode==13), sum(idx_Abortcode==13)/Nt, idx_Abortcode==13, find(idx_Abortcode==13);
22,'ABORT_EYE_FIX_HOLD_STATE'          ,14, 'e FixHold', sum(idx_Abortcode==14), sum(idx_Abortcode==14)/Nt, idx_Abortcode==14, find(idx_Abortcode==14);

23,'ABORT_EYE_TAR_ACQ_STATE'           ,15, 'e TarAcq',sum(idx_Abortcode==15), sum(idx_Abortcode==15)/Nt, idx_Abortcode==15, find(idx_Abortcode==15);

24,'ABORT_EYE_TAR_HOLD_STATE'          ,16, 'e TarHold',sum(idx_Abortcode==16), sum(idx_Abortcode==16)/Nt, idx_Abortcode==16, find(idx_Abortcode==16);

25,'ABORT_EYE_TAR_ACQ_INV_STATE'       ,17, 'e INVTarAcq',sum(idx_Abortcode==17), sum(idx_Abortcode==17)/Nt, idx_Abortcode==17, find(idx_Abortcode==17);

26,'ABORT_EYE_TAR_HOLD_INV_STATE'      ,18, 'e INVTarHold',sum(idx_Abortcode==18), sum(idx_Abortcode==18)/Nt, idx_Abortcode==18, find(idx_Abortcode==18);

27,'ABORT_EYE_CUE_ON_STATE'            ,19, 'e CUE', sum(idx_Abortcode==19), sum(idx_Abortcode==19)/Nt, idx_Abortcode==19, find(idx_Abortcode==19);

28,'ABORT_EYE_MEM_PER_STATE'           ,20, 'e MEM', sum(idx_Abortcode==20), sum(idx_Abortcode==20)/Nt, idx_Abortcode==20, find(idx_Abortcode==20);

29,'ABORT_EYE_DEL_PER_STATE'           ,21, 'e DEL',    sum(idx_Abortcode==21), sum(idx_Abortcode==21)/Nt, idx_Abortcode==21, find(idx_Abortcode==21);
30,'ABORT_JAW'                         ,22, 'Jaw',      sum(idx_Abortcode==22), sum(idx_Abortcode==22)/Nt, idx_Abortcode==22, find(idx_Abortcode==22);
31,'ABORT_BODY'                        ,23, 'Body',     sum(idx_Abortcode==23), sum(idx_Abortcode==23)/Nt, idx_Abortcode==23, find(idx_Abortcode==23);
32,'UNKNOWN ERROR CODE'                ,24, 'unknown',  sum(idx_Abortcode==24), sum(idx_Abortcode==24)/Nt, idx_Abortcode==24, find(idx_Abortcode==24);
33,'ABORT_DIRTY_SENSORS'               ,25, 'dirtySen', sum(idx_Abortcode==25), sum(idx_Abortcode==25)/Nt, idx_Abortcode==25, find(idx_Abortcode==25);
};

Abort_code_shortsummary = Abort_code_fullsummary;

end
