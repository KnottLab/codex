function [x1,y1,x2,y2,reg_info] = get_pair_tiles_v2(SI,mask)


[Jx,Jy] = find(mask>0);

maxCorr = 0;
for p = 1:length(Jx)
    
    x = Jx(p);
    y = Jy(p);
    
    for n = 1:size(SI.neighbors{x,y},1)
        
        xt = SI.neighbors{x,y}(n,1);
        yt = SI.neighbors{x,y}(n,2);
        if(isempty(SI.reg_info{x,y,n}))
            continue
        end
        
        if(SI.reg_info{x,y,n}.corr2>maxCorr&&mask(x,y)==1&&mask(xt,yt)==0)
            maxCorr = SI.reg_info{x,y,n}.corr2;
            x1 = x;
            y1 = y;
            x2 = xt;
            y2 = yt;
            reg_info = SI.reg_info{x,y,n};
        end
        
    end
    
end




end