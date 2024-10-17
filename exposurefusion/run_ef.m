#! /usr/bin/octave -qfW
%%% Read, write images and run exposure_fusion with Octve (or Matlab).
%%% Charles Hessel, CMLA, ENS Paris-Saclay.
%%% Created on July 23, 2018.

%%% If Octave, load package and get arg_list with argv. Use varargin in Matlab
if exist('OCTAVE_VERSION', 'builtin')
  pkg load image
  arg_list = argv();
else
  %%% With Matlab, replace the first line by
  %%% function run_ef (varargin)
  arg_list = varargin;
end

%%% Add files to path (so that script can be called from outside its directory)
[scriptPath, scriptName, scriptExt] = fileparts(mfilename('fullpath'));
addpath( scriptPath )
addpath([scriptPath '/exposureFusion'])

%%% Read/Check parameters
usage = sprintf( [...
  '%s/%s%s Wc Ws We SCB Wsat Bsat image0 [image1 image2 ... imageN]\n' ...
  '- Wc: weight given to the contrast measure in [0,1]\n' ...
  '- Ws: weight given to the saturation measure in [0,1]\n' ...
  '- We: weight given to the well-exposedness measure in [0,1]\n' ...
  '- SCB: clip or normalize the fused image\n' ...
  '       - if 0, clip out-of-range values;\n' ...
  '       - if 1, apply robust normalization with parameters Wsat and Bsat\n'...
  '- Wsat: maximal percentage of white-saturated pixels (when SCB=1)\n' ...
  '- Bsat: maximal percentage of black-saturated pixels (when SCB=1)\n' ...
  '- image0: first and mandatory image of the sequence\n' ...
  '- image1..imageN: (optional) following images of the sequence.'], ...
  scriptPath, scriptName, scriptExt );

if nargin < 8, error('Missing argument(s).\nUsage:\n%s\n', usage);
else
  Wc = str2double(arg_list{1});         % weight for contrast
  Ws = str2double(arg_list{2});         % weight for saturation
  We = str2double(arg_list{3});         % weight for well-exposedness
  SCB  = str2double(arg_list{4});       % Simplest Color Balance or Clipping
  Wsat = str2double(arg_list{5});       % percentage of white saturation
  Bsat = str2double(arg_list{6});       % percentage of black saturation
end

%%% load braketed exposure sequence
fprintf('=== Reading the input images ');
tic
N = nargin - 6;                                 % number of input images
J = imread(arg_list{7});                        % load the (mandatory) 1st image
imwrite(J,'input_0.png');                       % save image for IPOL
[H,W,D] = size(J);                              % get size of images
I = cat(4,im2double(J),zeros(H,W,D,N-1));       % allocate memory of 4D array I
for n = 2:N                                     % load the N-1 remaining images
  J = imread(arg_list{6+n});                            % load image
  imwrite(uint8(J),sprintf('input_%d.png',n-1));        % save for IPOL
  I(:,:,:,n) = im2double(J);                            % update I
end
fprintf('\t\t(%.3f seconds)\n',toc);

fprintf('=== Applying exposure fusion ');
tic
[R,W] = exposure_fusion(I, [Wc Ws We]);
fprintf('\t\t(%.3f seconds)\n',toc);

fprintf('=== Saving the weights images ');
tic
for n = 1:N
  imwrite(uint8(255*W(:,:,n)),sprintf('input_%d_weights.png',n-1));
end
fprintf('\t\t(%.3f seconds)\n',toc);

if ~SCB
  fprintf('=== Clipping out-of-range values ');
  tic
  %%% Nothing to do here, imwrite will clip in the end.
  fprintf('\t(%.3f seconds)\n',toc);
else
  fprintf('=== Normalizing fused image\n');
  tic
  R = robustNormalization(R, Wsat, Bsat, 1);
  fprintf('\t\t\t\t\t(%.3f seconds)\n',toc);
end

fprintf('=== Saving the fused image ');
tic
imwrite(uint8(255*R),'output.png');
fprintf('\t\t(%.3f seconds)\n',toc);

