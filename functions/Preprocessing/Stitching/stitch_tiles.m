function [I,CODEXobj] = stitch_tiles(I,CODEXobj,cl,ch,verbose)
tic


if(ch==1&&cl==1)
    stitching_info = [];
else
    stitching_info = CODEXobj.stitching_info{1};
end



%% %%%%%%%%%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

W = CODEXobj.Width;
w = CODEXobj.width;
D = W - w;

[J,M,V,x0,y0,mask] = stitching_initialization(I,CODEXobj,stitching_info);

if(isempty(stitching_info))
    new_tf = true;
    stitching_info.tile1 = [];
    stitching_info.tile2 = [];
    stitching_info.reg_info = {};
    stitching_info.tform = {};
    stitching_info.V = {};
else
    new_tf = false;
end



%% %%%%%%%%%%%%%%%%%%%%%%%% Stitching %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
k = 1;
while(sum(mask(:)==0)>0)
    
    disp(['stitching: CL=',num2str(cl),' CH=',num2str(ch),' : ',num2str(round(100*(numel(mask)-sum(mask(:)==0))/numel(mask))),'%  : ',CODEXobj.markers2{cl,ch}])
    
    [x1,y1] = get_processed_tile(mask,x0,y0);
    [x2,y2,mask] = get_unprocessed_tile(mask,x1,y1,x0,y0);

    I2 = I(1+(x2-1)*W:x2*W,1+(y2-1)*W:y2*W)+1;
       
    if(new_tf==true)
        
        [tform,V,reg_info] = get_registration_transform(x1,y1,x2,y2,I,I2,W,D,V);

        stitching_info.tile1 = [stitching_info.tile1;[x1 y1]];
        stitching_info.tile2 = [stitching_info.tile2;[x2 y2]];
        stitching_info.reg_info{k} = reg_info;
        stitching_info.tform{k} = tform;
        stitching_info.V{k} = V;

    end
    
    [J,M,I2r] = update_stitching(J,M,I2,stitching_info.V{k},D,w,x2,y2,stitching_info.tform{k},stitching_info.reg_info{k});
    
    if(verbose==1)
        I1 = I(1+(x1(1)-1)*W:x1(1)*W,1+(y1(1)-1)*W:y1(1)*W);
        display_stitching_step(J,CODEXobj,I1,I2,I2r,reg_info,stitching_info.tform{k})
    end

    k = k+1;
    
end



%% Correct missed stitches
% bw = imerode(~imbinarize(imadjust(J)),strel('disk',20));
% % figure,imagesc(imbinarize(imadjust(J)))
% % figure,imagesc(bw)
% 
% % mean(J(bw))
% J(M==0) = mean(J(bw));
% % figure,imagesc(M)
% % cccc


%% Correct Corners
M = (imdilate(M,strel('disk',1))-M)>0;
M = imdilate(M,strel('disk',2));

Jf = imfilter(J,fspecial('average',5));
J(M>0) = Jf(M>0);

I = J;



%%
if(ch==1&&cl==1)
    mkdir(['./figures/1_processing/',CODEXobj.sample_id])
    save_registration_eval_figure(stitching_info,['./figures/1_processing/',CODEXobj.sample_id,'/',CODEXobj.sample_id,'_4_Stitching_cycle_',num2str(cl),'.png'])
end



%%
CODEXobj.stitching_info{cl} = stitching_info;
for j = 1:length(CODEXobj.stitching_info{cl}.reg_info)
    CODEXobj.stitching_info{cl}.reg_info{j}.O1 = [];
    CODEXobj.stitching_info{cl}.reg_info{j}.O2 = [];
    CODEXobj.stitching_info{cl}.reg_info{j}.O2r = [];
end



toc


end






