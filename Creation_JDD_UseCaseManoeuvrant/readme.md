
### Tuto GIT ici :
https://codev-tuleap.intra.cea.fr/plugins/mediawiki/wiki/trilogy/index.php?title=M%C3%A9mo_Git

### Que trouve t'on dans ce GIT:

Ce dépot Git regroupe l'ensemble des données nécessaires pour la création des JDD Antares de l'étude sur la Manoeuvrabilité des REPs 2023. Il s'agit d'un mix France-Allemagne 2050.
Cela comprend un dossier de Donnees et un unique script R à lancer.

### Prérequis pour créer un JDD 

Pour générer le jeu de données, il est aussi nécessaire de posséder la version 4.1.0 (ou ses dérivés) de R.
Plusieurs packages doivent être installés et ils sont disponibles dans le dossier Packages_Antares. 
Il est necessaire de relancer le package_reader.R pour avoir tous les derniers packages à jour, puis de lancer R_install_packages.R pour les installer.
Il est à noter qu'il est fort probable qu'il manque certains packages pour lancer le script R (ce qui n'a pas pu être mis à jour par manque de temps).
Il est néanmoins possible de les installer assez facilement via l'interface de Rstudio qui nous renseigne sur les packages manquants.

### Créer un JDD

Une fois les packages installés, il suffit de lancer le script MIX2050_A-B.R pour créer le JDD Antares.
Vous pouvez lancer directement le calcul Antares à partir du Script R en renseignant l’adresse du bin d’Antares.
Il suffit de modifier la ligne précise du script tel que :
<pre>setSolverPath(path = "C:/Program Files/RTE/Antares/8.1.0/bin/antares-8.1-solver.exe")</pre>

Si ce bin n’est pas renseigné, le calcul ne se fait pas et le dossier devra être ouvert avec Antares pour lancer le calcul à partir de l’IHM.
Il est à noter que pour le moment, la version 8.1 d’Antares est nécessaire pour lancer un calcul avec les JDD créés par les scripts R.

Enfin, pour réaliser la transcription du JDD Antares vers Persee, des modifications ont été nécessaires et ce sont ces JDD qui sont disponibles dans le dépôt Tuleap https://codev-tuleap.intra.cea.fr/plugins/git/eraa/Etudes_Manoeuvrabilite_REP
Plus d'informations sont disponibles dans le readme du depôt associé.
