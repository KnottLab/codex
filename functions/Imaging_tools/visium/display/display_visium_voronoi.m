function display_visium_voronoi(I,A,R)

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


voronoi(X,Y,'c')


end

