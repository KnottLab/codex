function [CODEXobj,I] = background_subtraction_v6(CODEXobj,I,BG1,BG2,r,cl,ch)

disp('Background Subtraction ...')
tic



%%
BG1 = BG1{ch}; 
Jp = BG1>I;
BG1(Jp) = I(Jp);

BG2 = BG2{ch}; 
Jp = BG2>I;
BG2(Jp) = I(Jp);


%%
Jp = I>0&BG1>0&BG2>0;


%%
radius = 1;
I = imclose(I,strel('disk',radius));
BG1 = imclose(BG1,strel('disk',radius));
BG2 = imclose(BG2,strel('disk',radius));


%%
radius = 5;
I = imtophat(I,strel('disk',radius));
BG1 = imtophat(BG1,strel('disk',radius));
BG2 = imtophat(BG2,strel('disk',radius));


%%
a = (CODEXobj.Ncl-cl-1)/(CODEXobj.Ncl-3);
b = 1-a;

I = I - a*BG1 - b*BG2;
        
        
%%
I = I+1;
I(~Jp) = 0;


%%
% CODEXobj.Proc{r,1}.background_subtraction.time{cl,ch} = toc;


% disp(['Background Subtraction time: ',num2str(CODEXobj.Proc{r,1}.background_subtraction.time{cl,ch}),' seconds'])
% 


end











% function [M,a,b] = find_optimal_ab(I,BG1,BG2,Va,Vb,proc_unit)
% 
% M = zeros(length(Va),length(Vb));
% 
% if(strcmp(proc_unit,'GPU'))
%     disp('dgfdgdfgf')
%     I = gpuArray(I);
%     BG1 = gpuArray(BG1);
%     BG2 = gpuArray(BG2);
%     Va = gpuArray(Va);
%     Vb = gpuArray(Vb);
%     M = gpuArray(M);
% end
% 
% % Jpx = I>0&BG1>0&BG2>0;
% 
% % I = I(Jpx);
% % BG1 = BG1(Jpx);
% % BG2 = BG2(Jpx);
% 
% for a = 1:length(Va)
%     for b = 1:length(Vb)
%         J = I - Va(a)*BG1 - Vb(b)*BG2;
%         M(a,b) = sum(abs(J(:)));
%     end
% end
% 
% [a,b] = find(M==min(M(:)));
% a = a(1);
% b = b(1);
% 
% a = Va(a);
% b = Vb(b);
% 
% 
% end














