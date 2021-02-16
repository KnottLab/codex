function x = num2strn(x,n)

% n : number of characters
% 1 -> x
% 2 -> 0x
% 3 -> 00x


if(n==1)
    x = num2str(x);
    
elseif(n==2)
    if(x<10)
        x = ['0',num2str(x)];
    else
        x = num2str(x);
    end
    
elseif(n==3)
    if(x<10)
        x = ['00',num2str(x)];
    elseif(x<100)
        x = ['0',num2str(x)];
    else
        x = num2str(x);
    end

elseif(n==4)
    if(x<10)
        x = ['000',num2str(x)];
    elseif(x<100)
        x = ['00',num2str(x)];
    elseif(x<1000)
        x = ['0',num2str(x)];
    else
        x = num2str(x);
    end
    
elseif(n==5)
    if(x<10)
        x = ['0000',num2str(x)];
    elseif(x<100)
        x = ['000',num2str(x)];
    elseif(x<1000)
        x = ['00',num2str(x)];
    elseif(x<10000)
        x = ['0',num2str(x)];
    else
        x = num2str(x);
    end
      
end




end
























