function Xn = normalize_nuclei_frames_colors(Xn) 


disp('normalize nuclei frames colors ...')


%% target distribution
mu = mean(Xn,[1 2 4]); mu = permute(mu,[1 3 2]);
sd = std(double(Xn),[],[1 2 4]); sd = permute(sd,[1 3 2]);


%% 
Xt = reshape(Xn,[size(Xn,1)*size(Xn,2) size(Xn,3) size(Xn,4)]);


%%
MS = mean(Xt,1);
SD = std(double(Xt),[],1);


%% 
MS = repmat(MS,[size(Xt,1) 1 1]);
SD = repmat(SD,[size(Xt,1) 1 1]);

mu = repmat(mu,[size(Xt,1) 1 size(Xt,3)]);
sd = repmat(sd,[size(Xt,1) 1 size(Xt,3)]);


%% normalization
Xt = uint8( (double(Xt)-MS).*sd./SD + mu );


%%
Xn = reshape(Xt,size(Xn)); 


end

