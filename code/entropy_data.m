%Entropy 
function entropy_data=entropy_data(num_plus1,num_minus1,total_examples)
    ent_plus=(num_plus1/total_examples)*log2(num_plus1/total_examples);
    ent_minus=(num_minus1/total_examples)*log2(num_minus1/total_examples);
    entropy_data=-ent_plus-ent_minus;
    if isnan(entropy_data)
    entropy_data = 0;
    end
end
