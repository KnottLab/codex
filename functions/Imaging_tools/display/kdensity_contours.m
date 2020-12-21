function kdensity_contours(x,y)



[pdfx xi]= ksdensity(x);
[pdfy yi]= ksdensity(y);

% Create 2-d grid of coordinates and function values, suitable for 3-d plotting
[xxi,yyi]     = meshgrid(xi,yi);
[pdfxx,pdfyy] = meshgrid(pdfx,pdfy);

% Calculate combined pdf, under assumption of independence
pdfxy = pdfxx.*pdfyy; 

% Plot the results
% mesh(xxi,yyi,pdfxy)
% set(gca,'XLim',[min(xi) max(xi)])
% set(gca,'YLim',[min(yi) max(yi)])

hold on
contour(xxi,yyi,pdfxy,'k')


end