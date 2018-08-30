
function entropy_ygivenx=entropy_ygivenx(split_dataon_thresh1,split_dataon_thresh2,total_examples)
num_lessthresh=size(split_dataon_thresh1,1); %Sv- Number of instances less than threshold
num_greatthresh=size(split_dataon_thresh2,1);%Sv- Number of instances greater than threshold
num_plus1_split1=size(find(split_dataon_thresh1(:,end)==1),1);
num_minus1_split1=num_lessthresh-num_plus1_split1;
num_plus1_split2=size(find(split_dataon_thresh2(:,end)==1),1);
num_minus1_split2=num_greatthresh-num_plus1_split2;
ent_lessthresh=entropy_data(num_plus1_split1,num_minus1_split1,num_lessthresh);
ent_greatthresh=entropy_data(num_plus1_split2,num_minus1_split2,num_greatthresh);
entropy_ygivenx=((num_lessthresh/total_examples)*ent_lessthresh)+((num_greatthresh/total_examples)*ent_greatthresh);
if isnan(entropy_ygivenx)
    entropy_ygivenx= 0;
end
end