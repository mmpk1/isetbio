function [data, vObj] = ieMovie(data,varargin)
% Show a movie of an (x,y,t) or (x,y,c,t) matrix
%
%   [mov, vObj] = ieMovie(data,varargin)
% 
%  data:   (row,col,color,time) or (row,col,time) (Required)
%  step:   How many times frames to step over. Default = 1;
%  show:   Display the movie
%  vname:  (video file name)
%  FrameRate: (video frame rate)
%  hf:        Figure for showing data (vcNewGraphWin() by default)
%
% Example:
%   ieMovie(rand(50,50,50));
%   
%   dFlag = true;
%   ieMovie(rand(50,50,50),'dFlag',dFlag);
%
%   dFlag.vname = 'tmp'; dFlag.FrameRate = 5; dFlag.hf = vcNewGraphWin;
%   [mov,vObj] = ieMovie(rand(50,50,50),'step',3,'dFlag',dFlag);
%
%   [mov,vObj] = ieMovie(rand(50,50,3,100),'step',2,'dFlag',dFlag);
%
% ISETBIO Team (BW) 2016


%% Parse inputs
p = inputParser;
p.addRequired('data',@isnumeric);
p.addParameter('vname','',@ischar);
p.addParameter('FrameRate',20,@isnumeric);
p.addParameter('step',1,@isnumeric);
p.addParameter('show',true,@islogical);
p.addParameter('hf',[],@isgraphics);

p.parse(data,varargin{:});
data  = p.Results.data;
step  = p.Results.step;
show  = p.Results.show;
hf    = p.Results.hf;
vname      = p.Results.vname;
FrameRate  = p.Results.FrameRate;

%% Create the movie and video object

vObj = [];

% Could be monochrome or rgb
tDim = ndims(data);
nFrames = size(data, tDim);

% Scale and gamma correct mov
data = ieScale(data,0,1) .^ 0.3;

% show the movie, or write to file
if ~isempty(vname)
    if isempty(hf), vcNewGraphWin;
    else figure(hf);
    end
    axis image
    
    % When dFlag is a struct, show the move and save it in a file
    vObj = VideoWriter(vname);
    vObj.FrameRate = FrameRate;
    open(vObj);
    if isequal(tDim,4)
        % RGB data
        for ii = 1:step:nFrames
            image(data(:,:,:,ii)); drawnow;
            F = getframe; writeVideo(vObj,F);
        end
        close(vObj);
    elseif isequal(tDim,3)
        colormap(gray)
        for ii = 1:step:nFrames
            imagesc(data(:,:,ii)); drawnow;
            F = getframe; writeVideo(vObj,F);
        end
        close(vObj);
    end
elseif show
    % If it is a figure handle, show it in that figure
    if isempty(hf), vcNewGraphWin;
    else figure(hf);
    end
    axis image
    
    if isequal(tDim,4)
        % RGB data
        for ii=1:size(data,tDim)
            imshow(data(:,:,:,ii)); drawnow;
        end
    elseif isequal(tDim,3)
        colormap(gray);
        for ii = 1:nFrames
            imagesc(data(:,:,ii)); drawnow;
        end
    end
end

end




