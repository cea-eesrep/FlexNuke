### Que trouve t'on dans ce GIT:
Ce dépot Git regroupe les travaux issus de trois projets :
- les travaux de modélisation de la brique nucléaire flexible pour EESREP. Le composant ainsi créé est FlexibleNPP_component.py et l'archive de sa fabrication (archaïque à l'époque de git, certes) se trouve dans une succession de cas d'applications d'EESREP dans le dossier FlexEESREP_archive ;
- les travaux de reconstruction de données "historiques", fondés sur les données publiées en ligne semestriellement par RTE ;
- les travaux préliminaires à la comparaison d'EESREP et d'ANTARES sur le cas A-B (EESREP_casAB.ipynb).

Ce readme se propose de detailler quelques éléments permettant de prendre en main les différents dossiers. Par simplicité, les éléments ci-dessous sont par ordre alphabétique des noms de dossiers ou de fichiers.

### Le dossier FlexEESREP_archive

Ce dossier ne devrait pas être utilisé. Son existence est peu utile. Toutefois, les scripts présents construisent de manière itérative un modèle d'optimisation linéaire en nombre entiers, fondé sur EESREP, qui inclut dans le mix une ou plusieurs centrales nucléaires flexibles. Par flexible, il est entendu une unité répondant à certaines contraintes opérationnelles (rampes, crédit K, durée allumée après allumage, durée éteinte après extinction...)

Les scripts sont largement ressemblants entre eux suffisamment commentés pour en permettre la compréhension sans trop de difficultés.

### Le dossier Historical_RTE_analysis

Ce dossier regroupe trois sous-parties :
- Un dossier Processed_data qui inclut tous les dataframes qui ont été générés par les scripts détaillés ci-après ;
- Un dossier RTE_gross_data qui inclut tous les relevés publiés semestriellement par RTE entre 2011 et 2023, évitant ainsi au lecteur de passer un moment désagréable à télécharger chacun des .xls et à les ouvrir pour les dé-corrompre au format .xlsx. Les données sont brutes et sans traitement aucun ;
- Un ensemble de scripts, détaillés ci-dessous.

#### Scripts d'anlayse historique

**CreditK_analyser.ipynb** prend en entrée deux dataframes : celui contenant le crédit K du parc (obtenu avec les hypothèses faites dans Historical_df_analyser.ipynb **ET VALABLES UNIQUEMENT POUR LES PALLIERS CP0 et CPY**) et celui contenant les relevés historiques de production nettoyés. Il permet simplement de retracer les courbes de crédit K et de puissance relative, ou d'obtenir quelques anlayses rudimentaires sur "l'utilisation" du crédit K pour certaines unités bien choisies.

La grandeur obtenue en fin de script, entre 0 et 1, indique la proportion de crédit K "restant" sur la période considérée. C'est l'intégrale temporelle du crédit K tronqué entre 100 et 200 et normé à 1 pour rester conservatif. Proche de 1 signifie que le réacteur n'a pas beaucoup été à crédit K "faible" et proche de 0 indique à l'inverse de longues périodes à crédit K réduit.

**Historical_data_RTE.ipynb** est un script de construction du dataframe "dataframe_RTE.csv.xz" à partir des historiques Excel publiés par RTE. Le code s'articule en plusieurs parties triviales et consiste en une séparation-reconcaténation. Certains problèmes de fusion sont explicités, en particulier des changements de noms pour une même tranche, mais ne concernent pas de manière problématique les tranches nucléaires. Que le lecteur note bien quatre problèmes au sujet du dataframe généré :
- Il manque des dates, elles ne sont pas recrées ;
- Il y a des données manquantes d'origine, marquées d'une étoile ;
- Il y a des données aberrantes, qui ne sont pas filtrées ;
- Il y a des problèmes de fusion (deux fois la même unité avec des relevés différents à la même date).

**Historical_df_analyser.ipynb** est un script d'analyse du dataframe historique *nettoyé*. Il commence par charger le dataframe nettoyé avant de pré-charger des sets d'analyse pour faciliter l'utilisation. Les sets proposés sont par nom de centrale (pour analyser les quatre tranches du CNPE du Tricastin par exemple) ou par pallier (pour anlayser les tranches du palier P4' ou P4-P4' par exemple). L'utilisateur peut ainsi choisir les centrales à analyser (study_list0 est une liste avec une tranche de chaque pallier) et les dates d'analyse.

