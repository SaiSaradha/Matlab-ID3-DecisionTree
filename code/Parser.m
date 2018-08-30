%written by Gary Doran
classdef Parser
    methods (Static = true)
        function [examples classifications]=parse(problem_name)
            file = Parser.find_file(problem_name);
            if isempty(file)
                err = MException('Parser:NoFile', ...
                    'The specified file could not be located');
                throw(err);
            end
            
            fid = fopen(file);
            
            filearr = {};
            
            tline = fgetl(fid);
            while ischar(tline)
                % Remove comments
                tline = regexprep(tline, '//.*', '');
                tline = strtrim(tline);
                if ~isempty(tline)
                    % Split and trim attributes
                    linearr = strtrim(regexpi(tline, ',', 'split'));
                    filearr = vertcat(filearr, linearr);
                end
                tline = fgetl(fid);
            end

            fclose(fid);
            
            cols = size(filearr, 2);
            classifications = str2num(char(filearr(:,cols)));
            classifications = 2*classifications-1;
            examples = [];
            for c = 2:(cols-1)
                % Convert columns as necessary
                examples = horzcat(examples,...
                    Parser.convert_column(filearr(:,c)));
            end
        end
        
        function column=convert_column(raw)
            % Convert column of nominal attributes to integers
            char_col = char(raw);
            column = str2num(char_col);
            if ~isempty(column)
                % It is a numeric column
                % (no need to convert)
                return
            end
            unq = unique(raw);
            rows = size(char_col,1);
            column = zeros(rows, 1);
            for r = 1:rows
                column(r,1) = find(strcmp(unq, raw(r,1)));
            end
        end
        
        function file=find_file(problem_name)
            % Find the file with problem_name.data in some
            % subdirectory of the current directory
            len = length(problem_name);
            if len < 6 || ~strcmp('.data',problem_name(len - 4:len))
                problem_name = strcat(problem_name, '.data');
            end
            current_dir = pwd();
            file=Parser.find_file_rec(current_dir, problem_name);
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
