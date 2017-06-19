% Pickle.m
%
% Mark J. Olah (mjo@cs.unm DOT edu)
% 2014 - 2017
% copyright: see LICENCE file

classdef Pickle < matlab.mixin.Copyable
    % The Pickle class is what allows a class to save() to and load() from files with a specific
    % extension.  It has a notion of a obj.workingDir which is the "home" directory for the object, where
    % its save file will reside.  The obj.Paths structure is a list of other related files and their
    % relative paths.
    %
    % A pickle object is able to have a blank unititialized state.  It can be reset to this state with
    % the resetObject() method.  A load() overwrites the current state of the object with the state from the
    % object or file that is loaded.
    %
    % A class inheriting from Pickle must define several abstract methods and properties which configure
    % the operations of saving and loading.
    %
    % Notes:
    %  * This class uses the metaclass.ProprtyList property to get the definitive list of a class's
    % properties.  This is better than the properties() function which cannot find "hidden" properties.


    %All abstract properties must be declared in a subclass
    properties (Abstract=true, Constant=true)
        saveFileExt; % The extension used for saved files
        % These next properties are the expected format for the uigetfile and uiputfile matlab GUI
        % functions which allow us to pop-up specializes saving/loading GUI dialogs for each Pickle
        % class.  See the uigetfile help for more info on the format.
        SaveableDataFormats; %Ex: {'*.spdata', 'SPData (.spdata)'};
        LoadableDataFormats; %Ex: {'*.mat;*.tif;*.ics;*.spdata;*.spt','All Loadable Sources';...
                             %     '*.spdata','SPData file'; '*.spt', 'SPT object files (.spt)'};
    end

    properties (Abstract=true, Hidden=true)
        version; %For future file format version changes
    end

    properties (Abstract=true)
        Paths; %All filenames are relative paths from the workingDir
    end

    properties (Dependent=true)
        saveFilePath;   % Full path to the .spdata file that this object is associated with
        saveFileBaseName; % Base name of the spdata
    end

    properties (Transient=true)
        workingDir; %This is wherever we are currently working from.
                    %This is not saved as a permenant property because we can
                    %infer it from the file name on load, and the files'
                    %absolute path may change before we open the object again.
    end

    properties (SetAccess=protected, Transient=true, Hidden=true)
        initialized = false; %Logical if this object has been initialized to a valid data source yet
        dirty = false; %Marks that object state changes have changed and need to be written to disk.
        preservedProperties = struct();
    end
    
    methods
        function params = getParamStruct(obj)
            %
            % This returns a structure version of the class with all the important permement properties
            % saved.  This same structure is used internally for the save/load format and for the
            % presevation of properties and the use of default properties.
            %
            params = obj.getPermenantProperties();
        end
        
        function save(obj)
            if ~obj.initialized
                error('Pickle:save','Object is not initialized.');
            end
            Pickle.createDirIfNonexistant(obj.workingDir);
            obj.updateFromPreservedProperties(); %Fill in any blank (unset) parameters with the preseverd parameters.            
            save(obj.saveFilePath,'obj'); %do the actual save
            obj.dirty = false;
        end
       

        function saveas(obj, newsavepath)
            %spdatapath is a full path
            if ~obj.initialized
                error('Pickle:save','Object is not initialized.');
            end
            if nargin == 1   %Allow a dialog selection of filename
                p = obj.saveFilePath;
                if isempty(p)
                    p = obj.workingDir;
                end
                [filename, pathname] = uiputfile(obj.SaveableDataFormats,'Select save location', p);
                if ~filename; return; end
                newsavepath = fullfile(pathname,filename);
            end
            [newpath, newfile, ext] = fileparts(newsavepath);
            if isempty(newpath)
                newpath = obj.workingDir;
                if isempty(obj.workingDir)
                    error('Pickle:saveas','No directory specified and obj.workingDir not set'); 
                end
            end
            if isempty(ext)
                ext = obj.saveFileExt;
            elseif ~strcmp(ext,obj.saveFileExt)
                error('Pickle:saveas','New save file does not end in %s',obj.saveFileExt);
            end
            if ~strcmp(newpath,obj.workingDir)
                %Changed working directory so need to update relative paths
                obj.updatePaths(newpath);
                obj.workingDir = collapsepath(newpath);        
            end
            obj.Paths.saveFile = [newfile ext];
            obj.save();
        end

        function resetObject(obj)
            %Resets this object to a blank state.
            % reset all permentant and transient properties of this object to the default.  Clears any
            % preserved properties.
            % Overload this function in a subclass to allow preservation of some varaible (e.g. gui
            % stuff that is independant of object state)
            mc = metaclass(obj);
            props = mc.PropertyList; %Better than the properties() function as it finds "hidden" properties too
            for i=1:length(props)
                prop = props(i);
                name = prop.Name;
                if prop.Constant || prop.Dependent
                    continue; 
                end
                if prop.HasDefault
                    val = prop.DefaultValue;
                else
                    val = [];
                end
                obj.modifyProtectedProperty(name,val);
            end
        end

        function setPropertyDefaults(obj, defaultProperties)
            if ~isstruct(defaultProperties)
                defaultProperties = defaultProperties.getParamStruct();
            end
            props = fieldnames(defaultProperties);
            for n=1:length(props)
                prop = props{n};
                val = defaultProperties.(prop);
                if ~isempty(val) && ~strcmp(prop,'class')
                    obj.modifyProtectedProperty(prop, defaultProperties.(prop));
                end
            end
        end


        function setPreservedProperties(obj, defaultProperties)
            if ~isstruct(defaultProperties)
                defaultProperties = defaultProperties.getParamStruct();
            end
            props = fieldnames(defaultProperties);
            for n=1:length(props)
                prop = props{n};
                val = defaultProperties.(prop);
                if ~isempty(val)
                    obj.preservedProperties.(prop) = defaultProperties.(prop);
                end
            end
        end

        function p=getFilePath(obj,filekey)
            % filekey = string - the name of the file in the obj.Paths struct
            if isfield(obj.Paths,filekey) && ~isempty(obj.Paths.(filekey))
                parts=strsplit(obj.Paths.(filekey),{'\\','/'});
                p=fullfile(obj.workingDir, parts{:});
            else
                p=[];
            end
        end

        %% Dependent properties
        function fname=get.saveFilePath(obj)
            if ~obj.initialized || isempty(obj.workingDir) || ~isfield(obj.Paths,'saveFile') || isempty(obj.Paths.saveFile)
                fname = [];
            else
                fname = fullfile(obj.workingDir, obj.Paths.saveFile);
            end
        end

        function fname=get.saveFileBaseName(obj)
            if ~isfield(obj.Paths,'saveFile') || isempty(obj.Paths.saveFile)
                fname = [];
            else
                [~,fname,~] = fileparts(obj.Paths.saveFile);
            end
        end
    end
    
    methods (Abstract = true, Access = protected)
        
        % modifyProtectedProperty - This must be implemented by any
        % subclass.  Unfortunatly we cannot directly modify the protected
        % properties of subclasses, but we can call this abstract method on
        % the subclass.
        modifyProtectedProperty(obj, name, newval);
        val=getProtectedProperty(obj, name, newval);

        %To get this to work copy and paste the following code into your Pickle sub-class
        %
        %
        %methods (Access=protected) % Abstract methods inherited from Pickle            
        %    function val = getProtectedProperty(obj, name)
        %        %This is necessary for Pickle functionality to be able to access subclass protected variables
        %        val = obj.(name);
        %    end
        %
        %    function modifyProtectedProperty(obj, name, newval)
        %        %This is necessary for Pickel functionality to be able to change subclass protected variables
        %        obj.(name)=newval;
        %    end
        %end % Abstract methods inherited from Pickle
        %
    end

    methods (Access=protected)
        function updatePaths(obj, newWorkingDir)
            %Called when the working directory is changed
            file_names=fieldnames(obj.Paths);
            for i=1:length(file_names)
                file_name=file_names{i};
                old_rel_path=obj.Paths.(file_name);
                if ~isempty(old_rel_path)
                    switch file_name
                        case 'saveFile'
                            continue;
                        otherwise
                            obj.Paths.(file_name) = relativepath(newWorkingDir,fullfile(obj.workingDir, old_rel_path));
                    end
                end
            end
        end
        
        function propnames = getPermenantPropertyNames(obj)
            % propnames - a cell array of permenant property names
            function ret=isPermanant(p)
                ret= ~(p.Dependent || p.Constant || p.Transient);
            end
            mc = metaclass(obj);
            props = mc.PropertyList; %Better than the properties() function as this finds "hidden" properties too
            props = props(arrayfun(@isPermanant,props));
            propnames = cellmap(@(p) p.Name,props);
        end
        
        function propnames = getTransientPropertyNames(obj)
            % propnames - a cell array of transient property names
            mc = metaclass(obj);
            props = mc.PropertyList; 
            props = props(arrayfun(@(p) p.Transient, props));
            propnames = cellmap(@(p) p.Name,props);
        end

        function propstruct = getPermenantProperties(obj)
            props = obj.getPermenantPropertyNames();
            propvals = cellmap(@(p) obj.getProtectedProperty(p), props);
            propstruct = cell2struct(propvals,props);
            propstruct.class = class(obj);
        end

        function reconstructPermenantProperties(obj,propstruct)
            if ~strcmp(propstruct.class, class(obj))
                error('Pickle:reconstructPermenantProperties','Incompatible struct for class: "%s". This class: "%s"',propstruct.class, class(obj));
            end
