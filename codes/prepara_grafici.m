% plots
clear all;
close all;

load clementina_flower_root.mat
m1=2000;
m2=2000;
clear nuove_specie_totali;

[specie_future1 media1 media_quantili1 P_posterior1 Valori_predittiva1 media_pr_nuova1 media_pr_nuova_quantili1...
    Probabilita_nuova1 M1   media_nuove_X1_non_X2  media_nuove_X1_non_X2_quantili ...
    media_distinte_nuove_X1_non_X2  media_distinte_nuove_X1_non_X2_quantili  ...
        media_vecchie_X1_non_X2  media_vecchie_X1_non_X2_quantili media_vecchie_condivise1   ...
        media_vecchie_condivise_quantili1  media_nuove1  media_nuove_quantili1]=prediction(M_X1,M_X2,M_T1,M_T2,M_parametri,N,n1,m1,n2);


save clementina_grafici_flower.mat P_posterior1 media1 media_quantili1 Valori_predittiva1 specie_future1 n1 N M_parametri Probabilita_nuova1 ...
    media_pr_nuova1 media_pr_nuova_quantili1 M1    media_nuove_X1_non_X2  media_nuove_X1_non_X2_quantili ...
    media_distinte_nuove_X1_non_X2  media_distinte_nuove_X1_non_X2_quantili ...
    media_vecchie_X1_non_X2  media_vecchie_X1_non_X2_quantili media_vecchie_condivise1    media_vecchie_condivise_quantili1  media_nuove1  media_nuove_quantili1



[specie_future2 media2 media_quantili2 P_posterior2 Valori_predittiva2 media_pr_nuova2 media_pr_nuova_quantili2...
    Probabilita_nuova2 M2    media_nuove_X2_non_X1  media_nuove_X2_non_X1_quantili ...
    media_distinte_nuove_X2_non_X1  media_distinte_nuove_X2_non_X1_quantili  ...
      media_vecchie_X2_non_X1  media_vecchie_X2_non_X1_quantili media_vecchie_condivise2 ....
      media_vecchie_condivise_quantili2  media_nuove2  media_nuove_quantili2]=prediction(M_X2,M_X1,M_T2,M_T1,M_parametri,N,n2,m2,n1);


save clementina_grafici_root.mat P_posterior2 media2 media_quantili2 Valori_predittiva2 specie_future2 n2 N M_parametri Probabilita_nuova2 ...
    media_pr_nuova2 media_pr_nuova_quantili2 M2  media_nuove_X2_non_X1  media_nuove_X2_non_X1_quantili  ...
    media_distinte_nuove_X2_non_X1  media_distinte_nuove_X2_non_X1_quantili   ...
    media_vecchie_X2_non_X1  media_vecchie_X2_non_X1_quantili media_vecchie_condivise2    media_vecchie_condivise_quantili2  media_nuove2  media_nuove_quantili2


