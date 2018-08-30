function entropy_nomin=entropy_nomin_fun(nomin_data,total_examples)
num_nomin_data=size(nomin_data,1);
num_plus1_nomin=size(find(nomin_data(:,end)==1),1);
num_minus1_nomin=num_nomin_data-num_plus1_nomin;
ent_nomin=entropy_data(num_plus1_nomin,num_minus1_nomin,num_nomin_data);
entropy_nomin=((num_nomin_data/total_examples)*ent_nomin);
end