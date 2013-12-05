function envvars
% Set global environment variables
%
% SYNOPSIS
%
%   envvars
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

% Set the environment variable contents here
% =========================================================================

% MATLABHOME is mandatory for the functioning of MATLABStarter. Make sure
% it is set either here or externally.
% MATLABHOME = '';

% Optional
% XTENSIONS = '';
% IMARISPATH = '';

% Set the variables
% =========================================================================

% MATLABHOME: if you did not define here, make sure it is set as an 
% environment variable elsewhere, or startup will report an error.
if exist('MATLABHOME', 'var')
    setenv('MATLABHOME', MATLABHOME);
end

% XTENSIONS
if exist('XTENSIONS', 'var')
    setenv('XTENSIONS', XTENSIONS);
end

% IMARISPATH
if exist('IMARISPATH', 'var')
    setenv('IMARISPATH', IMARISPATH);
end
