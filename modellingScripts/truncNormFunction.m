function result = truncNorm(x,mu,sigma,x_min)	
	heaviside_l = @(x) 1.0*(x>=0);
    truncNormPDF = (normpdf(x , mu, sigma)./normcdf(-x_min, -mu, sigma) .* heaviside_l(x - x_min));
    result = truncNormPDF;
end