function x = num2str2(x) 

if(x<10)
    x = ['00',num2str(x)];
elseif(x<100)
    x = ['0',num2str(x)];
else
    x = num2str(x); 
end



end