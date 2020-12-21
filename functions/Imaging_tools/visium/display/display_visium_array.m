function display_visium_array(I,A,R)

% imagescBBC(I)

coeff = 23.5; % should be 1, waiting for Keshav...
diameter = coeff*5.630095500000001;

X = coeff*A.X(A.In_Tissue==1);
Y = coeff*A.Y(A.In_Tissue==1);

Jv = X>=R.y_start & X<=R.y_end & Y>=R.x_start & Y<=R.x_end;

X = X(Jv);
Y = Y(Jv);

X = X-R.y_start;
Y = Y-R.x_start;

th = 0:pi/50:2*pi;
for v = 1:size(X,1)
    xunit = 0.5*diameter * cos(th) + X(v);
    yunit = 0.5*diameter * sin(th) + Y(v);
    hold on,plot(xunit, yunit,'g','LineWidth',2);
end



end

