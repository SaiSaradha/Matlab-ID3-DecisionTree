clc;
% clear;
display('We are going to build a decision tree classifier. But before we do that let us get the data set and for this, please answer few questions:');
%%To load the .data and .names files
display('Browse through and select the right path that contains the data and names files');
path_folder=uigetdir('C:\', 'Select path to the data');
data_file_path= dir(fullfile(path_folder,'*.data'));
name_file_path=dir(fullfile(path_folder,'*.names'));
data_file_name=strsplit(data_file_path.name,'.');
data_name=data_file_name{1};
cd(path_folder);

% % % Parse the .data and .names files
% fprintf('Okay, now let us get the data to our workspace; \n \n We do that by calling the objects of the parser function previously created. \n \nThis might be a bit slow !');
% [Examples Classifications]=Parser.parse(data_name);
%Parse .names file
[num_labels label num_examples example_data Attributes_split]=Parser2_Fornames.parse2_names(data_name);

%Remove the instances that are same
data=horzcat(Examples,Classifications);
data1=unique(data,'rows');

%Splitting the dataset back to Examples and Classifications
Examples=data1(:,1:end-1);
Classifications=data1(:,end);
total_examples=size(Examples,1);
if(strcmp(data_name,'volcanoes'))
    Examples=Examples(:,2:end);
end
%%
%Get user inputs
fprintf('The following inputs are required. \n 1. Would you like to perform a cross validation on your dataset ? \n Enter 0 if you want to perform crossvalidation, 1 if you prefer not to. \n Recommendation: Cross validation is a good way to avoid Overfitting! \n \n2. Enter the maximum depth of the tree, 0 - Full tree \n \n3. Select the split criterion - 0 for Information Gain, 1 for Gain Ratio \n Press any key when you are ready to enter the inputs');
pause; 
prompt = {'Enter Cross Validation value: (0 or 1)','Enter maximum depth range:', 'What is the split criterion - Type in 0 for IG, 1 for Gain Ratio'};
title_box = 'User Inputs for growing the dtree';
lines_box = 1;
default_value_box = {'0','0','0'};
user_inputs = inputdlg(prompt,title_box,lines_box,default_value_box);
cv_required=str2double(user_inputs{1});
depth_val=str2double(user_inputs{2});
split_type=str2double(user_inputs{3});
%Handling exception:
while ~(cv_required==0 || cv_required==1)
        prompt='\n \n Wrong value for cross validation, enter either 0 or 1. \n\n Enter the correct value for CV:';
        cv_required=input(prompt);
end
while ~(depth_val >= 0 && depth_val <= 499)
    prompt= '\n \n Wrong depth; minimum depth value - 0 and max - number of examples-1. \n \n Enter the correct value';
    depth_val=input(prompt);
end
while ~(split_type==0 || split_type==1)
    prompt=' \n \n Type in 0 for Information Gain, 1 for Gain Ratio. \n \n Enter the criterion type:';
    split_type=input(prompt);
end

%%
%Checking the depth value:
if depth_val >= total_examples-1
    depth_val=0;
end

%%
%Directing the user inputs to the correct process, building tree on cvdata or directly the entire dataset:
if(cv_required==0)
    
%Code for doing 5-fold cross validation, if the user typed in 0:
num_folds=5;

%For repeatability, creating a random stream object
s=RandStream.create('mrg32k3a','seed',12345);

%Partition the data into 5 stratified folds
partition=cvpartition(Classifications,'kfold',5,s);  %s given to the function; this makes sure that we get the same random partition of data how many every time we run it
training_data_fold = cell(num_folds,1);
test_data_fold=cell(num_folds,1);

for i =1:num_folds
    train_logical= partition.training(i); %cvpartition gives logical indices; 0 - a specific instance is not in that fold (i); 1 - instance is in the fold i
    test_logical = partition.test(i);
    fold_train= Examples(train_logical==1,:);
    fold_class= Classifications(train_logical==1,:);
    fold_test= Examples(test_logical==1,:);
    fold_class_test= Classifications(test_logical==1,:);
    training_data_fold{i}=struct('Training_Data',fold_train,'Training_Class',fold_class);
    test_data_fold{i}=struct('Test_Data',fold_test,'Test_Class',fold_class_test);
end

%Concatenation of data and classification:
training_data_final=cell(num_folds,1);
test_data_final=cell(num_folds,1);
for i=1:num_folds
training_data_final{i}=horzcat(training_data_fold{i,1}.Training_Data,training_data_fold{i,1}.Training_Class);
test_data_final{i}=horzcat(test_data_fold{i,1}.Test_Data,test_data_fold{i,1}.Test_Class);
end

num_node=0;
accuracy_output=zeros;
Attributes_split1=Attributes_split;
accuracy_final=cell(num_folds,1);
accuracy_rate=cell(num_folds,1);
parent_initial=0;
depth_initial=0;
thresh_init=0;
true_pos=cell(num_folds,1);
false_pos=cell(num_folds,1);
true_neg=cell(num_folds,1);
false_neg=cell(num_folds,1);

%Now build the decision tree for each fold by calculating Entropy, Information Gain and Gain Ratio for all attributes (Call to the respective functions here):
for i=1:num_folds
        fprintf('\n');
        fprintf('New fold');
        this_fold=training_data_final{i,1};
        %Find the total number of attributes:
        num_attr=size(this_fold,2)-1;
        %Now to create a decision tree in this fold let's call the
        %dtree_recursive function that returns the decision tree for this
        %fold

        %Creating an instance of the tree structure:
        dtree_tree=dtree_model(depth_val);
%         tic
        if(split_type==0)
        dtree_tree.tree_grow(this_fold,parent_initial,Attributes_split1, depth_initial, thresh_init);%Grow the decision tree
        else
        dtree_tree.tree_grow_GR(this_fold,parent_initial,Attributes_split1, depth_initial, thresh_init);
        end
        dtree_tree.temp_cell(:,find(all(cellfun(@isempty,dtree_tree.temp_cell),1))) = [];
%         toc
        test_data_acc=test_data_final{i};
        dtree_tree.testing(test_data_acc,Attributes_split1);
%         tic;
        accuracy_output=dtree_tree.output_class;
        label_fortest=(test_data_acc(:,end))';
%         toc;
        [accuracy_final{i,1}, accuracy_rate{i,1}, true_pos{i,1}, false_pos{i,1}, true_neg{i,1}, false_neg{i,1}]=dtree_tree.test_tree(accuracy_output,label_fortest);
        fprintf('\n');
        fprintf('Accuracy =  ');
        fprintf('%0.3f',accuracy_rate{i,1});
        fprintf('\n Size:  ');
        disp(dtree_tree.num_node)
        fprintf('Maximum Depth:  ');
        disp(dtree_tree.depth)
end

% %Average Accuracy over the five folds:
accuracy_cv_fold=(accuracy_rate{1,1}+accuracy_rate{2,1}+accuracy_rate{3,1}+accuracy_rate{4,1}+accuracy_rate{5,1})/5;

%For no CV:
accuracy_no_cv=0;
accuracy_rate_no_cv=0;

else %cv=1, No cross validation, so directly run the algorithm on full sample
    % Calculation of Entropy of the entire dataset:
    num_node=0;
    accuracy_output=zeros;
    Attributes_split1=Attributes_split;
    accuracy_final=cell(1,1);
    accuracy_rate=cell(1,1);
    parent_initial=0;
    depth_initial=0;
    thresh_init=0;
    true_pos=0;
    false_pos=0;
    true_neg=0;
    false_neg=0;
        no_cv_data=horzcat(Examples,Classifications);
        %Find the total number of attributes:
        num_attr=size(no_cv_data,2)-1;
        %Now to create a decision tree let's call the
        %dtree_tree function that returns the decision tree for this
        %fold
        dtree_tree=dtree_model(depth_val);
        if(split_type==0)
        dtree_tree.tree_grow(no_cv_data,parent_initial,Attributes_split1, depth_initial, thresh_init);%Grow the decision tree
        else
        dtree_tree.tree_grow_GR(no_cv_data,parent_initial,Attributes_split1, depth_initial, thresh_init);
        end
        dtree_tree.temp_cell(:,find(all(cellfun(@isempty,dtree_tree.temp_cell),1))) = [];        
        test_data_acc=(no_cv_data(:,end))'; %Since no cross validation, we send in the entire data again to test the tree
        dtree_tree.testing(no_cv_data,Attributes_split1);
        accuracy_output=dtree_tree.output_class;
        [accuracy_final{1,1}, accuracy_rate{1,1}, true_pos, false_pos, true_neg, false_neg]=dtree_tree.test_tree(accuracy_output,test_data_acc);
        fprintf('\n');
        fprintf('Accuracy =  ');
        fprintf('%0.3f',accuracy_rate{1,1});
        fprintf('\n Size:  ');
        disp(dtree_tree.num_node)
        fprintf('Maximum Depth:  ');
        disp(dtree_tree.depth)
end
%%

