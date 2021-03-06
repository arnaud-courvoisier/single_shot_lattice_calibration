%%% This code takes two pictures as an input and outputs a curve
%%% representing the inverse of the RMS distance between data and theory,
%%% for various lattice depths. This allows to estimate the depth of the lattice
%%% as the position of the curve's maxima.
%%% The user is required to input system specific variables and the path to
%%% the pictures before running the program.
%%%
%%% Created by Arnaud Courvoisier 15/12/2021

clear all;
close all;

set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');
set(groot, 'defaultTextInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');
set(groot, 'defaultColorbarTickLabelInterpreter','latex');
set(groot, 'defaultColorbarTickLabelInterpreter','latex');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA ANALYSIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% SYSTEM SPECIFIC INITIALIZATION %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

calibration = 3.2e-6; % Size of a pixel in the object plane (m)
time_of_flight = 23e-3; % Time between the lattice release and the imaging (s)
exposure_time = 90e-6; % Time during which the lattice is pulsed (s)
imaging_resolution = 15e-6; % Resolution of the imaging system, including shot-to-shot position fluctuations if an average picture is used (m)

m_atom = 1.443e-25; % Mass of an atom (kg)
lattice_laser_wavelength = 780.241e-9; % Wavelength of the lattice laser used (m)

% Specify here the path of the time of flight pictures, in gray-scale PNG format or any other gray-scale format supported by the imread function.
% The region of interest surrounding the atoms should be at least 7*h_bar*k wide and centered roughly around 0*h_bar*k.
% The horizontal axis of the picture should correspond to the axis of the optical lattice.
initial_momentum_picture = imread('C:\Users\fearnaud\Documents\GitHub\single_shot_lattice_calibration\initial.png'); % Time-of-flight picture without any lattice pulse, used as a reference to obtain the cloud's initial momentum distribution.
pulsed_momentum_picture = imread('C:\Users\fearnaud\Documents\GitHub\single_shot_lattice_calibration\pulsed.png'); % Time-of-flight picture after lattice pulse.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

h_bar = 6.62606896e-34/2/pi;
e_recoil = h_bar^2*(2*pi/lattice_laser_wavelength)^2/(m_atom)/2; % Recoil energy (J)
v_recoil = sqrt(2*e_recoil/m_atom);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imaging_resolution = imaging_resolution/calibration;
gaussian_filter_size = floor(size(initial_momentum_picture,2)/20);
if rem(gaussian_filter_size,2)
    gaussian_filter_size = gaussian_filter_size - 1;
end
x = linspace(-gaussian_filter_size/2, gaussian_filter_size/2, gaussian_filter_size);
gaussian_filter = exp(-x.^2/(2*imaging_resolution^2));
gaussian_filter = gaussian_filter/sum(gaussian_filter);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA LOADING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

initial_momentum_distribution = sum(initial_momentum_picture);
momentum_distribution = sum(pulsed_momentum_picture);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FINDING CENTER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pixels = 1:numel(initial_momentum_distribution);

[x_data, y_data] = prepareCurveData( pixels, initial_momentum_distribution );

fit_result = fit_to_gaussian(x_data,y_data);

center = floor(fit_result.x_0);
background = fit_result.background;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% CROPPING DATA TO UNIVERSAL FORMAT %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

crop_range = 3; % The data will be cropped from -crop_range to +crop_range, where crop_range is in units of hbark
crop_one_hbark = round((time_of_flight*v_recoil)/calibration);
crop_range_in_pixels = crop_range*crop_one_hbark+1;

initial_momentum_distribution = initial_momentum_distribution((center-2*crop_one_hbark):(center+2*crop_one_hbark));
initial_momentum_distribution = initial_momentum_distribution - background;
initial_momentum_distribution = initial_momentum_distribution./max(initial_momentum_distribution);
initial_momentum_distribution(initial_momentum_distribution<0) = 0;

try
    momentum_distribution = momentum_distribution((center-crop_range_in_pixels):(center+crop_range_in_pixels));
    momentum_distribution = momentum_distribution - min(momentum_distribution);
    momentum_distribution = momentum_distribution./max(momentum_distribution);
