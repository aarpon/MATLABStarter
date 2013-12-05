function [ p, javapath ] = cgenpath( d )
% Adds MATLAB files, Java folders and jar archives recursively to the path
%
% SYNOPSIS
%
%   [ p, javapath ] = cgenpath( d )
%
% All subdirectories (including empty directories) starting at d are
% added to the path p; moreover, all subdirectories containing java
% classes or .jar packages are returned in javapath.  Subversion and git
% hidden directories (.svn, .git) are ignored.
%
% INPUT
%
%   d  : path to the folder to be scanned.
%
% OUTPUT
%
%   p       : path string in the form 'path1;path2;path3;...' that can
%             be passed as an input parameter to ADDPATH
%
%   javapath: cell array of strings that can be passed as input parameter
%             to JAVAADDPATH
%
%   This function is heavily inspired by genpath.m, Copyright 1984-2004
%   The MathWorks, Inc. $Revision: 1.13.4.3 $ $Date: 2004/03/17 20:05:14 $

% This file is part of MATLABStarter
%
% MATLABStarter is released under the terms of the Lesser GPL license
% version 3.0: http://www.gnu.org/licenses/lgpl-3.0.txt
%
% Copyright Aaron Ponti 2011 - 2013

if nargin ~= 1,
    error( 'CGENPATH only accepts one input argument.' );
end

% Initialise variables
p         = '';  % path to be returned
javapath  = {};  % dynamic java path to be returned

% Generate path based on given root directory
files = dir( d );
if isempty( files )
    return
end

% Add d to the paths even if it is empty.
p = [ p d pathsep ];

% Set logical vector for subdirectory entries in d
isdir = logical( cat( 1, files.isdir ) );

% Recursively descend through directories which are neither
% private nor "class" directories. Also '.svn', '.git' directories and
% package directories are ignored.
dirs = files( isdir ); % select only directory entries from current list

for i = 1 : length( dirs )
    
    dirname = dirs( i ).name;
    if ~strcmp(  dirname, '.' )              && ...
            ~strcmp(  dirname, '..' )        && ...
            ~strcmp(  dirname, '.svn' )      && ...
            ~strcmp(  dirname, '_svn' )      && ...
            ~strcmp(  dirname, '.git' )      && ...
            ~strncmp( dirname, '@', 1 )      && ...
            ~strncmp( dirname, '+', 1 )      && ...
            ~strcmp(  dirname, 'autosave' )  && ...
            ~strcmp(  dirname, 'private' )
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Construct dynamic JAVA PATH recursively
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Absolute path
        apath = fullfile( d, dirname );
        
        % Check wheter this directory contains *.jar or *.class files, if
        % so, add the directory to the java path
        thisDir = dir( apath );
        indx    = find( ~logical( cat( 1, thisDir.isdir ) ) );
        nfiles  = numel( indx );
        
        clear currentfiles;
        if nfiles ~= 0
            
            % Get list of files in current directory
            [ currentfiles{ 1 : nfiles } ] = deal( thisDir( indx ).name );
            
            % Check whether there are java files among them
            nClassFiles = 0;
            for j = 1 : numel( currentfiles )
                % JAR files have to be added explicitly
                if ~isempty( strfind( currentfiles{ j }, '.jar' ) )
                    javapath( numel( javapath ) + 1 )= ...
                        { [ apath, filesep, currentfiles{ j } ] };
                end
                % For CLASS files, the directory containing them is added
                if ~isempty( strfind( currentfiles{ j }, '.class' ) )
                    nClassFiles = nClassFiles + 1;
                end
            end
            
            % Add directory if it contains class files
            if nClassFiles ~= 0
                javapath( numel( javapath ) + 1 ) = { apath };
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % End of dynamic JAVA PATH
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Recursive calling of cgenpath
        [ pn, javapathn ] = cgenpath( fullfile( d, dirname ) );
        p = [ p pn ];
        javapath = [ javapath, javapathn ];
    end
    
end

