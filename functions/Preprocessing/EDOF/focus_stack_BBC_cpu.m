function im = focus_stack_BBC_cpu(Is)

[M,N,P] = size(Is);

opts.size = [M N P];
opts.alpha = 0.2;
opts.focus = 1:P;
opts.nhsize = 9;
opts.sth = 13;


%********** Compute fmeasure **********
fm = zeros(opts.size);
for p = 1:P
    fm(:,:,p) = gfocus(im2double(Is(:,:,p)), opts.nhsize);
end


%********** Compute Smeasure ******************
[u,s,A,fmax] = gauss3P(opts.focus,fm);

% Aprox. RMS of error signal as sum|Signal-Noise| 
% instead of sqrt(sum(Signal-noise)^2):
err = zeros(M,N);
for p = 1:P
    err = err + abs( fm(:,:,p) - A.*exp(-(opts.focus(p)-u).^2./(2*s.^2)) );
    fm(:,:,p) = fm(:,:,p)./fmax;
end
inv_psnr = imfilter(err./(P*fmax),fspecial('average',opts.nhsize),'replicate');

S = 20*log10(1./inv_psnr);
S(isnan(S)) = min(S(:));

phi = 0.5*(1+tanh(opts.alpha*(S-opts.sth)))/opts.alpha;
if(sum(isnan(phi(:)))==0)
    
    phi = medfilt2(phi, [3 3]);
    
    
    %********** Compute Weights: ********************
    fun = @(phi,fm) 0.5 + 0.5*tanh(phi.*(fm-1));
    for p = 1:P
        fm(:,:,p) = feval(fun, phi, fm(:,:,p));
    end
    
    
    %********* Fuse images: *****************
    fmn = sum(fm,3); %(Normalization factor)
    im = uint16(sum((double(Is).*fm),3)./fmn);
    
else
    
    im = gather(zeros(size(Is,1),size(Is,2),1,'uint16'));
    
end


end











%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [u,s,A,Ymax] = gauss3P(x,Y)
% Fast 3-point gaussian interpolation

STEP = 2; % Internal parameter

[M,N,P] = size(Y);

[Ymax,I] = max(Y,[],3);

[IN,IM] = meshgrid(1:N,1:M);

Ic = I(:);
Ic(Ic<=STEP)=STEP+1;
Ic(Ic>=P-STEP)=P-STEP;

Index1 = sub2ind([M,N,P], IM(:), IN(:), Ic-STEP);
Index2 = sub2ind([M,N,P], IM(:), IN(:), Ic);
Index3 = sub2ind([M,N,P], IM(:), IN(:), Ic+STEP);

Index1(I(:)<=STEP) = Index3(I(:)<=STEP);
Index3(I(:)>=STEP) = Index1(I(:)>=STEP);

x1 = reshape(x(Ic(:)-STEP),M,N);
x2 = reshape(x(Ic(:)),M,N);
x3 = reshape(x(Ic(:)+STEP),M,N);

y1 = reshape(log(Y(Index1)),M,N);
y2 = reshape(log(Y(Index2)),M,N);
y3 = reshape(log(Y(Index3)),M,N);

c = ( (y1-y2).*(x2-x3)-(y2-y3).*(x1-x2) )./...
    ( (x1.^2-x2.^2).*(x2-x3)-(x2.^2-x3.^2).*(x1-x2) );

b = ( (y2-y3)-c.*(x2-x3).*(x2+x3) )./(x2-x3);

s = sqrt(-1./(2*c));

u = b.*s.^2;

a = y1 - b.*x1 - c.*x1.^2;

A = exp(a + u.^2./(2*s.^2));

end








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute focus measure using graylevel local variance
function FM = gfocus(I, WSize)

h = fspecial('average',[WSize WSize]);

If = imfilter(I,h,'replicate');

FM = (I-If).^2;

FM = imfilter(FM, h, 'replicate');

end







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function options = parseInputs(imlist, varargin) 
% 
% % Determine image size and type:
% im = imread(imlist{1});
% options.RGB = (ndims(im)==3);
% M = size(im, 1);
% N = size(im, 2);
% P = length(imlist);
% options.size = [M, N, P];
% 
% input_data = inputParser;
% input_data.CaseSensitive = false;
% input_data.StructExpand = true;
% 
% input_data.addOptional('alpha', 0.2, @(x) isnumeric(x) && isscalar(x) && (x>0) && (x<=1));
% input_data.addOptional('focus', 1:P, @(x) isnumeric(x) && isvector(x));
% input_data.addOptional('nhsize', 9, @(x) isnumeric(x) && isscalar(x));
% input_data.addOptional('sth', 13, @(x) isnumeric(x) && isscalar(x));
% 
% parse(input_data, varargin{:});
% 
% options.alpha = input_data.Results.alpha;
% options.focus = input_data.Results.focus;
% options.nhsize = input_data.Results.nhsize;
% options.sth = input_data.Results.sth;
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