Le script commence par tronquer le dataframe global aux unités sélectionnées et aux dates voulues, et à étudier la qualité de la donnée (% NaN) et à calculer le dataframe des puissances relatives. L'analyse est ensuite séparée en plusieurs parties :
- Histogramme des rampes (avec éventuel filtrage des rampes plus lentes qu'un seuil donné) ;
- Tracé (si activé) de l'historique de puissance des tranches coloré avec le taux moyen de rampe sur 7 jours. Cela permet notamment de visualiser une évolution du dynamisme des tranches dans leur campagne ou d'une campagne sur l'autre. Le choix de la fenêtre de moyennage est très facilement modifiable ;
- Calcul/affichage du nombre d'heures passées en "Low-Power Opertations" (LPO) ou "Fonctionnement à Puissance Intermédiaire" (FPI) donc entre 92 %Pn et 20 %Pn.
- Calcul/affichage du nombre d'heures passées en "Extended Low-Power Opertations" (ELPO) ou "Fonctionnement à Puissance Intermédiaire" (FPPI) donc entre 92 %Pn et 20 %Pn plus de 8 h sur 24 h glissantes. **Le lecteur notera que cette définition n'est pas valable pour le pallier N4 (à vérifier) qui semble avoir ELPO = LPO ou FPPI = FPI, voir les STE pour plus d'informations.**
- Un filtrage **très discutable** des opérations de suivi de charge considérées comme les phases de LPO avec des pentes de moins de 10 %Pn/h (seuil arbitraire modifiable dans la fonction associée, davantage de travaux seraient utiles ici). La proportion de temps passé en suivi de charge est ensuite affichée sur un graphe avec des points de couleur associée aux palliers ;
- Calcul/affichage du burn-up des tranches en supposant que les arrêts pour rechargement sont des arrêts de plus de 26 jours réalisés à burn-up élevé (seuil paramétrable dans la fonction). Quelques erreurs sont à regretter, mais difficiles à résoudre sans faire exploser le coût de calcul et dont l'impact est en tout état de cause très modéré dans les calculs subséquents ;
- Un affichage des historiques de puissance colorés avec le burn-up ainsi obtenu. Cela permet d'identifier les quelques problèmes marginaux (ex Blayais 1 2020) ;
- Calcul/affichage du crédit K des tranches **en supposant la continuité des règles applicables aux palliers CP0 et CPY en gestion GARANCE fonctionnant "en base"**. Le seuil visible à K = 100 est normal et lié à la méthodologie détaillée par EDF dans les STE.

**Historical_df_cleaner.ipynb** est un script de nettoyage du dataframe historique, qui crée datframe_RTE_without_outliers.csv.xz :
- Remplacement des données manquantes "*" par des np.nan (Not a Number de numpy pour ne pas perturber l'analyse) ;
- Compactage du segment temporel : reconstruction de la compacité temporelle par remplissage des "trous" temporels par des np.nan pour toutes les unités ;
- Identification des données aberrantes "outliers" définies comme sortant de l'intervalle [-0,05 Pn ; 1,10 Pn]. À vérifier : la fonction associée enlève-t-elle les données ou les remplace-t-elle par des False ? Le cas échéant, il faut corriger un peu ce point ;
- Identification des données aberrantes "inliers" défineis comme dans l'intervalle acceptable, sans être crédibles. On parle ici de pointe d'une heure à 50 %Pn au milieu d'un arrêt pour rechargement par exemple. Les pas de temps qui se compensent deux à deux en rampes, avec des rampes relativement rapides (> 25 % Pn/h) sont filtrées.

**NPP_France_models.xlsx** comprend les palliers des centrales françaises.

**Units_France_capacity** comprend les puissances nominales des centrales françaises.

### EESREP_casAB.ipynb

Ce script vise à construire un modèle proche du cas AB construit par I-tésé pour Antares. Il est encore en cours de construction. Il est suffisamment commenté pour être intelligible et suit la structure habituelle des codes EESREP (voir section suivante).

### EESREP_model_with_flexible_nuke.ipynb

Ce script est, avec FlexibleNPP_component.py, le coeur de la mission de modélisation de la flexibilité nucléaire pour EESREP. Cette section s'intéresse au code employant la brique flexible. La suivante détaillera son contenu.

La structure du modèle est, grossièrement, la suivante :

                                             | -->  load
              fuel_Nuke --> FlexibleNPP  --> |
              fuel_CCGT --> cluster_CCGT --> |
                  demand-side management --> |
                                             | --> spilled_energy

L'utilisateur a la main sur l'intégralité des paramètres :
- Paramètres de simulation :
    - Durée d'un pas de temps (défaut : horaire, à ne pas modifier sans réflechir à l'impact sur les contraintes de flexibilité) ;
    - Durée de recouvrement des horizons ;
    - Durée d'un horizon ;
    - Nombre d'horizons.
- Données sur la demande, communes aux différentes formes, cela permet de construire des tracés fictifs :
    - Demande maximale ;
    - Demande minimale ;
    - Périodicité (le cas échéant) ;
    - Amplitude (le cas échéant) ;
    - Moyenne (le cas échéant) ;
    - Forme de la demande (linéaire, sinus, duck curve, triangle... à chercher plus bas) ;
    - Perturbation(s) à imposer sur la demande linéaire pour tester certaines contraintes.
- Données sur les moyens d'équilibrage de force : activation des moyens "spilled" et "Demand-side management" ;
- Contraintes à activer sur la brique nucléaire flexible :
    - Rampes de puissance (limite le rythme de montée en puissance dans les 16 heures qui suivent l'arrêt à froid) ;
    - Crédit FPPI (introduit une forme de monitoring du jeu pastille-gaine qui limite la manoeuvrabilité prolongée si le jeu se referme). Cette contrainte nécessite de charger trois dictionnaires :
        - dict_K0 : dictionnaire avec la valeur d'intialisation du crédit K ;
        - dict_A_i : dictionnaire avec les valeurs des coefficients de débit Ai (évoluant selon la profondeur du palier et le burn-up);
        - dict B_j : dictionnaire avec les valeurs des coefficients de crédit Bj (évoluant selon la valeur courante de K);
    - Durée de maintien après changement d'état (allumage/extinction)
    - Date de sortie d'arrêt pour rechargement (translate le profil de puissance atteignable en conséquence) ;
    - Mode de fonctionnement des tranches flexibles (Base ou suivi de charge)
    - Monitoring du burn-up ;
    - Méthode de calcul de l'approximation du burn-up, nécessaire à la construction du gabarit de Pmin atteignable : endogène (True) donc fondé sur l'historique de production ou exogène (False) donc fondé sur le facteur de charge du parc français
- Données du mix énergétique branché au bus électrique :
    - Nombre de tranches nucléaires flexibles (**le lecteur notera que leurs OPEX sont différents d'1e-6 euros pour éviter les permutations lors de l'optimisation) ;
    - Date des arrêts pour rechargement des tranches nucléaires flexibles (en jours depuis le début de simulation, un arrêt pour rechargement durant par défaut 26 jours, voir ci-dessous).


Ensuite, l'utilisateur peut rentrer une myriade de données technologiques ou éconmiques :
- Forme de la demande (paramétrage) ;
- Données technico-éconmiques pour les tranches nucléaires (flexibles et clusters) :
    - Durée de campagne (entre deux arrêts pour rechargement), par défaut 300 jours ;
    - Durée d'un arrêt pour rechargement, par défaut 26 jours ;
    - Rendement moyen de la tranche, sans évolution en fonction du niveau de puissance, par défaut 33 % ;
    - Facteur de charge moyen historique pour initialiser l'approximation du burn-up, par défaut 81 % ;
    - Puissance nominale (maximale), par défaut 1086 MW ;
    - Puissance minimale relative avant arrêt d'une tranche **pour un cluster**, par défaut 40 %Pn ;
    - Poids de combustible chargé dans le coeur (pour le calcul du burn-up en MWj/t), par défaut 2 kg pour chacun des 264 crayons de chacun des 185 assemblages ;
    - Durée minimale de fonctionnement après allumage, par défaut 12 heures ;
    - Durée minimale de maintien à l'arrêt après extinction, par défaut 16 heures ;
    - Taux maximal de rampe montante à appliquer dans les 16 heures qui suivent un arrêt à froid ;
    - Taux maximal de rampe descendante à appliquer, par défaut désactivé au sein même du code (à décommenter) ;

    - Nombre de tranches par cluster nucléaire ;

    - OPEX d'une tranche nucléaire, par défaut 14.5 €/MWh ;
    - Coût d'allumage d'une tranche nucléaire, par défaut 28 €/MW ;
    - Coût fixe de fonctionnement (Fixed OPEX), par défaut 1 c€/h.
- Données technico-éconmiques pour les tranches gaz (clusters) : à peu de choses près la même chose avec moins de variété ;
- Données technico-éconmiques pour les délestages et ecrêtages ;
- Données technico-éconmiques pour les combustibles ;

Vient ensuite la phase d'instanciation des composants et de branchement, (sauf exception en gras, l'utilisateur n'a pas grand chose à modifier ici) :
- Instanciation des bus physiques (électrons, combustible nucléaire, gaz...) et d'éventuels bus financiers ;
- Instanciation de la charge et des divers composants (et, éventuellement, des post-traitements nécessaires pour certains d'entre eux, voir l'instanciation du nucléaire flexible) ;
- Instanciation d'éventuels liens supplémentaires.
- Instanciation du modèle EESREP, avec le **choix du solveur** ;

Le bloc de simulation indique par défaut le numéro de l'horizon en cours de résolution. L'utilisateur peut modifier le code de manière à afficher certaines informations (par exemple le crédit K ou le burn-up) en direct, cela relève de la liberté individuelle.

Le bloc d'affichage des résultats se décompose en trois à quatre sous-blocs :
- Bloc 1 : paramétrage des quadrillages et limites de l'axe des abscisses pour pouvoir zoomer sur un évènement d'intérêt ;
- Bloc 2 : graphes "système" avec d'une part les production des groupes électrogènes et la demande et d'autre part les équilibrages (qui traduisent en fait les déséquilibres) et la demande ;
- Bloc 3 : sous-sous-blocs "nucléaires" avec des paires de graphes indiquant d'une part la production d'un groupe, son gabarit de puissance minimale atteignable et son burn-up et d'autre part son diagramme d'état et son crédit K ;
- Bloc 4 éventuel : sous-bloc dédié au gaz.

Une dernière partie est enfin complètement à la main de l'utilisateur, pour afficher temporairement un besoin. En l'état, il sert notamment à afficher le burn-up en MWj/t de la tranche 1.

### FlexibleNPP_component.py

Ce script construit la brique (Python class) nucléaire flexible *per se*. La classe est construite en quatre grandes parties :

- Initialisation, avec déclaration des entrée utilisateur mais aussi des entrées/sorties composant, de leur continuité et noms. Grille de lecture pour faciliter la compréhension des noms qui ne sont pas triviaux, en particulier les acronymes anglo-saxons :
    - fpd_init : full-power days (jepp, jours équivalents à pleine puissance) à la date 0 ;
    - fpd_max : full-power days (jepp) en fin de campagne (stricte, par de prolongement de cycle implémenté) ;
    - RS_duration : durée d'un refuelling stop (arrêt pour rechargement) ;
    - date_end_RS : date de sortie de refuelling stop ;
    - bool_fpd : activation du monitoring des fpd (jepp) ;
    - average_lf : facteur de charge moyen (load factor) ;
    - creditELPOmax : limite haute du crédit K (ou crédit ELPO pour Extended Low-Power Operations, car la méthodologie n'est pas réellement identique à celle d'EDF par défaut d'information) ;
    - bool_creditELPO : activation du monitoring du crédit ELPO ;
    - ELPO_mode : mode de fonctionnement (base ou suivi de charge) ;
    - K0 : valeur initiale du crédit ELPO ;
    - cons_A_i : valeur conservative du coefficient de débit du crédit ELPO (A_i maximal renseigné par l'utilisateur dans dict_A_i) ;
    - bool_duration : activation de la contrainte en temps après changement d'état ;

    - CS : Cold Shutdown (arrêt à froid) ;
    - HS : Hot Standby (attente à chaud) ;
    - LPO : Low-Power Operations (FPI, fonctionnement à puissance intermédiaire, entre 20 %Pn et 92 %Pn) ;
    - PO : Power Operations (fonctionnement dans la bande PMD, Puissance maximale disponible, jusqu'à 92 %Pn) ;
    - RS : Refuelling Stop (arrêt pour rechargement = arrêt à froid de durée contrainte) ;
    - RS_days : avancement en jours dans l'arrêt pour rechargement ;
    - fpd : compteur de jepp pour le calcul du burn-up ;
    - creditELPO : compteur de crédit ELPO ;
    - countLPO : compteur d'heures en LPO/FPI au cours des 24 dernières heures ;
    - is_step_ELPO : drapeau countLPO > 8.

- Déclaration des entrées/sorties ;

- Construction du modèle : voir sous-section suivante.

#### Construction du modèle (fonction build_model(...))
Cette fonction est appelée à chaque horizon et construit *per se* le modèle nucléaire flexible. Deux parties sont à distinguer : celle qui est executée en amont de l'horizon pour initialiser certaines variables (comportement proche du traitement inter-horizons) et celle qui définit des contraintes qui seront vraies à chaque pas de temps d'optimisation.

##### Préparation de l'horizon
Plusieurs étapes de calcul sont nécessaires avant de pouvoir définir les contraintes **linéaires** valables à chaque pas de temps :
- Calcul du burn-up en fin du dernier horizon, en prenant en compte le planning d'arrêt éventuellement saisi par l'utilisateur ;
- Calcul du nombre de jours restants d'arrêt pour rechargement avant le premier horizon si le planning d'arrêt introduit une centrale arrêtée au début de l'horizon 0 ;
- Calcul préliminaire pour l'aproximation du burn-up lors de l'horizon (calcul du facteur de charge moyen sur les horizons passés ou, à défaut, depuis la saisie utilisateur) ;
- Calcul de la proximité d'un arrêt pour rechargement : [va arriver, va se terminer, va occuper tout l'horizon ou ne peux pas arriver pendant l'horizon] permet de ne pas initialiser les contraintes quand c'est inutile et de faciliter la tâche au pré-optimisateur ;
    - Eventuel calcul du pas seuil entre fonctionnement et arrêt lorsqu'un AR va arriver dans l'horizon ;
- Déclaration des variables d'optimisation (ou fixées) selon la proximité de l'arrêt pour rechargement ;

Certaines préparations sont également cachées dans les opérations uniquement réalisées au premier pas de temps :
- initalisation des variables de continuité (previous_step_...) ;
- initialisation de la contrainte de rampes dans les seize heures suivant un arrêt à froid si le reacteur a CS_0 = 1 ;

##### Construction des contraintes par itération sur les pas de temps
La construction des contraintes est articulée en blocs (soit à exécution forcée avec des if True, soit à exécution conditionnelle avec des if bool) pour en faciliter la lecture et la contraction par le lecteur.

- Bloc de contraintes (conditionnel si le réacteur peut fonctionner lors de l'horizon, i.e. ne sera pas entièrement en arrêt pour rechargement) :
    - Sous-bloc 1 (forcé) : renommage des variables courantes par des noms haut-niveau (current_step_...) ;
    - Sous-bloc 2 (forcé) : équations de comportement (loi entrées/sorties) et exclusion mutuelle des états du système (RS/CS/HS/LPO/PO) ;
        - Sous-sous-bloc 3 (conditionnel) : équation d'évolution des fpd/jepp.
    - Sous-bloc 3 (forcé) : calcul de la puissance minimale atteignable par comparaison du burn-up approché au pas i avec le gabarit de P_min de Stéphane Feutry ;
    - Sous-bloc 4 (forcé) : encadrement de la puissance en fonction de l'état du réacteur (20 %Pn à 92 %Pn en LPO, 92 %Pn à 100 %Pn en PO, 0 %Pn sinon). Que le lecteur note qu'il est supposé que la puissance thermique en attente à chaud (2 %Pn) n'est pas considérée comme productrice d'électrons sur le réseau pour éviter un comportement dégénéré/opportuniste du réacteur ;
    - Sous-bloc 5 (conditionnel) : contrainte sur l'allumage ou l'extinction juste après une extinction ou un allumage, contrainte sur la rampe maximale dans les 16 h qui suivent un arrêt à froid ou un arrêt pour rechargement (si boolstate = 1 - CS -RS = 0) ;
    - Sous-bloc 6 (conditionnel) : calcul de countLPO (somme sur les dernières 24 h de LPO), astuce pour contraindre le modèle à passer en ELPO si countLPO > 8, débit conservatif du crédit ELPO

    Ajout à l'objectif d'une minimisation (souple) du nombre de pas en ELPO pour éviter d'être tout le temps en ELPO, du nombre de jours en LPO et du nombre de cycles d'allumage/extinction.

En l'absence de fonctionnement, toutes les variables d'optimisation sont contraintes dès la définiton et il n'y a pas lieu de déclarer de contraintes spécifiques.

#### Déclaration d'une fonction de post-traitement du crédit K
Le crédit K est calculé de manière conservative lors de l'optimisation avec le coefficient de débit (A_i) le plus élevé de ceux déclarés par l'utilisateur. La fonction de post-traitement reprend, pour chaque unité flexible, l'historique de production pour calculer le crédit ELPO réellement restant à la fin de l'horizon. Elle écrase et remplace la colonne correspondante dans le dataframe des résultats. **Que le lecteur note bien que cette fonction n'est valable que pour les paliers CP0 et CPY, et sous des hypothèses discutables concernant l'identification du suivi de charge** (considéré conservativement inexistant ici : toute manoeuvre consomme du crédit ELPO).
