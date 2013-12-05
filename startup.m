function startup
% Creates current's user path structure and updates svn/git repositories
%
% This function is launched by MATLAB at startup.
%
% SYNOPSIS
%
%   startup
%
% INPUT
%
%   none
%
% OUTPUT
%
%   none

% This file is part of MATLABStarter
%
% MATLABStarter is released under the terms of the Lesser GPL license
% version 3.0: http://www.gnu.org/licenses/lgpl-3.0.txt
%
% Copyright Aaron Ponti 2011 - 2013

% Set environment variables
% =========================================================================

if exist('envvars.m', 'file')
    envvars;
end

% Make sure to restore the default search path
% =========================================================================

try
    % Change to a non UNC path (to prevent problems in Windows), and then
    % restore and save the default path before we build the dynamic path
    cd( matlabroot )
    warning off
    restoredefaultpath;
    warning on
    savepath;
catch %#ok<CTCH> For back-compatibility
end

% Get all environment variables
% =========================================================================

% MATLABHOME must be defined and point to a valid directory
home = getenv( 'MATLABHOME' );
if isempty(home)
    disp( [ 'Error: the environment variable ''MATLABHOME'' ', ...
        'was not set.' ] );
    disp( [ 'Only MATLAB''s standard functions and toolboxes ', ...
        'will be accessible for this session.' ] );
    return
end
if exist( home, 'dir' ) == 0
    disp( [ 'Error: the directory specified by the environment ', ...
        'variable ''MATLABHOME'' does not exists!' ] );
    disp( [ 'Only MATLAB''s standard functions and toolboxes ', ...
        'will be accessible for this session.' ] );
    return    
end

% MATLABUSERFOLDER is optional but if set it must point to a valid 
% directory
userFolder = getenv( 'MATLABUSERFOLDER' );
if ~isempty( userFolder )
    if exist( userFolder, 'dir' ) == 0
        disp( [ 'Error: the directory specified by the environment ', ...
            'variable ''MATLABUSERFOLDER'' does not exists!' ] );
        % Set to empty so that it is ignored later
        userFolder = [ ];
    end
end

% XTENSIONS is ignored in all platform but in Windows, where it is optional
%   Remark: for historical reasons, the addition of ImarisXT extensions 
%   can be turned off explicitly by setting the environment variable 
%   XTENSIONS to 'DISABLE'.
if ispc
    XTensions = getenv( 'XTENSIONS' );
    if isempty(XTensions)
        % Ignore
        XTensions = 'DISABLE';
    end
    if strcmpi( XTensions, 'DISABLE' ) == 0
        if exist( XTensions, 'dir' ) == 0
            disp( ...
                [ 'Error: the directory specified by the environment ', ...
                'variable ''XTENSIONS'' does not exists!' ] );
            disp( [ 'Calling MATLAB accessory functions from Imaris ', ...
                'will not be possible.' ] );
        end
    end
else
    XTensions = 'DISABLE';
end

% IMARISPATH is ignored in Linux, and otherwise optional
xtPath = '';
if ispc || ismac
    ImarisPath = getenv( 'IMARISPATH' );
    if ~isempty(ImarisPath)
        if exist( ImarisPath, 'dir' ) == 0
            disp( ...
                [ 'Error: the directory specified by the environment ', ...
                'variable ''IMARISPATH'' does not exists!' ] );
            disp( [ 'Calling MATLAB accessory functions from Imaris ', ...
                'will not be possible.' ] );
            ImarisPath = '';
        end
    end
    
    % is XTENSIONS defined and valid?
    isXTENSIONSdefined = exist('XTensions', 'var' ) && ...
            strcmp(XTensions, 'DISABLE') == 0;
        
    % Set directory for automatic update of ImarisXT extension if needed
    if isXTENSIONSdefined == 0 && ~isempty(ImarisPath)
        if ispc
            xtPath = fullfile( ImarisPath, 'XT', 'matlab' );
        elseif ismac
            xtPath = fullfile( ImarisPath, 'Contents', 'SharedSupport', ...
                'XT', 'matlab' );
        else
            xtPath = '';
        end
        
        % Check the full path
        if ~isempty( xtPath )
            if exist( xtPath, 'dir' ) == 0
                disp( ...
                    [ 'Error: could not find the XT/matlab Imaris ', ...
                    'subfolder. Expected path: ' ] );
                disp( xtPath );
                xtPath = '';
            end
        end
        
    end
    
end


% =========================================================================
%
% Build the list of directories to be updated
%
% If the passed folder is an svn working copy we add it and do not recurse
% If it is not a working copy, we get the list of first-level subfolders
%
% =========================================================================

% Add MATLABHOME with all its level-one subdirs 
% =========================================================================

allDirs = getSubfolderDir( home );

% Add XTENSIONS if needed
% =========================================================================

if strcmp( XTensions, 'DISABLE' ) == 0
    allDirs = cat( 2, allDirs, { XTensions } );
end

% Add IMARISPATH/{platform_dependent}/XT/matlab (xtPath) if needed
% =========================================================================

if ~isempty(xtPath)
    allDirs = cat( 2, allDirs, { xtPath } );
end

% Add MATLABUSERFOLDER if needed
% =========================================================================

if ~isempty( userFolder )
    allDirs = cat( 2, allDirs, getSubfolderDir( userFolder ) );
end

% Add also the directory containing this function -- which might be
% read-only for normal users, so additional care should be taken below
% (this is also a full path)
% =========================================================================

