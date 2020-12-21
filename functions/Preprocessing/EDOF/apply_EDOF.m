function I = apply_EDOF(CODEXobj,cl,ch,proc_unit)


tic

k = 1;
I = [];
for x = 1:CODEXobj.Nx
    It = [];
    if(mod(x,2)==0); Jy = CODEXobj.Ny:-1:1; else; Jy = 1:CODEXobj.Ny; end
    for y = Jy
        
        disp(['EDOF:  ',CODEXobj.markers2{cl,ch},'  : CL=',num2str(cl),' CH=',num2str(ch),' X=',num2str(x),' Y=',num2str(y),' | ',num2str(round(100*k/(CODEXobj.Nx*CODEXobj.Ny))),'%'])
        
        Is = zeros(CODEXobj.Width,CODEXobj.Width,CODEXobj.Nz);
        for z = 1:CODEXobj.Nz
            im = read_tile_at_Z(CODEXobj,cl,ch,x,y,z);
            Is(:,:,z) = im;            
        end
        
        
        if(strcmp(proc_unit,'GPU'))
            im = focus_stack_BBC_gpu(Is);
        else 
            im = focus_stack_BBC_cpu(Is);
        end
        
        
        It = [It im];
        
        k = k+1;
    end
    I = [I;It];
end


toc


end







