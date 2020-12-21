function display_visium_array_v4(A)

% imagescBBC(I)

coeff = 23.5; 
% diameter = coeff*scale_factors.spot_diameter_fullres;
diameter = coeff*5.630095500000001;



X = A.X;
Y = A.Y;


th = 0:pi/50:2*pi;
for v = 1:size(X,1)
    xunit = 0.5*diameter * cos(th) + X(v);
    yunit = 0.5*diameter * sin(th) + Y(v);
    hold on,plot(xunit, yunit,'g','LineWidth',2);
end



end