% Add also the directory containing this function 
startupDirName = fileparts( which( mfilename ) );
if ~isempty( startupDirName )
    allDirs = cat( 2, allDirs, { startupDirName } );
end

% Update all svn and git repositories
% =========================================================================

if exist( 'updateRepositories.m', 'file' ) == 2
    updateRepositories( allDirs );
end

% =========================================================================
%
% Now build dynamic path
%
% =========================================================================

fprintf( 1, [ 'Please wait while the dynamic MATLAB and JAVA ', ...
    'paths are built...' ] );

% MATLABHOME
% =========================================================================

success = addToPath( home );
if success == 0
    disp( [ 'Error: could not create the dynamic MATLAB path ', ...
        'specified by the environment variable ''MATLABHOME''.' ] );
    disp( [ 'Only MATLAB''s standard functions and toolboxes ', ...
        'will be accessible for this session.' ] );
    disp( [ 'Please <a href="mailto:aaron.ponti@fmi.ch">report</a> ', ...
        'this problem.' ] );
    return
end

% User path
% =========================================================================

if ~isempty( userFolder )
    success = addToPath( userFolder );
    if success == 0
        disp( [ 'Error: could not create the dynamic MATLAB ', ...
            'path specified by the environment variable ', ...
            '''MATLABUSERFOLDER''.' ] );
        disp( [ 'Please <a href="mailto:aaron.ponti@fmi.ch">', ...
            'report</a> this problem.' ] );
        return
    end
end

% Imaris path
% =========================================================================

if ~isempty( xtPath )
    success = addToPath( xtPath );
    if success == 0
        disp( [ 'Error: could not create the dynamic MATLAB ', ...
            'path specified by the environment variable ', ...
            '''IMARISPATH''.' ] );
        disp( [ 'Please <a href="mailto:aaron.ponti@fmi.ch">', ...
            'report</a> this problem.' ] );
        return
    end
end

% XTENSIONS
% =========================================================================

if strcmpi(  XTensions , 'DISABLE' ) == 0
    success = addToPath( XTensions );
    if success == 0 
        disp( [ 'Error: could not create the dynamic MATLAB path ', ...
            'specified by the environment variable ''XTENSIONS''.' ] );
        disp( [ 'Calling MATLAB accessory functions from Imaris ', ...
            'will not be possible.' ] );
        disp( [ 'Please <a href="mailto:aaron.ponti@fmi.ch">', ...
            'report</a> this problem.' ] );
    end
end

% Inform
fprintf( 1, ' Done.\n' );

% Now enter MATLABUSERFOLDER if defined, or MATLABHOME
if ~isempty( userFolder )
    cd( userFolder );
    % If a file called startup_user.m exists in the MATLABUSERFOLDER, 
    % then launch it (since we changed the the MATLABUSERFOLDER, the
    % function -- if it exists -- will run from here and shadow possible
    % other functions with the same name somewhere else in the path).
    startupUserFile = fullfile( userFolder, 'startup_user.m' );
    if exist( startupUserFile, 'file' ) == 2
        fprintf( 1, ...
            'Please wait while the user''s statup file is executed...' );
        startup_user;
        fprintf( 1, ' Done.\n' );
    end 
else
    cd( home );
end

% Inform about the MATLABUSERFOLDER option
fprintf( 1, [ '\n   WARNING: Do NOT save the MATLAB path!\n', ...
    '   If you want to work with your code on shared machines, ', ...
    'follow the user\n   configuration instructions at ', ...
    'http://www.scs2.net/next/index.php?id=130.\n\nReady.\n\n' ] );

% =========================================================================
% =========================================================================

function allDirs = getSubfolderDir( folder )

if exist( folder, 'dir' ) == 0
    allDirs = {};
    return;
end

% If folder is a subversion working copy, we just return it
if ( exist( [ folder, filesep, '.svn' ], 'dir' ) || ...
        exist( [ folder, filesep, '_svn' ], 'dir' ) )
    allDirs{ 1 } = folder;
    return
end

% Get list of subdirectories
subdirs = dir( folder );
subdirs( [ subdirs.isdir ] == 0 ) = [];
nDirs = numel( subdirs );
% Allocate space for all directories to be updated (or at least checked)
allDirs = cell( 1, nDirs - 2 );
c = 0;
for i = 1 : nDirs
    if strcmp( subdirs( i ).name, '..' ) == 0 && ...
            strcmp( subdirs( i ).name, '.' ) == 0
        % Add only if a a subfolder '.svn' or '_svn' exists
        currDirName = [ folder, filesep, subdirs( i ).name ];
        if ( exist( [ currDirName, filesep, '.svn' ], 'dir' ) || ...
                exist( [ currDirName, filesep, '_svn' ], 'dir' ) || ...
                exist( [ currDirName, filesep, '.git' ], 'dir' ) )
            c = c + 1;
            allDirs{ c } = currDirName;
        end
    end
end
allDirs = allDirs( 1 : c );

% =========================================================================

function success = addToPath( folder )

success = 1;

try
    
    % This is the modified version of genpath
    [ MATLABPATH, JAVAPATH ] = cgenpath( folder );
    
    % Add dynamic MATLAB path
    addpath( MATLABPATH );
    
    % Add dynamic JAVA path
    javaaddpath( JAVAPATH );
    
catch
    
    success = 0;
    
end

