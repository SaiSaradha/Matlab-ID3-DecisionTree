%Code to create the tree 
classdef dtree_model  < handle
    properties
%       
        depth %depth value
        queue_cell
        node_count %Number of nodes in the tree
        node_cell = {{}}
        data %Cell containing the data split based on the attribute
        temp_cell
        count
        num_node
        num_attr 
        max_depth
        num
        output_class
        threshold
        attrib_ind_track
    end
    methods
        function obj=dtree_model(maxi_depth)
             obj.count=0;
             obj.depth=0;
             obj.num_node=0;
             obj.queue_cell={};
             obj.temp_cell={};
             obj.num_attr=0; 
             obj.max_depth=maxi_depth;
             obj.data=zeros;
             obj.num=0;
             obj.output_class=zeros;
        end
        %Function to grow the decision tree:
        function tree_grow(obj,data_final,parent_name,Attributes_split1, currentdepth, thresh_f) 
            obj.num_attr=size(Attributes_split1,1);
            labels=data_final(:,end);
            
            if(~(obj.max_depth==0))
            if currentdepth == (obj.max_depth)
                obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
                i=size(obj.queue_cell,2);
                fprintf('Now at max depth');
                while (i >= 0)
                    if(i==0)   
                        obj.depth=currentdepth;
                        return;
                    end
                labels1=obj.queue_cell{1,1}(:,end);    
                dval = sum(labels1);
                dval = dval/abs(dval);
                if isnan(dval)
                    dval = 1;
                end
                obj.temp_cell{obj.count}.leaf = dval;
                obj.temp_cell{obj.count}.depth_current=obj.queue_cell{3,1};  
                obj.temp_cell{obj.count}.parent_name=obj.queue_cell{2,1};
                obj.temp_cell{obj.count}.data=labels1;
                obj.temp_cell{obj.count}.threshold=obj.queue_cell{4,1};          
                obj.queue_cell(:,1)=[];          
                i=i-1;
                obj.count=obj.count+1;
                end
            end
            end
            
            %Check if the attributes have been exhausted:
            if obj.num_node==obj.num_attr
                x1=size(find(labels==1),1);
                x2=size(find(labels==-1),1);
                if(x1>=x2)
                        obj.count=obj.count+1;
                        obj.temp_cell{obj.count}.leaf=1;
                        obj.temp_cell{obj.count}.depth_current=currentdepth;
                        obj.temp_cell{obj.count}.parent_name=parent_name;
                        obj.temp_cell{obj.count}.data=labels;
                        obj.temp_cell{obj.count}.threshold=thresh_f;
                        obj.depth=currentdepth;
                        return;
                else
                    obj.count=obj.count+1;
            	obj.temp_cell{obj.count}.leaf=-1;
                obj.temp_cell{obj.count}.depth_current=currentdepth;
                obj.temp_cell{obj.count}.parent_name=parent_name;
                obj.temp_cell{obj.count}.data=labels;
                obj.temp_cell{obj.count}.threshold=thresh_f;  
                obj.depth=currentdepth;
                return;
                end
            end
            
            %Lets find if the data is already biased:
            val=unique(labels);
            v1=size(val,1);
            if(v1==1)
            obj.count=obj.count+1;
            obj.temp_cell{obj.count}.leaf=val;
            obj.temp_cell{obj.count}.depth_current=currentdepth;
            obj.temp_cell{obj.count}.parent_name=parent_name;
            obj.temp_cell{obj.count}.data=labels;
            obj.temp_cell{obj.count}.threshold=thresh_f;   
            if obj.count >= 1 
                obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
                if size(obj.queue_cell,2)==0
                     obj.depth=currentdepth;
                     return;
                else
                obj.queue_cell(:,1)=[];
                if size(obj.queue_cell,2)==0
                    obj.depth=currentdepth;
                     return;
                else
                dataa=obj.queue_cell{1,1};
                parrent=char(obj.queue_cell{2,1});
                currentdepth=obj.queue_cell{3,1};
                thresh_ff=obj.queue_cell{4,1};
                obj.count=obj.count+1;
                tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_ff)
                end
                end                
            end
            else   
                
        %Now we pick the next attribute    
        num_traineg=size(data_final,1);
        num_plus1=size(find(data_final(:,end)==1),1);
        num_minus1=num_traineg-num_plus1;
        entropy_total=entropy_data(num_plus1,num_minus1,num_traineg);
        thresh_list=zeros(1,225);
        IG_lists=zeros(1,225);
        j=1;
        tic;
            while(j<=obj.num_attr)
        cont=strcmp('continuous',Attributes_split1{j,2}); %These are the attribute indices that are continuous
        new_threshold=0;
        max_IG_cont=0;
        thresh_val=0;
        IG_thisthresh=0;
        IG_previous=0;
        %Now if the attribute is continue, we need to find the threshold
        %for splitting the data
        if cont==1
            c=1;
            this_fold_1=sortrows(data_final,j);
            this_fold=horzcat(this_fold_1(:,j),this_fold_1(:,end));
            this_fold=sortrows(this_fold,1);
            num_traineg_thisfold=size(this_fold,1);
            while(c<num_traineg_thisfold)
                    if(~(this_fold(c,end)==this_fold(c+1,end)))
                    new_threshold=(this_fold(c,1)+this_fold(c+1,1))/2;
                    split_dataon_thresh1=this_fold(this_fold(:,1)<=new_threshold,:);
                    split_dataon_thresh2=this_fold(this_fold(:,1)>new_threshold,:);
                    entropy_ygivenx_thisthresh=entropy_ygivenx(split_dataon_thresh1,split_dataon_thresh2,num_traineg_thisfold);
                    IG_thisthresh=entropy_total-entropy_ygivenx_thisthresh;
                    end
                    if(IG_thisthresh>IG_previous)
                        max_IG_cont=IG_thisthresh;
                        thresh_val=new_threshold;
                        IG_previous=IG_thisthresh;
                    end
                c=c+1;
            end
              thresh_list(1,j)=thresh_val;
              IG_lists(1,j)=max_IG_cont;
            
        else
            %Nominal features
            entropy_nomin=zeros;
            this_fold=data_final;
            nomin_values=unique(this_fold(:,j));
            num_traineg_thisfold=size(this_fold,1);
            for disc=1:numel(nomin_values)
               nomin_data=this_fold(this_fold(:,j)==nomin_values(disc),:);
               entropy_nomin(disc)=entropy_nomin_fun(nomin_data,num_traineg_thisfold);
            end
            IG_nomin=entropy_total-sum(entropy_nomin);
            IG_lists(1,j)=IG_nomin;
        end              
   j=j+1;    
            end
            
             if obj.num_node >0
                for i=1:size(obj.attrib_ind_track,2)
                IG_lists(1,obj.attrib_ind_track(1,i))=-1;
                end
            end
            
              max_IG_final=max(max(IG_lists));
              