%             if propstruct.version ~= obj.version
%                 error('Pickle:reconstructPermenantProperties','Incompatible version:%i. This class:%i',propstruct.version, obj.version);
%             end
            props = obj.getPermenantPropertyNames();
            for n = 1:length(props)
                prop = props{n};
                if ~isfield(propstruct,prop)
                    error('Pickle:reconstructPermenantProperties','No value for property "%s"',prop);
                end
                obj.modifyProtectedProperty(prop, propstruct.(prop));
            end
        end

        function setPermenantProperties(obj,propstruct)
            props = fieldnames(propstruct);
            for n = 1:length(props)
                prop = props{n};
                if ~isprop(obj,prop)
                    error('Pickle:setPermenantProperties','Object has no property "%s"',prop);
                end
                obj.modifyProtectedProperty(prop, propstruct.(prop));
            end
        end

        function propstruct = saveobj(obj)
            %This is called by matlab internally when save() function is called.  We simply need to
            %return the object as a property structure, which is what getPermenantProperties() already
            %does for us.
            propstruct = obj.getPermenantProperties();
        end

        function reloadobj(obj,propstruct)
            if isfield(propstruct,'Paths')
                %Check saved filepaths use the appropriate file path
                %slashes
                fn = fieldnames(propstruct.Paths);
                for i=1:numel(fn)
                    filename = propstruct.Paths.(fn{i});
                    if ~isempty(filename)
                        dirnames = strsplit(filename,{'\\','/'});
                        propstruct.Paths.(fn{i}) = fullfile(dirnames{:});
                    end
                end
            end
            obj.reconstructPermenantProperties(propstruct);
            obj.initialized = true;
        end

        function copyobj(obj, other)
            obj.reconstructPermenantProperties(other.getPermenantProperties());
            obj.initialized = other.initialized;
        end
        
        function savePreservedProperties(obj)
            %Save non-null previous parameters as defaults
            props = obj.getPermenantPropertyNames();
            for n=1:length(props)
                prop = props{n};
                val = obj.getProtectedProperty(prop);
                if ~isempty(val)
                    obj.preservedProperties.(prop) = val;
                end
            end
        end

        function updateFromPreservedProperties(obj)
            %Update any blank values with preserved properties
            % should be only called internally from save
            props = obj.getPermenantPropertyNames();
            for n=1:length(props)
                prop = props{n};
                val = obj.getProtectedProperty(prop);
                if isempty(val) && isfield(obj.preservedProperties,prop)
                    pp = obj.preservedProperties.(prop);
                    if ~isempty(pp) && ~isstruct(pp) && ~iscell(pp)
                        obj.modifyProtectedProperty(prop,pp);
                    end
                end
            end
            %Copy over any preserved paths
            if isfield(obj.preservedProperties,'Paths')
                pathnames = fieldnames(obj.preservedProperties.Paths);
                for i=1:length(pathnames);
                    p=pathnames{i};
                    if ~isfield(obj.Paths,p) || isempty(obj.Paths.(p))
                        obj.Paths.(p) = obj.preservedProperties.Paths.(p);
                    end
                end
            end
        end
        
        
        function assertInitialized(obj)
            if ~obj.initialized
                error('Pickle:assertInitialized', 'Object is not initialized.  Use the load() method to initialize.');
            end
        end


    end %protected methods


    methods (Static=true)
        function obj=loadobj(propstruct)
            %Called by the matlab loading routine to initialize an object.
            Constructor = str2func(propstruct.class);
            obj = Constructor();
            obj.reloadobj(propstruct);
        end

        function createDirIfNonexistant(newpath)
            if ~exist(newpath, 'dir')
                [success, mess, messid]=mkdir(newpath);
                if ~success
                    error('GUIBuilder:createDirIfNonexistant','Unable to create directory: "%s" Error %s:%s', newpath, mess, messid);
                end
            end
        end
        
        function filename = findUnusedFileName(path,filepattern, idx)
            % Find an used filename with a given pattern wich includes a
            % '%i' feild for an interger index.
            % [IN]
            %  path - type:string - where the file will live
            %  patttern - type:string - The desired file name with extension.  If it contains a '%i' substring then we
            %             will use sprintf with the 'idx' variable which defaults to 1 to substitue in
            %             The index will be increased until an unused file name in that directory is
            %             found.  If a name with no pattern is given and the file already exists, then
            %             a default file extension of '.v%i', will be added before the actual extension and 
            %             idx will be susbstituted in until an unused name is found.
            %  idx - [optional] type:integer - the starting index for subsitution into the file naame pattern
            %        [default=1]
            % [OUT]
            %   filename - type:string - full path name to the first unsed file name
            %              matching the pattern
            if nargin==2
                idx = 1;
            end
            Pickle.createDirIfNonexistant(path);
            if isempty(strfind(filepattern,'%i'))
                filename = fullfile(path,filepattern);
                if ~exist(filename,'file')
                    return %Got it!
                else
                    [path,basename,ext] = fileparts(filename);
                    filepattern = [basename '.v%i' ext]; %Try adding a '.v1' etc., to distinguish names
                end
            end
            filename = fullfile(path,sprintf(filepattern,idx));
            while exist(filename,'file')
                idx = idx+1;
                filename = fullfile(path,sprintf(filepattern,idx));
            end
        end

        function filepath = selectUnusedFileName(path,filepattern,formats,title)
            % [IN]
            %  path - the full path to the directory.  Will be created if non-exstant
            %  filepattern - A suggested filename with extensions with an optional %i substituion as in 
            %                the Pickle.findUnusedFileName() method.
            %  formats - The allowable formats in uiputfile format.
            %  title [optional] - The title of the uiputfile window.
            % [OUT]
            %  filepath - The fuyll path to the selected filename.
            if nargin<4
                title = 'Select Save File';
            end
            Pickle.createDirIfNonexistant(path);
            savename = Pickle.findUnusedFileName(path,filepattern);
            [file,path] = uiputfile(formats,title,savename);
            if ~file
                filepath = [];
            else
                filepath = fullfile(path, file);
            end
        end

        function filepaths = listExistingFileNames(path,filepattern)
            % [IN]
            %  path - A full path to a directory.  If non existant no files will be returned.
            %  filepattern - A pattern with '*' and '?' charactors as interpreted by the 'dir' function
            % [OUT]
            %  filepaths - Cell array of strings.
            if isempty(filepattern)
                filepaths=[];
                return
            end
            [~,fname,ext] = fileparts(filepattern);
            if isempty(fname) && ~isempty(ext)
                filepattern = ['*' ext]; % If just an extension is given make a pattern for all files of that ext.
            end
            if exist(filepattern,'file') % If any pattern was actually given as full path to a single file, return it            
                filepaths = {filepattern};
            elseif ~exist(path,'dir')
                filepaths = {};
            else
                filelist = dir(fullfile(path,filepattern));
                filepaths = cellmap(@(n) fullfile(path,n), {filelist(:).name});
            end
        end
        
        function filepath = selectExistingFileName(path,filepattern,formats, title, varargin)
            % [IN]
            %  path - the full path to the directory.  Will be created if non-exstant
            %  filepattern - A suggested filename with extensions with * or ? charactors
            %  formats - The allowable formats in uiputfile format.
            %  title [optional] - The title of the uiputfile window.
            % [OUT]
            %  filepath - The full path to the selected filename.
            if nargin<4
                title = 'Load Existing File';
            end
            if ~exist(path,'dir')
                path = pwd();
            end
            names = Pickle.listExistingFileNames(path,filepattern);
            if isempty(names)
                start_name = path;
            else
                start_name = names{1};
            end
            if ~isempty(formats) || isempty(filepattern)
                selectFormats = formats;
            else
                [~,fname,ext] = fileparts(filepattern);
                if isempty(fname) && ~isempty(ext)
                    filepattern = ['*' ext]; % If just an extension is given make a pattern for all files of that ext.
                end
                selectFormats = [{filepattern,sprintf('Suggested File Pattern (%s)',filepattern)}; formats];
            end
            [file,path] = uigetfile(selectFormats,title,start_name,varargin{:});
            if isscalar(file) && ~file
                filepath = [];
            else
                files = makecell(file);
                filepath = cellmap(@(f) fullfile(path,f), files);
            end
            if iscell(filepath) && isscalar(filepath)
                filepath = filepath{1};
            end
        end

        function filepaths = selectBatchProccesingFileNames(path,filepattern,formats, title)
            % Select 1 or more files for batch processing
            % [IN]
            %  path - the full path to the directory.  Will be created if non-exstant
            %  filepattern - A suggested filename with extensions with * or ? charactors
            %  formats - The allowable formats in uiputfile format.
            %  title [optional] - The title of the uiputfile window.
            % [OUT]
            %  filepath - Cell array of the full paths to all selected files.
            if nargin<4
                title = 'Select File(s) for Batch Processing';
            end
            if ~exist(path,'dir')
                error('Pickle:selectExistingFileName','Path does not exist: "%s"',path);
            end
            if ischar(filepattern) % Add a '*' if only an extenstion was given
                [p,name, ext] = fileparts(filepattern);
                if isempty(name) && ~isempty(ext)
                    name = '*';
                end
                if ~isempty(p)
                    path = p;
                end
                filepattern = [name,ext];
            end
            names = Pickle.listExistingFileNames(path,filepattern);
            filepaths = {};
            if ~isempty(names)
                selectFormats = [{filepattern,'Suggested File Pattern'}; formats];
                [files,path] = uigetfile(selectFormats,title,fullfile(path,filepattern),'Multiselect','on');
                if isscalar(files)
                    return;
                elseif ischar(files)
                    filepaths = {fullfile(path, files)};
                else
                    filepaths = cellmap(@(f) fullfile(path,f), files);
                end
            end
        end
        function newfs = changeFileExtensions(fs, new_ext)
            % new_ext is a string with a '.ext' format
            function nf = changeExt(f)
                [path,base,~] = fileparts(f);
                nf = fullfile(path,[base, new_ext]);
            end
            newfs = cellmap(@changeExt, fs);
        end
        
        function overwrite = confirmOverwriteDialog(fileList)
            % Make a dialog to ask user if it is okay to batch overwrite fiales. 
            % [in]
            %  fileList - optional list of files to check if any exists in which case we should ask
            %
            % [out]
            % overwrite - boolean, true if it is OK with user to nuke the files.
            if nargin==1 && ~isempty(fileList) && ~any(cellfun(@(f) exist(f,'file'), makecell(fileList)))
                overwrite = false; % The file list is nonempty and none of the files exists
            else %otherwise ask user
                msg = sprintf('WARNING: This will overwrite %s files.  This is irreversible.\n You can Force the overwrite of these files, or keep the existing files and only batch process the missing files.',Pickle.saveFileExt);
                title = 'WARNING: Batch Processing Will Overwrite Data';
                response = questdlg(msg,title,'Force Overwrite All Files','Keep Existing Files', 'Quit Now', 'Keep Existing Files');
                switch response
                    case 'Keep Existing Files'
                        overwrite = false;
                    case 'Force Overwrite All Files'
                        overwrite = true;
                    otherwise
                        error('Pickle:OverwriteCancel','Overwrite Canceled');
                end
            end
        end

    end
end %classdef
