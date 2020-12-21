%UNIS2DOSALL Convert all text file to DOS format
% UNIX2DOSALL(DIRECTORY,DOS2UNIX,EXTENSIONS)
%
% converts all text files in DIRECTORY and its subdirectories 
% with the extensions listed in the cell array EXTENSIONS
% requires the file exchange matlab function FUF
% DOS2UNIX should be set to true or false if supplied and says which direction
% the conversion works.
% the extensions {'c','h','cpp','m'} are used by default if none are supplied
% If no directory is supplied, the current directory is used
%
% example:
% unix2dosall('c:\temp\',true,{'c','m'})
% will convert all files with the extension *.c and *.m from DOS (LF) to UNIX (CR/LF)
% in the directory c:\temp\ and all its subdirectories
%
function unix2dosall(directory,dos2unix,extensions)
if nargin<3
    % default extensions when none supplied
    extensions={'c','h','m'};
end
if nargin<2
        dos2unix=false;             % default is unix to dos
end
if nargin<1
        directory=cd;               % default is current directory
end
if isequal(directory,'.') || isequal(directory,'.\') || isequal(directory,'./') 
    directory=cd;
end
if ~iscell(extensions) && ischar(extensions)
    extensions={extensions};
end
fnames={};
for ii=1:length(extensions);
    fnames=[fnames;fuf([directory '\*.' extensions{ii}],'detail')];
end
fprintf('This will convert  %g  files from Unix to DOS format in directory %s\n',length(fnames),directory)
yn=input('Continue (y/n)? ','s');
if lower(yn)=='y'
    for ii=1:length(fnames);
        disp(fnames{ii})
        unix2dos(fnames{ii},dos2unix);
    end
end
