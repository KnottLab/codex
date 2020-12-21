function [H,E,BG] = deconvolve(I)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deconvolve: Deconvolution of an RGB image into its constituent stain
% channels
% 
%
% Input:
% I         - RGB input image.
% M         - (optional) Stain matrix. 
%                        (default Ruifrok & Johnston H&E matrix)
%
%
% Note: M must be an 2x3 or 3x3 matrix, where rows corrrespond to the stain
%       vectors. If only two rows are given the third is estimated as a
%       cross product of the first two.
%
%
% Output:
% DCh       - Deconvolved Channels concatatenated to form a stack. 
%             Each channel is a double in Optical Density space.
% M         - Stain matrix.
%
%
% References:
% [1] AC Ruifrok, DA Johnston. "Quantification of histochemical staining by
%     color deconvolution". Analytical & Quantitative Cytology & Histology,
%     vol.23, no.4, pp.291-299, 2001.
%
%
% Acknowledgements:
% This function is inspired by Mitko Veta's Stain Unmixing and Normalisation 
% code, which is available for download at Amida's Website:
%     http://amida13.isi.uu.nl/?q=node/69
%
%
% Example:
%           I = imread('hestain.png');
%           [ DCh, H, E, Bg, M ] = Deconvolve( I, [], 1);
%
%
% Copyright (c) 2013, Adnan Khan
% Department of Computer Science,
% University of Warwick, UK.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

I = double(I);

%% Sanity check
[n,p,~] = size(I);

%% Default Color Deconvolution Matrix proposed in Ruifork and Johnston
M = [0.644211 0.716556 0.266844; 
     0.092789 0.954111 0.283111;];

% This stain vector is obtained as the cross product of first two
% stain vectors 
M = [M; cross(M(1, :), M(2, :))];

% Normalise the input so that each stain vector has a Euclidean norm of 1
M = (M./repmat(sqrt(sum(M.^2, 2)), [1 3]));


%% MAIN IMPLEMENTATION OF METHOD

% the intensity of light entering the specimen (see section 2a of [1])


% Vectorize
J = reshape(I, [], 3);

% calculate optical density
Y = -log((J+1)/255);



% determine concentrations of the individual stains
% M is 3 x 3,  Y is N x 3, C is N x 3
% Y = exp(-(Y*M));
% Y(Y>1)=1;
% C=1-Y;

% determine concentrations of the individual stains
% M is 3 x 3,  Y is N x 3, C is N x 3
C = Y / M;

C(C<0) = 0;
C(C>2) = 2;
C = C/2;
% determine concentrations of the individual stains
% M is 3 x 3,  Y is N x 3, C is N x 3
% C = Y * pinv(M);



% Stack back deconvolved channels
DCh = reshape(C,n,p,3);
H = DCh(:,:,1);
E = DCh(:,:,2);
BG = DCh(:,:,3);

end