catch
    error('Make sure that the region of interest surrounding the atoms is at least 7*h_bar*k wide and centered roughly around 0*h_bar*k')
end

momentum_vector = linspace(-crop_range,crop_range,length(momentum_distribution));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FOLDED AVERAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

folded_mean_temp = momentum_distribution;
l = folded_mean_temp(:,1:crop_range_in_pixels+1);
r = folded_mean_temp(:,crop_range_in_pixels+1:end);
folded_mean = flip((l+flip(r,2))/2,2);
mirror = flip(folded_mean,2);
momentum_distribution = [mirror(:,1:end-1) folded_mean];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GENERATES MOMENTUM DISTRIBUTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSTANTS AND PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

v_0_vector = linspace(0,15,150); % Potential depth in units of Er = h_bar^2*k^2/2m // V(x) = v_0*sin^2(kx) // k = pi/a = 2*pi/lambda_rb
number_of_bands = 15; % Number of bands that we take into account in the calculation
q_vector = linspace(-2,2,200); % q in units of pi/a = k

population_matrix = zeros(length(v_0_vector),length(q_vector),3); % Theoretical momentum distributions at t=exposure_time for different lattice depths

for vv = 1:length(v_0_vector)
    
    v_0 = v_0_vector(vv);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTS BAND STRUCTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    e_n_q = zeros(number_of_bands,length(q_vector)); % Each line corresponds to a band and columns correspond to different q indices
    j_vector = linspace(-(number_of_bands-1)/2,(number_of_bands-1)/2,number_of_bands); % index j in Jean Dalibard's Coll??ge de France notes
    c_j_n_q = zeros(length(j_vector),number_of_bands,length(q_vector));
    
    for l = 1:length(q_vector) % We loop on the values of q. For each value of q we solve an eigenvalue problem that gives us the eigenenergies and eigenvectors at the corresponding q.
        q_temp = q_vector(l);
        
        % We build equation (2.37) in a matrix form
        A = zeros(number_of_bands,number_of_bands);
        for ii=1:number_of_bands
            A(ii,ii) = (2*j_vector(ii)+q_temp).^2 + v_0/2; % Diagonal part
        end
        B = diag(-v_0/4*ones(number_of_bands-1,1),1)+diag(-v_0/4*ones(number_of_bands-1,1),-1); % Off-diagonal part
        C = A+B;
        
        [c_j_n_q(:,:,l), temp_eigen_values] = eig(C);
        
        e_n_q(:,l) = diag(temp_eigen_values);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TIME EVOLUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% We use for this part the following article as a reference :
    %%% J Hecker Denschlag et al 2002 J. Phys. B: At. Mol. Opt. Phys. 35 3095
    
    %%% Lattice exposure time vector in s
    
    region = [-1 0 +1];
    
    %%% Initial momentum distribution
    
    initial_momentum_distribution_interpolated = interp1(linspace(0,1,numel(initial_momentum_distribution)),initial_momentum_distribution,linspace(0,1,numel(q_vector)));
    
    for rr = region
        for qq = 1:length(q_vector)
            amplitude = 0;
            for nn = 1:number_of_bands
                amplitude = amplitude + conj(c_j_n_q((number_of_bands+1)/2,nn,qq))*c_j_n_q((number_of_bands+1)/2+rr,nn,qq)*exp(-1i*2*pi*e_n_q(nn,qq)*exposure_time/(h_bar*2*pi/e_recoil));
            end
            population_matrix(vv,qq,rr+2) = abs(amplitude).^2*initial_momentum_distribution_interpolated(qq);
        end
    end
    
    no = numel(q_vector);
    final_population_matrix = [population_matrix(:,(no*1/4):(no/2),1) population_matrix(:,(no/2+1):end,1)+population_matrix(:,1:(no/2),2) population_matrix(:,(no/2+1):end,2)+population_matrix(:,1:(no/2),3) population_matrix(:,(no/2+1):(end*3/4),3)];
    final_population_matrix = filter(gaussian_filter,1,final_population_matrix,[],2);
end

