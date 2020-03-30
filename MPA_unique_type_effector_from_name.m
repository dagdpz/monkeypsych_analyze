function [u_types,u_effectors,type_effector_short]=MPA_unique_type_effector_from_name(u_types,u_effectors,typeff)

all_type_effectors      = combvec(u_types,u_effectors)';
type_effectors =[];

% redifine type_effectors to include only relevant
for t=1:size(all_type_effectors,1)
    typ=all_type_effectors(t,1);
    eff=all_type_effectors(t,2);
    [~, type_effector_short{t}]=MPA_get_type_effector_name(typ,eff);
    if ~ismember(type_effector_short{t},typeff) %|| sum(tr_con)<1
        continue;
    end
    type_effectors=[type_effectors; all_type_effectors(t,:)];
end
type_effector_short(~ismember(type_effector_short,typeff))=[];
u_types     =unique(type_effectors(:,1))';
u_effectors =unique(type_effectors(:,2))';