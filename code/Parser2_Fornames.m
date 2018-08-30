%written by Gary Doran and Sai Saradha
classdef Parser2_Fornames
    methods (Static = true)
        function [num_labels label num_examples example_data Attributes_split]=parse2_names(problem_name)
                file = Parser2_Fornames.find_file(problem_name);
            if isempty(file)
                err = MException('Parser:NoFile', ...
                    'The specified file could not be located');
                throw(err);
            end
            % Creating a file identifier and identifying the line using fgetl:
                fid=fopen(file);
                tline=fgetl(fid);

            % This is the first line, to find the number of labels and their values
            %Removing the dot
                dotrem1=regexprep(tline,{'\.',''},{'',''});

            %Split the string with a comma delimiter
                split1=strsplit(dotrem1,',');[~,num_labels]=size(split1);

            %Store the labels in a separate variable
                label=zeros;
                for i=1:num_labels 
                label(i,1)=str2double(split1{1,i});end

            %Get the next line - We have the number of instances here and remove the
             %dot
                tline=fgetl(fid);
                dotrem2=regexprep(tline,{'\.',''},{'',''});
                split2=strsplit(dotrem2,',');[~,num_examples]=size(split2);

             %The first cell has the value 'index:1' (for eg), so removing the non digit
             %characters from the first cell
                split2{1,1}=regexprep(split2{1,1},{'\D',''},{'',''});

            %Store the number of examples in a variable, if required
                for i=1:num_examples example_data(i,1)=str2double(split2{1,i});end

             %We now have to process the attributes:
                   Attributes_split = textscan(fid, '%s %s', 'Delimiter', ':');

            %Removing dots if found:
                    Attributes_split{1,2}=regexprep(Attributes_split{1,2},{'\.',''},{'',''});

            %Check if the attribute has the value - continuous. If it is not
            %continuous, then create a cell for the specific attribute that holds the
            %values of that attribute:
                    attribute_split_size=size(Attributes_split{1});
                    num_attributes=attribute_split_size(1,1);
                    for i=1:num_attributes
                    if(~strcmp(Attributes_split{2}{i},'continuous'))
                    %split3=strsplit(Attributes_split{2}{i},',');
                    %Attributes_split{2}{i}=cell(split3);
                    Attributes_split{2}{i}='Notcontinuous';
                    end
                    end
                    Attributes_split=horzcat(Attributes_split{1,1},Attributes_split{1,2});
                    if(strcmp(problem_name,'volcanoes'))
                        Attributes_split(1,:)=[];
                    end
         fclose(fid);   
        end
        function file=find_file(problem_name)
            % Find the file with problem_name.data in some
            % subdirectory of the current directory
            len = length(problem_name);
            if len < 6 || ~strcmp('.names',problem_name(len - 4:len))
                problem_name = strcat(problem_name, '.names');
            end
            current_dir = pwd();
            file=Parser2_Fornames.find_file_rec(current_dir, problem_name);
        end
        
        function file=find_file_rec(dir_name, file_name)
            % Recursively find a file in the directory or subdirectory
            list = dir(dir_name);
            for cellname = {list.name}
                name = char(cellname);
                if strcmp('.', name) || strcmp('..', name)
                    continue
                end
                fullname = strcat(dir_name, '/', name);
                if isdir(fullname)
                    sub_file = Parser.find_file_rec(fullname, file_name);
                    if ~isempty(sub_file)
                        file = sub_file;
                        return;
                    end
                else
                    if strcmp(file_name, name)
                        file = fullname;
                        return;
                    end
                end
            end
            file = [];
            return;
        end
    end
end