final_population_matrix = final_population_matrix./(repmat(max(final_population_matrix')',1,size(final_population_matrix,2)));
final_population_matrix = circshift(final_population_matrix,-gaussian_filter_size/2,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COMPARES DATA AND THEORY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Interpolates the data so that it has the same size as the theory
momentum_distribution = interp1(momentum_vector,momentum_distribution,linspace(-3,3,size(final_population_matrix,2)));
momentum_distribution(momentum_distribution == Inf) = NaN;

for ff = 1:size(final_population_matrix,1)
    error_2(ff) = 1/numel(momentum_distribution)*sum((momentum_distribution(:)' - final_population_matrix(ff,:)).^2,'omitnan');
end
normalized_momentum_distribution = momentum_distribution;


one_over_error2_normalized = 1./error_2;
one_over_error2_normalized = one_over_error2_normalized/max(one_over_error2_normalized);

[~,idx_max] = max(one_over_error2_normalized);
lattice_depth = v_0_vector(idx_max);
hwhm_right = v_0_vector(idx_max+find(one_over_error2_normalized(idx_max:end)<=(0.5+min(one_over_error2_normalized)),1,'first'));
hwhm_left = v_0_vector(find(one_over_error2_normalized(1:idx_max)<=(0.5+min(one_over_error2_normalized)),1,'last'));
fwhm = hwhm_right-hwhm_left;

summary_figure = figure;
summary_figure.Units = 'normalized';
summary_figure.Position = [0.3056    0.6234    0.3014    0.3367];

subplot(4,1,1:2)
plot(v_0_vector,one_over_error2_normalized,'color',[0.4 0.4 0.4],'linewidth',1.5)
axis square
xlabel('lattice depth ($E_r$)')
ylabel('$1/RMS_{error}$')
title(['Overlap between experiment and theory' ])
axis([0 15 0 1.2])
box on
grid on
legend(['$V_0 = ', num2str(lattice_depth,'%1.1f'), '\pm' num2str(fwhm/2,'%1.1f') 'E_r$'])

subplot(4,1,3)
imagesc([-crop_range,crop_range],[],pulsed_momentum_picture(:,(center-crop_range_in_pixels):(center+crop_range_in_pixels)))
colormap(flipud(gray))
xlabel('momentum ($\hbar k$)')
yticks([])

subplot(4,1,4)
plot(linspace(-crop_range,crop_range,numel(momentum_distribution)),momentum_distribution,'color',[0.4 0.4 0.4],'linewidth',1.5)
hold on
plot(linspace(-crop_range,crop_range,numel(momentum_distribution)),final_population_matrix(idx_max,:),'--','color', [0.6 0.6 0.6],'linewidth',1.5)
hold off
xlabel('momentum ($\hbar k$)')
legend({'Data','Theory'})


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fit_result = fit_to_gaussian(x,y)
    %%% This function fits the data (x,y) to a gaussian
    %%%
    %%% Created by Arnaud Courvoisier 10/03/2019

    if size(x,1)>1
        x = x';
    end
    if size(y,1)>1
        y = y';
    end

    [~,idx_maximum] = max(y);
    fun = @(p,x)p(1)*exp(-(x-p(2)).^2/2/p(3)^2)+p(4);
    options = optimoptions('lsqcurvefit','FunctionTolerance',1e-12,'Display','off');
    p_lower = [0,                  x(1),            0,         -max(y)/5      ];
    p_upper = [max(abs(y))*2,      x(end),          x(end),    max(y)         ];
    p_start = [abs(max(y)-min(y)), x(idx_maximum),  x(end)/6,  (y(1)+y(end))/2];
    [p,~,residual,~,~,~,jacobian] = lsqcurvefit(fun,p_start,x',y',p_lower,p_upper,options);

    fit_result.a = p(1);
    fit_result.x_0 = p(2);
    fit_result.sigma = p(3);
    fit_result.background = p(4);
    fit_result.all = p;
    fit_result.fit_type = 'gaussian';

    try
        fit_result.confidence = nlparci(p,residual,'jacobian',jacobian);
    catch
        fit_result.confidence = NaN(4,2);
    end
    fit_result.fun = @(p,x)p(1)*exp(-(x-p(2)).^2/2/p(3)^2)+p(4);
end