%             IF IG=0, ID3 will stop: (for that node)
            if(max_IG_final==0)
            x1=size(find(labels==1),1);
            x2=size(find(labels==-1),1);
                if(x1>=x2)
                        if obj.count >= 1 
                            obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
                        end
                            if size(obj.queue_cell,2)==0
                                    return;
                            else
                                obj.queue_cell(:,1)=[];
                            end
                            if size(obj.queue_cell,2)==0
                                 return;
                            else
                                dataa=obj.queue_cell{1,1};
                                parrent=char(obj.queue_cell{2,1});
                                currentdepth=obj.queue_cell{3,1};
                                thresh_ff=obj.queue_cell{4,1};
                                obj.count=obj.count+1;
                                tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_ff)
                            end
                 else
                              
                        if obj.count >= 1 
                            obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
                        end
                            if size(obj.queue_cell,2)==0
                                    return;
                            else
                                obj.queue_cell(:,1)=[];
                            end
                            if size(obj.queue_cell,2)==0
                                 return;
                            else
                                dataa=obj.queue_cell{1,1};
                                parrent=char(obj.queue_cell{2,1});
                                currentdepth=obj.queue_cell{3,1};
                                thresh_ff=obj.queue_cell{4,1};
                                obj.count=obj.count+1;
                                tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_ff)
                            end
                end
        end
            
      %Find the attribute:
      
        max_attrib_ind=find(IG_lists==max_IG_final);
        max_attrib=max_attrib_ind(1,1);
        thresh_forcalc=thresh_list(1,max_attrib);
        if obj.num_node==0
        fprintf('\n');
        fprintf('First Feature : ');
        disp(max_attrib);
        fprintf('\n');
        fprintf('First feature name: ');
        disp(Attributes_split1{max_attrib,1})
        end
        obj.num_node=obj.num_node+1;
        obj.attrib_ind_track=[obj.attrib_ind_track max_attrib];
        if (obj.count > 0 && ~(isempty(obj.queue_cell)))
        obj.queue_cell(:,1)=[];
        end  
        
            obj.count=obj.count+1;
            obj.temp_cell{obj.count}.depth_current=currentdepth;
            obj.temp_cell{obj.count}.data=labels;
            obj.temp_cell{obj.count}.parent_name=parent_name;
            obj.temp_cell{obj.count}.name=Attributes_split1{max_attrib,1};
        
    %Check if the attribute is continuous or nominal and split the data accordingly:
    
        cont_check=strcmp(Attributes_split1{max_attrib,2},'continuous');
        if cont_check==0 %This means that the attribute is nominal
              nomin_values=unique(data_final(:,max_attrib));
              obj.temp_cell{obj.count}.continuous=0;
              obj.temp_cell{obj.count}.threshold=thresh_f;
        for disc=1:numel(nomin_values)
            if disc==1
                currentdepth=currentdepth+1;
                name_parent=Attributes_split1(max_attrib,1);
                obj.num_attr=size(Attributes_split1,1);
            end
               new_data_nomin=data_final(data_final(:,max_attrib)==nomin_values(disc),:);
               obj.count=obj.count+1;       
               obj.queue_cell{1,obj.count}=new_data_nomin;
               obj.queue_cell{2,obj.count}=name_parent;
               obj.queue_cell{3,obj.count}=currentdepth;  
               obj.queue_cell{4,obj.count}=nomin_values(disc);
        end      
        %Recursive call to build the decision tree further down
        obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
        dataa=obj.queue_cell{1,1};
        parrent=char(obj.queue_cell{2,1});
        currentdepth=obj.queue_cell{3,1};
        thresh_nomin=obj.queue_cell{4,1};
        tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_nomin)
            else %The attribute is continuous
               obj.temp_cell{obj.count}.continuous=1;
               obj.temp_cell{obj.count}.threshold=thresh_f;
               currentdepth=currentdepth+1;
               name_parent=Attributes_split1(max_attrib,1);
               new_data_cont1_lt=data_final(data_final(:,max_attrib)<= thresh_forcalc,:);
               new_data_cont2_gt=data_final(data_final(:,max_attrib)>thresh_forcalc,:);
               obj.queue_cell{1,obj.count}=new_data_cont1_lt;
               obj.queue_cell{2,obj.count}=name_parent;
               obj.queue_cell{3,obj.count}=currentdepth;
               obj.queue_cell{4,obj.count}=thresh_forcalc;
               obj.count=obj.count+1;
               obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
               obj.queue_cell{1,obj.count}=new_data_cont2_gt;
               obj.queue_cell{2,obj.count}=name_parent;
               obj.queue_cell{3,obj.count}=currentdepth;
               obj.queue_cell{4,obj.count}=thresh_forcalc;
               dataa=obj.queue_cell{1,1};
               parrent=char(obj.queue_cell{2,1});
               currentdepth=obj.queue_cell{3,1};
               thresh_cont=obj.queue_cell{4,1};
               tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_cont)
        end 
         
            end
        end
        
        %This is the same function as tree_grow, but the split criterion is
        %Gain Ratio;
        function tree_grow_GR(obj,data_final,parent_name,Attributes_split1, currentdepth, thresh_f) 
            obj.num_attr=size(Attributes_split1,1);
            labels=data_final(:,end);
            
            %Check if the user specified maximum depth has been reached
            if(~(obj.max_depth==0))
            if currentdepth == (obj.max_depth)
                obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
                i=size(obj.queue_cell,2);
                fprintf('size of the queue now at max depth');
                while (i >= 0)
                    if(i==0)   
                        obj.depth=currentdepth;
                        return;
                    end
                labels1=obj.queue_cell{1,1}(:,end);    
                dval = sum(labels1);
                dval = dval/abs(dval);
                if isnan(dval)
                    dval = 1;
                end
                obj.temp_cell{obj.count}.leaf = dval;
                obj.temp_cell{obj.count}.depth_current=obj.queue_cell{3,1};  
                obj.temp_cell{obj.count}.parent_name=obj.queue_cell{2,1};
                obj.temp_cell{obj.count}.data=labels1;
                obj.temp_cell{obj.count}.threshold=obj.queue_cell{4,1};          
                obj.queue_cell(:,1)=[];          
                i=i-1;
                obj.count=obj.count+1;
                end
            end
            end
            
            %Check if the attributes have been exhausted:
            if obj.num_node==obj.num_attr
                x1=size(find(labels==1),1);
                x2=size(find(labels==-1),1);
                if(x1>=x2)
                        obj.count=obj.count+1;
                        obj.temp_cell{obj.count}.leaf=1;
                        obj.temp_cell{obj.count}.depth_current=currentdepth;
                        obj.temp_cell{obj.count}.parent_name=parent_name;
                        obj.temp_cell{obj.count}.data=labels;
                        obj.temp_cell{obj.count}.threshold=thresh_f;
                        obj.depth=currentdepth;
                        return;
                else
                    obj.count=obj.count+1;
            	obj.temp_cell{obj.count}.leaf=-1;
                obj.temp_cell{obj.count}.depth_current=currentdepth;
                obj.temp_cell{obj.count}.parent_name=parent_name;
                obj.temp_cell{obj.count}.data=labels;
                obj.temp_cell{obj.count}.threshold=thresh_f;  
                obj.depth=currentdepth;
                return;
                end
            end
            
            %Lets find if the data is already biased:
            val=unique(labels);
            v1=size(val,1);
            if(v1==1)
            obj.count=obj.count+1;
            obj.temp_cell{obj.count}.leaf=val;
            obj.temp_cell{obj.count}.depth_current=currentdepth;
            obj.temp_cell{obj.count}.parent_name=parent_name;
            obj.temp_cell{obj.count}.data=labels;
            obj.temp_cell{obj.count}.threshold=thresh_f;   
            if obj.count >= 1 
                obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
                if size(obj.queue_cell,2)==0
                     obj.depth=currentdepth;
                     return;
                else
                obj.queue_cell(:,1)=[];
                if size(obj.queue_cell,2)==0
                    obj.depth=currentdepth;
                     return;
                else
                dataa=obj.queue_cell{1,1};
                parrent=char(obj.queue_cell{2,1});
                currentdepth=obj.queue_cell{3,1};
                thresh_ff=obj.queue_cell{4,1};
                obj.count=obj.count+1;
                tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_ff)
                end
                end                
            end
            else   
                
        %Now we pick the next attribute    
        num_traineg=size(data_final,1);
        num_plus1=size(find(data_final(:,end)==1),1);
        num_minus1=num_traineg-num_plus1;
        entropy_total=entropy_data(num_plus1,num_minus1,num_traineg);
        thresh_list=zeros(1,225);
        GR_lists=zeros(1,225);
        j=1;
        tic;
            while(j<=obj.num_attr)
        cont=strcmp('continuous',Attributes_split1{j,2}); %These are the attribute indices that are continuous
        new_threshold=0;
        thresh_val=0;
        IG_thisthresh=0;
        GR_previous=0;
        gain_ratio=0;
        if cont==1
            c=1;
            this_fold_1=sortrows(data_final,j);
            this_fold=horzcat(this_fold_1(:,j),this_fold_1(:,end));
            num_traineg_thisfold=size(this_fold,1);
            while(c<num_traineg_thisfold)
                    if(~(this_fold(c,end)==this_fold(c+1,end)))
                    new_threshold=(this_fold(c,1)+this_fold(c+1,1))/2;
                    split_dataon_thresh1=this_fold(this_fold(:,1)<=new_threshold,:);
                    split_dataon_thresh2=this_fold(this_fold(:,1)>new_threshold,:);
                    entropy_ygivenx_thisthresh=entropy_ygivenx(split_dataon_thresh1,split_dataon_thresh2,num_traineg_thisfold);
                    IG_thisthresh=entropy_total-entropy_ygivenx_thisthresh;
                    data_t1_size=size(split_dataon_thresh1,1);
                    data_t2_size=num_traineg_thisfold-data_t1_size;
                    s1_by_s=data_t1_size/num_traineg_thisfold;
                    s2_by_s=data_t2_size/num_traineg_thisfold;
                    split_info=-((s1_by_s*log2(s1_by_s))+(s2_by_s*log2(s2_by_s)));
                    gain_ratio=IG_thisthresh/split_info;
                    end
                    if(gain_ratio>GR_previous)
                        max_GR_cont=gain_ratio;
                        thresh_val=new_threshold;
                        GR_previous=IG_thisthresh;
                        
                    end
                c=c+1;
            end
              thresh_list(1,j)=thresh_val;
              GR_lists(1,j)=max_GR_cont;
            
        else
            %Nominal features
            entropy_nomin=zeros;
            this_fold=data_final;
            nomin_values=unique(this_fold(:,j));
            num_traineg_thisfold=size(this_fold,1);
            split_info=zeros;
            for disc=1:numel(nomin_values)
               nomin_data=this_fold(this_fold(:,j)==nomin_values(disc),:);
               entropy_nomin(disc)=entropy_nomin_fun(nomin_data,num_traineg_thisfold);
               nomin_data_size=size(nomin_data,1);
               sc_by_s=nomin_data_size/num_traineg_thisfold;
               split_info(disc)=-(sc_by_s*log2(sc_by_s));
            end
            IG_nomin=entropy_total-sum(entropy_nomin);
            split_info_t=sum(split_info);
            gain_ratio=IG_nomin/split_info_t;
            GR_lists(1,j)=gain_ratio;
        end              
   j=j+1;    
            end
            
            if obj.num_node >0
                for i=1:size(obj.attrib_ind_track,2)
                GR_lists(1,obj.attrib_ind_track(1,i))=-1;
                end
            end
            
              max_GR_final=max(max(GR_lists)); 
              
            %IF GR=0, ID3 will stop:
            if(max_GR_final==0)
            x1=size(find(labels==1),1);
            x2=size(find(labels==-1),1);
                if(x1>=x2)
                        if obj.count >= 1 
                            obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
                        end
                            if size(obj.queue_cell,2)==0
                                    return;
                            else
                                obj.queue_cell(:,1)=[];
                            end
                            if size(obj.queue_cell,2)==0
                                 return;
                            else
                                dataa=obj.queue_cell{1,1};
                                parrent=char(obj.queue_cell{2,1});
                                currentdepth=obj.queue_cell{3,1};
                                thresh_ff=obj.queue_cell{4,1};
                                obj.count=obj.count+1;
                                tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_ff)
                            end
                 else
                              
                        if obj.count >= 1 
                            obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
                        end
                            if size(obj.queue_cell,2)==0
                                    return;
                            else
                                obj.queue_cell(:,1)=[];
                            end
                            if size(obj.queue_cell,2)==0
                                 return;
                            else
                                dataa=obj.queue_cell{1,1};
                                parrent=char(obj.queue_cell{2,1});
                                currentdepth=obj.queue_cell{3,1};
                                thresh_ff=obj.queue_cell{4,1};
                                obj.count=obj.count+1;
                                tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_ff)
                            end
                end
        end
            
      %Find the root attribute:
        max_GR_final=max(max(GR_lists)); 
        max_attrib_ind=find(GR_lists==max_GR_final);
        max_attrib=max_attrib_ind(1,1);
        thresh_forcalc=thresh_list(1,max_attrib);
        if obj.num_node==0
        fprintf('\n');
        fprintf('First Feature : ');
        disp(max_attrib);
        fprintf('\n');
        fprintf('First feature name: ');
        disp(Attributes_split1{max_attrib,1})
        end
        obj.num_node=obj.num_node+1;
        obj.attrib_ind_track=[obj.attrib_ind_track max_attrib];
        if (obj.count > 0 && ~(isempty(obj.queue_cell)))
        obj.queue_cell(:,1)=[];
        end          
            obj.count=obj.count+1;
            obj.temp_cell{obj.count}.depth_current=currentdepth;
            obj.temp_cell{obj.count}.data=labels;
            obj.temp_cell{obj.count}.parent_name=parent_name;
            obj.temp_cell{obj.count}.name=Attributes_split1{max_attrib,1};
        
    %Check if the attribute is continuous:
    
        cont_check=strcmp(Attributes_split1{max_attrib,2},'continuous');
        if cont_check==0 %This means that the attribute is nominal
              nomin_values=unique(data_final(:,max_attrib));
              obj.temp_cell{obj.count}.continuous=0;
              obj.temp_cell{obj.count}.threshold=thresh_f;
        for disc=1:numel(nomin_values)
            if disc==1
                currentdepth=currentdepth+1;
                name_parent=Attributes_split1(max_attrib,1);
                obj.num_attr=size(Attributes_split1,1);
            end
               new_data_nomin=data_final(data_final(:,max_attrib)==nomin_values(disc),:);
               obj.count=obj.count+1;       
               obj.queue_cell{1,obj.count}=new_data_nomin;
               obj.queue_cell{2,obj.count}=name_parent;
               obj.queue_cell{3,obj.count}=currentdepth;  
               obj.queue_cell{4,obj.count}=nomin_values(disc);
        end      
        %Recursive call to build the decision tree further down
        obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
        dataa=obj.queue_cell{1,1};
        parrent=char(obj.queue_cell{2,1});
        currentdepth=obj.queue_cell{3,1};
        thresh_nomin=obj.queue_cell{4,1};
        tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_nomin)
            else %The attribute is continuous
               obj.temp_cell{obj.count}.continuous=1;
               obj.temp_cell{obj.count}.threshold=thresh_f;
               currentdepth=currentdepth+1;
               name_parent=Attributes_split1(max_attrib,1);
               new_data_cont1_lt=data_final(data_final(:,max_attrib)<= thresh_forcalc,:);
               new_data_cont2_gt=data_final(data_final(:,max_attrib)>thresh_forcalc,:);
               obj.queue_cell{1,obj.count}=new_data_cont1_lt;
               obj.queue_cell{2,obj.count}=name_parent;
               obj.queue_cell{3,obj.count}=currentdepth;
               obj.queue_cell{4,obj.count}=thresh_forcalc;
               obj.count=obj.count+1;
               obj.queue_cell(:,find(all(cellfun(@isempty,obj.queue_cell),1))) = [];
               obj.queue_cell{1,obj.count}=new_data_cont2_gt;
               obj.queue_cell{2,obj.count}=name_parent;
               obj.queue_cell{3,obj.count}=currentdepth;
               obj.queue_cell{4,obj.count}=thresh_forcalc;
               dataa=obj.queue_cell{1,1};
               parrent=char(obj.queue_cell{2,1});
               currentdepth=obj.queue_cell{3,1};
               thresh_cont=obj.queue_cell{4,1};
               tree_grow(obj,dataa,parrent,Attributes_split1, currentdepth, thresh_cont)
        end 
         
            end
        end
        
   
  %Now given any unseen instances, the tree would predict the output class:
  
        function testing(obj,test_data,Attributes_split)
            %We are going to traverse the tree till the leaf and determine
            %the value at the leaf for every example, this will be our
            %predicted output
            obj.temp_cell(:,find(all(cellfun(@isempty,obj.temp_cell),1))) = [];
            num_eg=size(test_data,1);
            i=1;
            tree_built=obj.temp_cell;
            parentt=tree_built{1,1}.name;
            this_node=tree_built{1,1};
        while(i<=num_eg)
            single_data=test_data(i,:);
            recur_findleaf(obj,single_data,Attributes_split,parentt,this_node); 
            i=i+1;
            
        end
        end
        
        function recur_findleaf(obj,single_data,Attributes_split,parent_node,this_node)
            %Check if the node is a leaf and if it is, return the value
            leaf_check=any(strcmp('leaf',fieldnames(this_node)));
            if leaf_check==1
                obj.num=obj.num+1;
                obj.output_class(obj.num)= this_node.leaf;
                return;
            end
            %Now if there is no leaf, then find the child nodes:
            poss_nodes={};
            %Now find the child nodes:
            for j=1:size(obj.temp_cell,2)
            parent_check=any(strcmp('parent_name',fieldnames(obj.temp_cell{1,j})));
            if parent_check==1
            node_isparent=obj.temp_cell{1,j}.parent_name;
            if(strcmp(node_isparent, parent_node))
                poss_nodes{1,j}=obj.temp_cell{1,j};
            end
            end
            end
            poss_nodes(:,find(all(cellfun(@isempty,poss_nodes),1))) = [];
            if(isempty(poss_nodes))
                leaf_value=sum(this_node.data);
                leaf_value= leaf_value/abs(leaf_value);
                obj.num=obj.num+1;
                obj.output_class(obj.num)= leaf_value;
                if isnan(leaf_value)
                    obj.output_class(obj.num) = 1;
                end
                return;
            end
            %Now lets find the index of the attribute:
            a=strfind(Attributes_split(:,1), parent_node);
            for i=1:size(Attributes_split,1) 
            if a{i,1}==1 
            index=i;
            end 
            end
            if(this_node.continuous==1) %This means that attribute is continuous
            
            %If this attribute is continuous, then it would be split
                %only into two
            if(single_data(:,index)<= poss_nodes{1,1}.threshold)
                leaf_check2=any(strcmp('leaf',fieldnames(poss_nodes{1,1})));  
            if leaf_check2==1
                obj.num=obj.num+1;
                obj.output_class(obj.num)= poss_nodes{1,1}.leaf;
                return;
            end
                next_parent=poss_nodes{1,1}.name;  
                next_node=poss_nodes{1,1};
                recur_findleaf(obj,single_data,Attributes_split,next_parent,next_node);
            else
                if(size(poss_nodes,2)==2)
                    leaf_check2=any(strcmp('leaf',fieldnames(poss_nodes{1,2})));
            if leaf_check2==1
                obj.num=obj.num+1;
                obj.output_class(obj.num)= poss_nodes{1,2}.leaf;
                return;
            end
            else
                  leaf_check2=any(strcmp('leaf',fieldnames(poss_nodes{1,1}))); %fixed
            if leaf_check2==1
                obj.num=obj.num+1;
                obj.output_class(obj.num)= poss_nodes{1,1}.leaf;
                return;
            end   
                end
                 next_parent=poss_nodes{1,2}.name;
                 next_node=poss_nodes{1,2};
                recur_findleaf(obj,single_data,Attributes_split,next_parent,next_node);
            
            end
            else
                %This attribute has to be nominal
                for i=1:size(poss_nodes,2)
                   if(single_data(:,index)== poss_nodes{1,i}.threshold)
                       leaf_check2=any(strcmp('leaf',fieldnames(poss_nodes{1,i})));  
                        if leaf_check2==1
                        obj.num=obj.num+1;
                        obj.output_class(obj.num)= poss_nodes{1,i}.leaf;
                        return;
                        end
                    next_parent=poss_nodes{1,i}.name;     
                    next_node=poss_nodes{1,i};
                    recur_findleaf(obj,single_data,Attributes_split,next_parent,next_node);
                   end
                end
            end
        end
        
        
%     %Now calculating Accuracy   
     function [accuracy_normal,accuracy_calc, true_pos, false_pos, true_neg, false_neg]=test_tree(obj, tree_output,actual_output)
         correct_predict=0;
         true_pos=0;
         true_neg=0;
         false_pos=0;
         false_neg=0;
         for i=1:size(tree_output,2)
             if tree_output(i)==actual_output(i)
                 correct_predict=correct_predict+1;
             end
         %Normal Accuracy calculation
        accuracy_normal=double(100*(correct_predict/size(tree_output,2)));
        %Accuracy
        if(actual_output(i)==1 && tree_output(i)==1)
            true_pos=true_pos+1;
        elseif (actual_output(i)==-1 && tree_output(i)==-1)
            true_neg=true_neg+1;
        elseif (actual_output(i)==1 && tree_output(i)==-1)
            false_neg=false_neg+1;
        elseif (actual_output(i)==-1 && tree_output(i)==1)
            false_pos=false_pos+1;
        end
        end
        accuracy_calc = double((true_pos+true_neg)/(true_pos+true_neg+false_neg+false_pos));
% 
     end
    end
end