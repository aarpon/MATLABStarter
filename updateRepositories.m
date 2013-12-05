function updateRepositories( allDirs )
% This function updates the svn and git repositories found in allDirs
%
% SYNOPSIS
%
%   updateSVNrepositories( allDirs )
%
% INPUT
%
%   allDirs : cell array of full folder names
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

if nargin ~= 1
    error( 'One input parameter expected.' );
end

if ~iscell( allDirs )
    error( 'allDirs must be a cell array.' );
end

% svn and git installed?
% =========================================================================

existSVN = true;
[ status, err ] = system( 'svn' );
if status == 127
    existSVN = false;
end

existGIT = true;
[ status, err ] = system( 'git' );
if status == 127
    existGIT = false;
end

% Perform the svn updates
% =========================================================================

% Now svn update all directories that are svn working copies
report = cell( 1, 2 );
counter = 0;
errors = 0;

fprintf(1, 'Please wait while the code repositories are updated...' );
for i = 1 : numel( allDirs )
    
    % Is the dir a working copy?
    subDirs = dir( allDirs{ i } );
    
    isSVN = false;
    isGIT = false;
    
    for j = 1 : numel( subDirs )
        dirname = subDirs( j ).name;
        if existSVN == true && ...
                strcmp(  dirname, '.svn' ) || strcmp(  dirname, '_svn' )
            isSVN = true;
            break;
        elseif existGIT && strcmp(  dirname, '.git' )
            isGIT = true;
            break;
        else
            % Keep going
        end
    end
    
    if isSVN == true
        
        % Run an svn update (non interactively)
        eval(['[ status, err ] = system( ''svn update "', ...
            allDirs{ i },'" --non-interactive --trust-server-cert'' );' ] );
        
        % Something went wrong?
        if status == 1
            
            % Cleanup if needed
            if ~isempty( strfind( err, 'locked' ) ) || ...
                    ~isempty( strfind( err, 'delete-entry' ) )
                eval(['[ status, err ] = system( ''svn cleanup "', ...
                    allDirs{ i },'"'' );' ] );
                if status == 1
                    % Try again to run an svn update (non interactively)
                    eval( ...
                        ['[ status, err ] = system( ''svn update "', ...
                        allDirs{ i }, '" --non-interactive'' ', ...
                        ' --trust-server-cert'' );' ] );
                end
            end
            
            % Check whether authorization was successful
            if ~isempty( strfind( err, 'authorization failed' ) ) || ...
                ~isempty( strfind( err, 'verification failed' ) )
                errors = 1;
            end
            
            % Check whether the user has write permission
            if ~isempty( strfind( err, 'Permission denied' ) ) || ...
                    ~isempty( strfind( err, 'forbidden' ) )
                errors = 1;
            end
            
        end
        
        % Store the outputs
        counter = counter + 1;
        report{ counter, 1 } = allDirs{ i };
        report{ counter, 2 } = err;
    
    end
    
    if isGIT == true
        % Run a git pull
        if ispc
            sep = ' & ';
        else 
            sep = '; ';
        end
        eval(['[ status, err ] = system( ''cd /D "', ...
                allDirs{ i }, '"', sep, 'git pull'');']);
        
        % Something went wrong?
        if status ~= 0

            % TODO: try intercepting it
            
        end
        
        % Store the outputs
        counter = counter + 1;
        report{ counter, 1 } = allDirs{ i };
        report{ counter, 2 } = err;

        
    end
    
end

% =========================================================================
%
% CREATE A LOG
%
% =========================================================================

% Directory where to store the file
OUTPUTDIR=getenv('TMP');
if isempty(OUTPUTDIR)
    OUTPUTDIR=getenv('TEMP');
    if isempty(OUTPUTDIR)
        OUTPUTDIR=getenv('HOME');
        if isempty(OUTPUTDIR)
            OUTPUTDIR=pwd;
        end
    end
end

% Prepare report
tmpfile=[OUTPUTDIR,filesep,'update_log.txt'];

nolog = false;
fid=fopen(tmpfile,'w');
if fid==-1
    fid = 1;
    nolog = true;
end

% Write to log
for counter = 1 : size( report, 1 );
    fprintf( fid, 'Update of %s:\n%s\n',report{ counter, 1 }, ...
        report{ counter, 2 } );
end

% Close file
fclose( fid );

if nolog == false
    if errors == 0
        msg = [ ' Done (<a href="file:///',tmpfile,'">details</a>).' ];
    else
        fprintf( 1, '\n' );
        msg = [ 'WARNING: some operations did not complete ', ...
            'successfully (<a href="file:///',tmpfile,'">details</a>).' ];
    end
else
    msg = ' Done.';
end

disp( msg );
