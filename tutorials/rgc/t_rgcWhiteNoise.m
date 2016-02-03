% t_rgcWhiteNoise
% 
% A tutorial for the isetbio RGC object. A white noise image is created 
% in isetbio as a scene, and the sensor, outer segment and RGC objects are
% computed in response to the scene. 

% (HJ) ISETBIO TEAM, 2014
% (JRG) modified 10/2015

%% Init
ieInit;

%% Compute a Gabor patch scene

% Set up Gabor stimulus using sceneCreate('harmonic',params)
fov = 0.6;

params.meanLuminance = 200;
params.row = 64; params.col = 64;
% params.freq = 6; params.contrast = 1;
% % params.ph  = 0;  params.ang = 0;
% params.row = 64; params.col = 64;
% params.GaborFlag = 0.2; % standard deviation of the Gaussian window

% Create display
display = displayCreate('CRT-Sony-HorwitzLab');

% Set up scene, oi and sensor
scene = sceneCreate('harmonic', params);
scene = sceneSet(scene, 'h fov', fov);
% vcAddObject(scene); sceneWindow;

% These parameters are for other stuff.
params.expTime = 0.01;
params.timeInterval = 0.01;
params.nSteps = 5;     % Number of stimulus frames

%% Initialize the optics and the sensor
oi  = oiCreate('wvf human');
sensor = sensorCreate('human');
sensor = sensorSetSizeToFOV(sensor, fov, scene, oi);

sensor = sensorSet(sensor, 'exp time', params.expTime); 
sensor = sensorSet(sensor, 'time interval', params.timeInterval); 

%% Compute a dynamic set of cone absorptions

% We want to produce a scene video that translates into an oi video that
% becomes a cone absorption video.  At present coneAbsorptions ONLY does
% this using eye movements, not by creating a series of images.  This code
% represents our first effort to produce dynamic scenes.

% We are literally going to recreate a set of scenes with different phase
% positions and produce the scenes, ois, and cone absorptions by the loop.
% The result will be a time series of the cone photon absorptions.
%
% We are reluctant to make scene(:,:,:,t) because we are frightened about
% the size.  But it still might be the right thing to do.  So the code here
% is an experiment and we aren't sure how it will go.

% sceneRGB = zeros([sceneGet(scene, 'size') params.nSteps 3]); % 3 is for R, G, B
% sensorPhotons = zeros([sensorGet(sensor, 'size') params.nSteps]);
% stimulus = zeros(1, params.nSteps);
fprintf('Computing cone isomerization:    \n');

% ieSessionSet('wait bar',true);
wFlag = ieSessionGet('wait bar');
if wFlag, wbar = waitbar(0,'Stimulus movie'); end

% Loop through frames to build movie
for t = 1 : params.nSteps
    if wFlag, waitbar(t/params.nSteps,wbar); end
        

    if t == 1 
        stimulusRGBdata = zeros(params.row,params.col,3);
    end

    stimRGBraw = 0.5+(0.25*randn(params.row,params.col,3));
    stimulusRGBdata = floor(254*abs(stimRGBraw)./max(stimRGBraw(:)));

    % % % % Generate scene object from stimulus RGB matrix and display object
    scene = sceneFromFile(stimulusRGBdata, 'rgb', params.meanLuminance, display);

    scene = sceneSet(scene, 'h fov', fov);

    % Get scene RGB data    
    sceneRGB(:,:,t,:) = sceneGet(scene,'rgb');
    
    % Compute optical image
    oi = oiCompute(oi, scene);    
    
    % Compute absorptions
    sensor = sensorCompute(sensor, oi);

    if t == 1
        volts = zeros([sensorGet(sensor, 'size') params.nSteps]);
    end
    
    volts(:,:,t) = sensorGet(sensor, 'volts');
    
    % vcAddObject(scene); sceneWindow
end

if wFlag, delete(wbar); end

% Set the stimuls into the sensor object
sensor = sensorSet(sensor, 'volts', volts);
% vcAddObject(sensor); sensorWindow;


%% Movie of the cone absorptions over cone mosaic
% from t_VernierCones by HM

step = 1;   % Step is something about time?
% Display gamma preference could be sent in here
tmp = coneImageActivity(sensor,[],step,false);

% Show the movie
vcNewGraphWin;
tmp = tmp/max(tmp(:));
for ii=1:size(tmp,4)
    img = squeeze(tmp(:,:,:,ii));
    imshow(img); truesize;
    title('Cone absorptions')
    drawnow
end
close;
%% Outer segment calculation

% Input = RGB
os = osCreate('identity');
os = osSet(os, 'rgbData', sceneRGB);

% % Plot the photocurrent for a pixel
% osPlot(os,sensor);

%% Build rgc

% rgc1 = rgcCreate('GLM', scene, sensor, os, 'right', 3.0, 180);
clear params

% params = rgcParams('linear');

% params.sensor = absorptions;
params.name    = 'Macaque inner retina 1'; % This instance
params.model   = 'glm';    % Computational model
params.row     = sensorGet(sensor,'row');  % N row samples
params.col     = sensorGet(sensor,'col');  % N col samples
params.spacing = sensorGet(sensor,'width','um'); % Cone width
params.timing  = sensorGet(sensor,'time interval','sec'); % Temporal sampling
params.eyeSide   = 'left';   % Which eye
params.eyeRadius = 5;        % Radium in mm
params.eyeAngle  = 90;       % Polar angle in degrees

% Coupled GLM model for the rgc (which will become innerRetina
% Push this naming towards innerR.  
% We should delete the 'input' because we could run the same rgc
% object with different inputs
% We should reduce dependencies on the other objects
% We should clarify the construction of the different mosaics
rgc1 = rgcCreate(params);for cellTypeInd = 1:5%length(obj.mosaic)
    % params.cellTypeInd = cellTypeInd;
    % rgcSet(rgc1, 'mosaic', rgcMosaicLinear(rgc1));
    rgcSet(rgc1, 'mosaic', rgcMosaicGLM(rgc1));
end
rgc1 = rgcCompute(rgc1, os);

% rgcPlot(rgc1, 'mosaic');
% rgcPlot(rgc1, 'linearResponse');
% rgcPlot(rgc1, 'rasterResponse');
rgcPlot(rgc1, 'psthResponse');
%% Build rgc response movie
%  https://youtu.be/R4YQCTZi7s8

% % osLinear
% rgcMovie(rgc1, sensor);

% % osIdentity
% rgcMovie(rgc1, os);