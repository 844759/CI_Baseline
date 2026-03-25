function sigmaList = recommended_sigma_values(lambdaC)
%RECOMMENDED_SIGMA_VALUES
% Theree recommended sigma values for a given lambda_c:
%   sigma_small = lambda_c/(2*log(2))
%   sigma_mid   = lambda_c
%   sigma_large = 2*lambda_c

sigmaSmall = lambdaC / (2 * log(2));
sigmaMid   = lambdaC;
sigmaLarge = 2 * lambdaC;

sigmaList = [sigmaSmall, sigmaMid, sigmaLarge];
end
