% Same as main_highpop.m but with PARFOR Loop

clear all;
close all;

% add path for Computing
addpath('/work/sta790/ff31/HPYsinglecell/codes')  
addpath('/work/sta790/ff31/HPYsinglecell/codes/hyper')  
% addpath('/Users/felpo/MATLAB/projects/untitled/codes')  


%add the Good-Tulming estimator of Bianca

% numero di iterazioni su cui fare average
Runs=100;
% Runs=5;

% numero delle popolazioni
J=100;
% J = 10;

% Setting paper 
% numero totale delle specie tra tutte le popolazioni
N=20000;
% parametri per la Zipf
Zipfpar=[1.3; 1.3; 1.3; 1.3; repelem(2,J - 4).'];
% numero delle specie presenti nelle J popolazioni
NN=2500*ones(J,1);


% Reviewer Answer 6 
% parametri per la Zipf
% Zipfpar=[repelem(2,33).'; repelem(2.1,33).'; repelem(1.9,34).'];

% numero di iterazioni in MCMC per il numero di tavoli e dei parametri di
% HPY dato il campione iniziale
iter=35000;
burnin=15000;
% iter=350;
% burnin=150;

% Numero di iterazioni per il particle filter: il numero delle iterazioni
% deve essere inferiore a iter-burnin
N_iter=1000;

% normalizing parameter of GT strategy, in order to give some prob to be selected to 
% populations that have u_Gt = 0
alpha_GT = 0.1;

% ampiezza del campione iniziale
n_init=20*ones(J,1);
% lunghezza del campione addizionale
addsample=100;
% addsample=5;
% units sampled each additional trial
n_inc = 50;


% Dati finali
M=zeros(Runs,addsample);
%DATAfinal=struct('HPY',M,'uniform',M,'Oracle',M,'GoodTulming',M);
DATAfinal_HPY = M;
DATAfinal_uniform = M;
DATAfinal_Oracle = M;
DATAfinal_GoodTulming = M;


%weights
M=zeros(Runs,J);
%WEIGTHS=struct('weight_HPY',M,'weight_uniform',M,'weight_Oracle',M,'weight_GoodTulming',M);
WEIGTHS_HPY = M;
WEIGTHS_uniform = M;
WEIGTHS_Oracle = M;
WEIGTHS_GoodTulming = M;
clear M;

% simulare la legge vera in ogni popolazione
labels=1:N;

%frequenze nella popolazione
freq=cell(1,length(NN));
for i=1:J
    freq{i}=zeros(1,NN(i));
end

for i=1:J
    freq1=1:NN(i);
    freq2=sum(freq1.^(-Zipfpar(i)));
    for j=1:NN(i)
        % Zipf
        freq{i}(j)=((1/j)^Zipfpar(i))/freq2;
        
        % Uniform
        % freq{i}(j) = 1/NN(i);
    end
end

% labels delle specie nelle varie popolazioni
pop=cell(1,J);
for i=1:J
    labels_corr=labels;
    for h=1:NN(i)
        pop{i}(h)=gendiscr(labels_corr,ones(1,length(labels_corr))/length(labels_corr));
        ind=find(pop{i}(h)==labels_corr);
        labels_corr(ind)=[];
    end
end

%genera i dati iniziali per le varie popolazioni
% data{j}= vettore che contiene il campione della popolazione j
data=cell(1,J);
for i=1:J
    data{i}=zeros(1,n_init(i));
end
for j=1:J
    for i=1:n_init(j)
        data{j}(i)=gendiscr(pop{j},freq{j});
    end
end

dati_totali=cell2mat(data);
% specie dsitinte di tutta la popolazione iniziale
Kini=unique(dati_totali);
%numero di specie iniziali distinte
tot_dist=length(Kini);
%% Inferenza MCMC sul numero di specie e sul numero di parametri
% questi parametri sono quelli riferiti alle prior degli hyperparametri
% del PY
M0=1;
V0=4;
bigK=length(Kini);

% aggiornamento con l'algoritmo marginale che ho sviluppato con Antonio
% ed Igor
[M_Tavoli M_l_star M_parametri Dati_star k_popolazioni]=posterior_K(data,M0,V0,J,n_init,iter,burnin);
%save ristorante_cinese  M_Tavoli M_l_star M_parametri Dati_star k_popolazioni Kini tot_dist dati_totali data pop DATAfinal WEIGTHS

% % Aggiornamento con l'algoritmo di Marco: cambia come si aggiornano gli
% % iperparametri
% [M_Tavoli, M_l_star, M_parametri, Dati_star, k_popolazioni]=ristorante_cinese(data,M0,V0,J,n_init,iter,burnin);

% ora stimo i parametri che mi servono dopo
[mjk_ini, m_dot_k_ini, m_j_dot_ini, m_dd_ini alpha d gamma nu]=stima_parametri(M_l_star,tot_dist,M_parametri,J,iter-burnin);
gamma = repmat(gamma,Runs,1);
nu = repmat(nu,Runs,1);
alpha = repmat(alpha,Runs,1);
d = repmat(d,Runs,1);

% creo un vettore di pesi per la mistura delle normali dei parametri: ne
% prendo solo una parte.
M_parametri_ini=M_parametri(end-N_iter+1:end,:);

% storage 
% M_parametri_storage = repmat(M_parametri_ini,Runs,addsample,1);


%% Algoritmi vari per scegliere da dove campionare la prossima
% osservazione: Unif, HPY Oracle GT
disp('finish first estimation')

%to save workspace
%M_par_save = M_parametri_storage(1,:,:);
%clear M_parametri_storage; 
save('MCMC_estimation_paper.mat');

%save weights and add sample units
%xlswrite('HPY.xls',transpose(sum(DATAfinal.HPY)/Runs));
%xlswrite('unif.xls',transpose(sum(DATAfinal.uniform)/Runs));
%xlswrite('GT.xls',transpose(sum(DATAfinal.GoodTulming)/Runs));
%xlswrite('Oracle.xls',transpose(sum(DATAfinal.Oracle)/Runs));

%per caricare dei vecchi valori
% unif= csvread('unif.csv');