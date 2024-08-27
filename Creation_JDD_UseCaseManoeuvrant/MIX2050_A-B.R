# Mix 2050 (A-B)


# *** Packages a installer si jamais fait ***

{
#install.packages("AntaresViz")
#install.packages("xts")
#install.packages("ggplot2")
#install.packages("reshape2")
#install.packages("geometry")
#install.packages("tictoc")
#install.packages("antaresRead")
  }

# *** Chargement des librairies utiles ***

{
  library(tictoc)
  library(stringr)
  library(geometry)
  library(antaresRead)
  library(antaresEditObject)
  library(antaresProcessing)
  library(antaresViz)
  library(readxl)
  library(readr)
  library(data.table)
  library(readxl)
  library(sm)
  library(tidyverse) 
  library(tidyquant) 
  library(ggplot2)
  library(RColorBrewer)
  library(dplyr)
  library(htmlwidgets)
  library(manipulateWidget)
  library(xts)
  library(lattice)
  library(ggplot2)
  library(reshape2)
  library(rstudioapi)
}


# *** Nettoyage (suppression des variables et nettoyage de l'affichage console) ***

{
rm(list = ls()) # Supprime toutes les variables creees
cat("\014") # Supprime l'affichage actuel sur la console
heuredebut = Sys.time() # Sauvegarde l'heure avant le lancer de la simulation
}

{# *** Boulot ***

Effacement = T # si T : on met en place des capacites d'effacement, sinon non 
translation = T # si T : on decale le profil de consommation initial en base, sinon par homothetie 

{
print("Let's get to work!")
tic()


# *** Definition du nom de l'etude generee ***

nom_etude = "A-B"
print(paste("Starting to create the study ", nom_etude, sep = ""))


# *** Choix des variables utilisateurs ***

{  
# *** Paramètres etudies *** 

# ** Choix de l'annee climatique etudiee ** 
# Rappel : 1 --> 1982 ; 15 --> 1996 ; 25 -->2006 et 35 --> 2016  
  
choice_year = 24

  
# ** Donnees tech-ecos des centrales thermiques **   


coutMarginalNucleaire = 14.5 #(€/MWh)
coutDemarrageNucleaireParMW = 28 #(€/MW)
PnomUniteNucleaire = 1000 #(MW)
PminNucleaire = 0.4 #(%)
MinUpTimeNucleaire = 12 #(h) 
MinDownTimeNucleaire = 12 #(h)

coutMarginalGaz = 210 #(€/MWh)
coutDemarrageGazParMW = 278 #(€/MW)
PnomUniteGaz = 100 #(MW)
PminGaz = 0.4 #(%)
MinUpTimeGaz = 2 #(h)
MinDownTimeGaz = 2 #(h)

coutMarginalEffacement = 500 #(€/MWh)
coutDemarrageEffacementParMW = 0 #(€/MW)
PnomUniteEffacement = 100 #(MW)
PminEffacement = 0 #(sur 1)  
MinUpTimeEffacement = 6 #(h) 
MinDownTimeEffacement = 1 #(h)


# ** Capacites installees pour le thermique (exprimees en MW) **
# NB : arrondi par defaut si pas un multiple de la puissance nominale d'une unite

CapaNucleaire_A = 39100 
CapaGaz_A = 18100
CapaEffacement_A = 11400

CapaNucleaire_B = 0
CapaGaz_B = 74700
CapaEffacement_B = 11400

# ** Capacites installees du renouvelable (exprimees en MW) **   

CapaSolarPV_A = 90000 
CapaWindOffshore_A = 36100
CapaWindOnshore_A = 51500

CapaSolarPV_B = 196600
CapaWindOffshore_B = 79100
CapaWindOnshore_B = 193000

# ** Tailles de reservoir pour chaque zone (exprimees en MWh) **

ReservoirA = 10100000
ReservoirB = 917500
ReservoirStepA = 218500
ReservoirStepB = 834000 

# ** Puissances des turbines et pompes (exprimees en MW) **

PuissanceTurbine_A = 21600 
PuissanceTurbine_B = 5300

PuissanceTurbine_StepA = 10000 
PuissanceTurbine_StepB = 15000

PuissancePompage_StepA = 10000 
PuissancePompage_StepB = 15000

# ** Efficacites des pompes **

EfficacitePompe_StepA = 0.8
EfficacitePompe_StepB = 0.8

# ** Couts de unsupplied et de spilled (exprimes en €/MWh) **

cout_unsupplied = 15000
coutEcretementA = 1
coutEcretementB = 1

# ** Transmission de la liaison France-Allemagne 

liaisonFranceAllemagne = 6000 #MW
coutLiaisonFranceAllemagne = 2 #(€/MWh)

# *** Definition des principaux chemins ***

# Dans l'ordre : 
# - dossier où seront crees les prochaines etudes generees
# - dossier où puiser pour recuperer les TS 
# - chemin vers le solver (aller fouiller dans le dossier RTE dans les programmes si different)



chemin_vers_studies <- dirname(getSourceEditorContext()$path)
chemin_vers_etude = paste(chemin_vers_studies, nom_etude, sep = "/")
chemin_vers_donnees <- paste(chemin_vers_studies,"/Donnees", sep ="")
setSolverPath(path = "C:/Program Files/RTE/Antares/8.2.2/bin/antares-8.2-solver.exe")

# *** Version d'antares utilisee *** (Pas necessairement celle qui apparait dans le chemin vers le solver)

version_etude = "8.1.0"
} 
  
# *** Creation de l'etude  : ~ 15 secondes par etude *** 

{
dir.create(chemin_vers_studies, showWarnings = F, recursive = T, mode = "0777")
unlink(paste(chemin_vers_etude, nom_etude, sep = "/"), recursive = T)
createStudy(chemin_vers_etude, study_name = nom_etude, antares_version = version_etude)
  

# *** import des series temporelles ***

# fait à la main, transvasees dans donnees

# *** Gestion des paramètres generaux ***


infini = 999999
MonteCarloYears = 1

updateGeneralSettings(mode = "Economy", # Economy, Adequacy, Draft
                      horizon = 2018,            #NULL,  #Reference year (static tag, not used in the calculations)
                      nbyears = MonteCarloYears,              #Number of Monte-Carlo years that should be prepared for the simulation (not always the same as the Number of MC years actually simulated
                      #                      nbyears = 20,              #Number of Monte-Carlo years that should be prepared for the simulation (not always the same as the Number of MC years actually simulated
                      simulation.start = 1,     #NULL, #First day of the simulation (e.g. 8 for a simulation beginning on the second week of the first month of the year) 
                      simulation.end = 365,     #NULL, #Last day of the simulation (e.g. 28 for a simulation ending on the fourth week of the first month of the year)
                      #                      january.1st = "Thursday", #NULL, #First day of the year (Mon, Tue, etc.)
                      january.1st = NULL ,      #NULL, #First day of the year (Mon, Tue, etc.)
                      first.month.in.year = "january" , #NULL,  #Actual month by which the Time-series begin (Jan to Dec, Oct to Sep, etc.)
                      first.weekday = "Monday", #NULL, #In economy or adequacy simulations, indicates the frame (Mon- Sun, Sat-Fri, etc.) to use for the edition of weekly results.
                      leapyear = FALSE,         #NULL, # (TRUE/FALSE) indicates whether February has 28 or 29 days
                      year.by.year = FALSE,      #FALSE,  #(False) No individual results will be printed out, (True) For each simulated year, detailed results will be printed out in an individual directory7 : Study_name/OUTPUT/simu_tag/Economy /mc-i-number
                      derated = FALSE,    #NULL,  #Soit Automatic (tirage des annees Monte-Carlo au hasard), Custom (Mix en tirage aleatoire et deterministe,
                      ###reglable dans le MC Scenario Builder) ou Derated (Moyenne sur toutes les series)
                      custom.ts.numbers= TRUE, ## PAS SUR A QUOI CELA REFERE : Hypothese : Nombre de series a prendre en comtpe si Custom precedemmment
                      user.playlist = TRUE, #NULL, # # Devrait faire reference a Configure --> MC Playlist 
                      #LVfiltering = FALSE, #NULL, ## Correspond a Configure --> Filtering on simulation results, permet d'ouvir plusieurs fenêtres lors de la fin d'une simulation
                      active.rules.scenario = "default ruleset",  # # On ne sait pas vers ou ca mene (dans le fichier txt settings->generaldata ca donne "default_ruleset")
                      generate = c("thermal"), # # Permet de savoir quelle sont les series qui seroont generees par Antares (en gros permet d'enlever le statut Ready-made)
                      nbtimeseriesload = 1, #NULL,   Fixe le nombre de load a simuler si stochastique
                      nbtimeserieshydro = 1, #NULL, # idem
                      nbtimeserieswind = 1, #NULL,  # idem
                      nbtimeseriesthermal = 1, #NULL, # idem
                      nbtimeseriessolar = 1, #NULL,  # idem
                      refreshtimeseries = NULL, ## controle le parametre refresh du tableau de l'onglet Simulation
                      intra.modal = NULL,  # # Controle les parametres intra et inter modal du tableau de l'onglet simulation
                      inter.modal = NULL,  #
                      refreshintervalload = 100,    #NULL, # Controle le refresh span de load
                      refreshintervalhydro = 100,   #NULL, # idem
                      refreshintervalwind = 100,    #NULL, # idem
                      refreshintervalthermal = 100, #NULL, # idem
                      refreshintervalsolar = 100,   #NULL, # idem
                      readonly = FALSE,      #NULL,  #
                      opts = antaresRead::simOptions())


# *** Gestion des paramètres d'optimisation ***

updateOptimizationSettings(
  simplex.range = NULL,
  transmission.capacities = NULL,
  include.constraints = NULL,
  include.hurdlecosts = NULL,
  include.tc.min.stable.power = NULL,
  include.tc.min.up.down.time = NULL,
  include.dayahead = NULL,
  include.strategicreserve = NULL,
  include.spinningreserve = NULL,
  include.primaryreserve = NULL,
  include.exportmps = NULL,
  power.fluctuations = 'free modulations',
  shedding.strategy = NULL,
  shedding.policy = 'shave peaks',
  unit.commitment.mode = 'accurate',
  number.of.cores.mode = 'high',
  renewable.generation.modelling = 'clusters',
  day.ahead.reserve.management = NULL,
  opts = antaresRead::simOptions()
)

# *** Modification du paramètre avance hydro-heuristic-policy : regle sur "maximize generation" ou 'accommodate rule curves' ***

cheminParametres<-paste(chemin_vers_studies, nom_etude, "settings", sep="/")
parametres <- antaresEditObject::readIniFile(file = file.path(cheminParametres, "generaldata.ini"))
parametres$`other preferences`[["hydro-heuristic-policy"]] = "accommodate rule curves"
writeIni(listData = parametres,
         pathIni = file.path(cheminParametres, "generaldata.ini"),
         overwrite = TRUE)

# *** Creation des areas ***

names_Area <- c("A", "B", "STEP A", "STEP B")
colors_Area <- rep(c("orange", "blue", "green"), c(2,3,1))
average_unsupplied_energy_costs_Area = rep(c(cout_unsupplied,0), c(2,4))
average_spilled_energy_costs_Area =  rep(c(coutEcretementA, coutEcretementB, 0, 0, 0), c(1,1,2,1,1))
localizations_Area = list(c(0,0), c(100,0), c(-100, 0), c(200,0), c(0,-100), c(-100,-100))

nombre_Area = length(names_Area)

for (i in 1:nombre_Area){
  shedding_status = !(names_Area[[i]] %in% c("STEP A", "STEP B"))
  createArea(
    name = names_Area[i],
    color = colors_Area[i],
    localization = localizations_Area[[i]],
    nodalOptimizationOptions(
      non_dispatchable_power = shedding_status,
      dispatchable_hydro_power = shedding_status,
      other_dispatchable_power = shedding_status,
      spread_unsupplied_energy_cost = 0,
      spread_spilled_energy_cost = 0,
      average_unsupplied_energy_cost = average_unsupplied_energy_costs_Area[i],
      average_spilled_energy_cost = average_spilled_energy_costs_Area[i] 
    ), 
    filtering = filteringOptions(),
    overwrite = TRUE,
    opts = antaresRead::simOptions()
  )
}

# *** Creation des links ***
# 
links = list(c("STEP A", "A"), c("A", "B"), c("B", "STEP B"))

dataLinks = list(
  matrix(data = rep(c(infini,infini,0, 0, 0, 0, 0, 0), each=8760), ncol=8),
  matrix(data = rep(c(liaisonFranceAllemagne,liaisonFranceAllemagne,coutLiaisonFranceAllemagne, coutLiaisonFranceAllemagne, 0, 0, 0, 0), each=8760), ncol=8),
  matrix(data = rep(c(infini,infini,0, 0, 0, 0, 0, 0), each=8760), ncol=8)
)

nombre_Links = length(links)

for (i in 1:nombre_Links){
  createLink(
    from =links[[i]][1], 
    to = links[[i]][2],
    propertiesLink = propertiesLinkOptions(
      hurdles_cost = (i==2)+(i==3),
      transmission_capacities = "enabled",
      asset_type = "ac",
      display_comments = TRUE,
      filter_synthesis = c("hourly", "daily", "weekly", "monthly", "annual"),
      filter_year_by_year = c("hourly", "daily", "weekly", "monthly", "annual")
    ),
    dataLink = dataLinks[[i]],
    overwrite = TRUE,
    opts = antaresRead::simOptions()
  )
}

# *** Creation des clusters de thermal *** 

nbUnitesNucleaire_A = CapaNucleaire_A%/%PnomUniteNucleaire
nbUnitesGaz_A = CapaGaz_A%/%PnomUniteGaz
nbUnitesNucleaire_B = CapaNucleaire_B%/%PnomUniteNucleaire
nbUnitesGaz_B = CapaGaz_B%/%PnomUniteGaz
nbUnitesEffacement_A = CapaEffacement_A%/%PnomUniteEffacement
nbUnitesEffacement_B = CapaEffacement_B%/%PnomUniteEffacement

nbClusterNucleaire_A = nbUnitesNucleaire_A%/%100 + as.integer(PnomUniteGaz*nbUnitesNucleaire_A%/%100!=CapaNucleaire_A)
nbClusterGaz_A = nbUnitesGaz_A%/%100 + as.integer(PnomUniteGaz*nbUnitesGaz_A%/%100!=CapaGaz_A)
nbClusterNucleaire_B = nbUnitesNucleaire_B%/%100 + as.integer(PnomUniteGaz*nbUnitesNucleaire_B%/%100!=CapaNucleaire_B)
nbClusterGaz_B = nbUnitesGaz_B%/%100 + as.integer(PnomUniteGaz*nbUnitesGaz_B%/%100!=CapaGaz_B)
nbClusterEffacement_A = nbUnitesEffacement_A%/%100 + as.integer(PnomUniteEffacement*nbUnitesEffacement_A%/%100!=CapaEffacement_A)
nbClusterEffacement_B = nbUnitesEffacement_B%/%100 + as.integer(PnomUniteEffacement*nbUnitesEffacement_B%/%100!=CapaEffacement_B)

nbUnitesResteNucleaire_A = nbUnitesNucleaire_A%%100
nbUnitesResteGaz_A = nbUnitesGaz_A%%100
nbUnitesResteNucleaire_B = nbUnitesNucleaire_B%%100
nbUnitesResteGaz_B = nbUnitesGaz_B%%100
nbUnitesResteEffacement_A = nbUnitesEffacement_A%%100
nbUnitesResteGaz_B = nbUnitesEffacement_B%%100


clusters_thermal= list()
centUnites = 100

# GAZ A

if(nbUnitesGaz_A%%100!=0){
  for(k in 1:(nbUnitesGaz_A%/%100)){
    clusters_thermal = append(clusters_thermal, 
      c("A", "Gas", paste("Gaz", k), unitcount = centUnites, nominal = PnomUniteGaz,  minpower = PminGaz*PnomUniteGaz, minuptime = MinUpTimeGaz, MinDownTimeGaz, mustrun = "FALSE", coutmarg = coutMarginalGaz, coutdemar = coutDemarrageGazParMW*PnomUniteGaz, prix = coutMarginalGaz))
  }
  clusters_thermal = append(clusters_thermal,
      c("A", "Gas", paste("Gaz", k+1), unitcount = nbUnitesGaz_A%%100, nominal = PnomUniteGaz,  minpower = PminGaz*PnomUniteGaz, minuptime = MinUpTimeGaz, MinDownTimeGaz, mustrun = "FALSE", coutmarg = coutMarginalGaz, coutdemar = coutDemarrageGazParMW*PnomUniteGaz, prix = coutMarginalGaz))
}

if(nbUnitesGaz_A%%100==0 && nbUnitesGaz_A !=0){
    clusters_thermal = append(clusters_thermal, 
      c("A", "Gas", paste("Gaz", 1), unitcount = nbUnitesGaz_A, nominal = PnomUniteGaz,  minpower = PminGaz*PnomUniteGaz, minuptime = MinUpTimeGaz, MinDownTimeGaz, mustrun = "FALSE", coutmarg = coutMarginalGaz, coutdemar = coutDemarrageGazParMW*PnomUniteGaz, prix = coutMarginalGaz))
}


# NUC A

if(nbUnitesNucleaire_A%/%100!=0){
  for(k in 1:(nbUnitesNucleaire_A%/%100)){
    clusters_thermal = append(clusters_thermal, 
      c("A", "Nuclear", paste("Nucleaire", k), unitcount = centUnites, nominal = PnomUniteNucleaire,  minpower = PminNucleaire*PnomUniteNucleaire, minuptime = MinUpTimeNucleaire, MinDownTimeNucleaire, mustrun = "FALSE", coutmarg = coutMarginalNucleaire, coutdemar = coutDemarrageNucleaireParMW*PnomUniteNucleaire, prix = coutMarginalNucleaire))
  }
  clusters_thermal = append(clusters_thermal,
                            c("A", "Nuclear", paste("Nucleaire", k+1), unitcount = nbUnitesNucleaire_A%%100, nominal = PnomUniteNucleaire,  minpower = PminNucleaire*PnomUniteNucleaire, minuptime = MinUpTimeNucleaire, MinDownTimeNucleaire, mustrun = "FALSE", coutmarg = coutMarginalNucleaire, coutdemar = coutDemarrageNucleaireParMW*PnomUniteNucleaire, prix = coutMarginalNucleaire))
}

if(nbUnitesNucleaire_A%/%100==0 && nbUnitesNucleaire_A !=0){
    clusters_thermal = append(clusters_thermal, 
                              c("A", "Nuclear", paste("Nucleaire", 1), unitcount = nbUnitesNucleaire_A, nominal = PnomUniteNucleaire,  minpower = PminNucleaire*PnomUniteNucleaire, minuptime = MinUpTimeNucleaire, MinDownTimeNucleaire, mustrun = "FALSE", coutmarg = coutMarginalNucleaire, coutdemar = coutDemarrageNucleaireParMW*PnomUniteNucleaire, prix = coutMarginalNucleaire))
}


# GAZ B

if(nbUnitesGaz_B%/%100!=0){
  for(k in 1:(nbUnitesGaz_B%/%100)){
    clusters_thermal = append(clusters_thermal, 
                              c("B", "Gas", paste("Gaz", k), unitcount = centUnites, nominal = PnomUniteGaz,  minpower = PminGaz*PnomUniteGaz, minuptime = MinUpTimeGaz, MinDownTimeGaz, mustrun = "FALSE", coutmarg = coutMarginalGaz, coutdemar = coutDemarrageGazParMW*PnomUniteGaz, prix = coutMarginalGaz))
  }
  clusters_thermal = append(clusters_thermal,
                            c("B", "Gas", paste("Gaz", k+1), unitcount = nbUnitesGaz_B%%100, nominal = PnomUniteGaz,  minpower = PminGaz*PnomUniteGaz, minuptime = MinUpTimeGaz, MinDownTimeGaz, mustrun = "FALSE", coutmarg = coutMarginalGaz, coutdemar = coutDemarrageGazParMW*PnomUniteGaz, prix = coutMarginalGaz))
}

if(nbUnitesGaz_B%/%100==0 && nbUnitesGaz_B !=0){
    clusters_thermal = append(clusters_thermal, 
                              c("B", "Gas", paste("Gaz", 1), unitcount = nbUnitesGaz_B, nominal = PnomUniteGaz,  minpower = PminGaz*PnomUniteGaz, minuptime = MinUpTimeGaz, MinDownTimeGaz, mustrun = "FALSE", coutmarg = coutMarginalGaz, coutdemar = coutDemarrageGazParMW*PnomUniteGaz, prix = coutMarginalGaz))
}

# NUC B

if(nbUnitesNucleaire_B%/%100!=0){
  for(k in 1:(nbUnitesNucleaire_B%/%100)){
    clusters_thermal = append(clusters_thermal, 
                              c("B", "Nuclear", paste("Nucleaire", k), unitcount = centUnites, nominal = PnomUniteNucleaire,  minpower = PminNucleaire*PnomUniteNucleaire, minuptime = MinUpTimeNucleaire, MinDownTimeNucleaire, mustrun = "FALSE", coutmarg = coutMarginalNucleaire, coutdemar = coutDemarrageNucleaireParMW*PnomUniteNucleaire, prix = coutMarginalNucleaire))
  }
  clusters_thermal = append(clusters_thermal,
                            c("B", "Nuclear", paste("Nucleaire", k+1), unitcount = nbUnitesNucleaire_B%%100, nominal = PnomUniteNucleaire,  minpower = PminNucleaire*PnomUniteNucleaire, minuptime = MinUpTimeNucleaire, MinDownTimeNucleaire, mustrun = "FALSE", coutmarg = coutMarginalNucleaire, coutdemar = coutDemarrageNucleaireParMW*PnomUniteNucleaire, prix = coutMarginalNucleaire))
}

if(nbUnitesNucleaire_B%/%100==0 && nbUnitesNucleaire_B !=0){
    clusters_thermal = append(clusters_thermal, 
                              c("B", "Nuclear", paste("Nucleaire", 1), unitcount = nbUnitesNucleaire_B, nominal = PnomUniteNucleaire,  minpower = PminNucleaire*PnomUniteNucleaire, minuptime = MinUpTimeNucleaire, MinDownTimeNucleaire, mustrun = "FALSE", coutmarg = coutMarginalNucleaire, coutdemar = coutDemarrageNucleaireParMW*PnomUniteNucleaire, prix = coutMarginalNucleaire))
}

# Effacement A

if(nbUnitesEffacement_A%%100!=0){
  for(k in 1:(nbUnitesEffacement_A%/%100)){
    clusters_thermal = append(clusters_thermal, 
                              c("A", "Other", paste("Effacement", k), unitcount = centUnites, nominal = PnomUniteEffacement,  minpower = PminEffacement*PnomUniteEffacement, minuptime = MinUpTimeEffacement, MinDownTimeEffacement, mustrun = "FALSE", coutmarg = coutMarginalEffacement, coutdemar = coutDemarrageEffacementParMW*PnomUniteEffacement, prix = coutMarginalEffacement))
  }
  clusters_thermal = append(clusters_thermal,
                            c("A", "Other", paste("Effacement", k+1), unitcount = nbUnitesEffacement_A%%100, nominal = PnomUniteEffacement,  minpower = PminEffacement*PnomUniteEffacement, minuptime = MinUpTimeEffacement, MinDownTimeEffacement, mustrun = "FALSE", coutmarg = coutMarginalEffacement, coutdemar = coutDemarrageEffacementParMW*PnomUniteEffacement, prix = coutMarginalEffacement))
}

if(nbUnitesEffacement_A%%100==0 && nbUnitesEffacement_A !=0){
  clusters_thermal = append(clusters_thermal, 
                            c("A", "Other", paste("Effacement", 1), unitcount = nbUnitesEffacement_A, nominal = PnomUniteEffacement,  minpower = PminEffacement*PnomUniteEffacement, minuptime = MinUpTimeEffacement, MinDownTimeEffacement, mustrun = "FALSE", coutmarg = coutMarginalEffacement, coutdemar = coutDemarrageEffacementParMW*PnomUniteEffacement, prix = coutMarginalEffacement))
}

# Effacement B

if(nbUnitesEffacement_B%%100!=0){
  for(k in 1:(nbUnitesEffacement_B%/%100)){
    clusters_thermal = append(clusters_thermal, 
                              c("B", "Other", paste("Effacement", k), unitcount = centUnites, nominal = PnomUniteEffacement,  minpower = PminEffacement*PnomUniteEffacement, minuptime = MinUpTimeEffacement, MinDownTimeEffacement, mustrun = "FALSE", coutmarg = coutMarginalEffacement, coutdemar = coutDemarrageEffacementParMW*PnomUniteEffacement, prix = coutMarginalEffacement))
  }
  clusters_thermal = append(clusters_thermal,
                            c("B", "Other", paste("Effacement", k+1), unitcount = nbUnitesEffacement_B%%100, nominal = PnomUniteEffacement,  minpower = PminEffacement*PnomUniteEffacement, minuptime = MinUpTimeEffacement, MinDownTimeEffacement, mustrun = "FALSE", coutmarg = coutMarginalEffacement, coutdemar = coutDemarrageEffacementParMW*PnomUniteEffacement, prix = coutMarginalEffacement))
}

if(nbUnitesEffacement_B%%100==0 && nbUnitesEffacement_B !=0){
  clusters_thermal = append(clusters_thermal, 
                            c("B", "Other", paste("Effacement", 1), unitcount = nbUnitesEffacement_B, nominal = PnomUniteEffacement,  minpower = PminEffacement*PnomUniteEffacement, minuptime = MinUpTimeEffacement, MinDownTimeEffacement, mustrun = "FALSE", coutmarg = coutMarginalEffacement, coutdemar = coutDemarrageEffacementParMW*PnomUniteEffacement, prix = coutMarginalEffacement))
}


lg = 12 # Nombre d'info pour chaque cluster
nombre_clusters_thermal = length(clusters_thermal)/lg
TS_clusters_thermal_list = rep(NULL, times = nombre_clusters_thermal)



for (i in 0:(nombre_clusters_thermal-1)){
  createCluster(
    area                = clusters_thermal[[i*lg+1]], 
    group               = clusters_thermal[[i*lg+2]], 
    cluster_name        = clusters_thermal[[i*lg+3]], 
    unitcount           = as.integer(clusters_thermal[[i*lg+4]]),
    nominalcapacity     = as.numeric(clusters_thermal[[i*lg+5]]),
    'min-stable-power'  = as.numeric(clusters_thermal[[i*lg+6]]),
    'min-up-time'       = as.integer(clusters_thermal[[i*lg+7]]),
    'min-down-time'     = as.integer(clusters_thermal[[i*lg+8]]),
    'must-run'          = as.logical(clusters_thermal[[i*lg+9]]), 
    'marginal-cost'     = as.numeric(clusters_thermal[[i*lg+10]]),
    'startup-cost'      = as.numeric(clusters_thermal[[i*lg+11]]),
    'market-bid-cost'   = as.numeric(clusters_thermal[[i*lg+12]]) ,
                                     
    add_prefix = F,                                 
    time_series = TS_clusters_thermal_list[[i]], 
    overwrite = TRUE
  )
}


# *** Creation des clusters de renewable *** 


cluster_RES_list = list(
  c("A", "Solar PV", "Solar PV", "1", CapaSolarPV_A), 
  c("A", "Wind Offshore", "Wind Offshore", "1", CapaWindOffshore_A), 
  c("A", "Wind Onshore", "Wind Onshore", "1", CapaWindOnshore_A), 
  c("B", "Solar PV", "Solar PV", "1", CapaSolarPV_B), 
  c("B", "Wind Offshore", "Wind Offshore", "1", CapaWindOffshore_B), 
  c("B", "Wind Onshore", "Wind Onshore", "1", CapaWindOnshore_B)
  )

nombre_clusters_RES = length(cluster_RES_list)

for (i in 1:nombre_clusters_RES){
  fichier_a_lire = file.path(chemin_vers_donnees, "renewables", "series", tolower(cluster_RES_list[[i]][1]),tolower(cluster_RES_list[[i]][2]), paste0("series", ".txt", sep = ""))
  createClusterRES(
    area              = cluster_RES_list[[i]][1], 
    cluster_name      = cluster_RES_list[[i]][2],
    group             = cluster_RES_list[[i]][3], 
    unitcount         = as.integer(cluster_RES_list[[i]][4]),
    nominalcapacity   = as.numeric(cluster_RES_list[[i]][5]), 
    ts_interpretation = "production-factor",
    time_series = read.table(fichier_a_lire, header = F, sep = "\t"), 
    add_prefix = F, 
    overwrite = TRUE
    ) 
}


# *** Creation de la load *** 

if(translation){
  prefixe = "loadTranslation_"
}

else{
  prefixe = "load_"
}

setwd(paste(chemin_vers_donnees, "load/series", sep = "/"))

for(i in 1:nombre_Area){
  if (names_Area[[i]] == "A" || names_Area[[i]] == "B"){
    writeInputTS(
      data = read.table(paste(prefixe, tolower(names_Area[[i]]), ".txt", sep = ""), header = F),
      type = "load",
      area = names_Area[[i]],
      overwrite = TRUE,
    )
  }
}


# *** Creation de l'hydro *** 

# ** Gestion des TS **

listeInput = list() # liste qui me permet de conserver les bornes min et max lues 


for(i in 1:nombre_Area){
  if (names_Area[[i]] == "A" || names_Area[[i]] == "B"){
  setwd(paste(chemin_vers_donnees, "hydro/series", names_Area[[i]], sep = "/"))
  writeInputTS(
    data = read.table("ror.txt", header = F),
    type = "hydroROR",
    area = names_Area[[i]],
    overwrite = TRUE,
  )
  }
  
}


for(i in 1:nombre_Area){
  if (names_Area[[i]] == "A" || names_Area[[i]] == "B"){
  setwd(paste(chemin_vers_donnees, "hydro/series", names_Area[[i]], sep = "/"))
  writeInputTS(
    data = read.table("mod.txt", header = F),
    type = "hydroSTOR",
    area = names_Area[[i]],
    overwrite = TRUE,
  )
  }
}

# ** Gestion de la section "Management options ** 

# * Definition de water_values

water_values <- function (inputPath,node,valeur = 0)
  # This funciton allows us to assign the water values to a zone 
{
  maxpower <- matrix(data = rep(rep(x=valeur, times = 101), each = 365), ncol = 101)
  # Matrix holding the water values
  
  utils::write.table(
    x = maxpower, row.names = FALSE, col.names = FALSE, sep = "\t",
    file = file.path(inputPath, "hydro", "common", "capacity", paste0("waterValues_", node, ".txt"))
    # Linking to the Antares files
  )
}

# * Definition de config_hydroSTOR *

config_hydroSTOR<-function(inputPath,node,follow_load=TRUE,hard_bounds=FALSE,IDB=1,IDM=24,IMB= 1, reservoir_date= 0, reservoir_management= TRUE,pumping_effi = 0.75,
                           reservoir_capacity,use_water=FALSE, use_heuristic= TRUE,Power_turb,Power_pump=0,waterValues)
{

  node <- tolower(node)
  inputPath <- paste(chemin_vers_studies, nom_etude, "input", sep="/")
  
  hydro <- antaresEditObject::readIniFile(file = file.path(inputPath, "hydro", "hydro.ini"))

  hydro$'follow load'[[node]] <- follow_load
  hydro$`inter-daily-breakdown`[[node]] <- IDB
  hydro$`intra-daily-modulation`[[node]] <- IDM
  hydro$`inter-monthly-breakdown`[[node]] <- IMB
  hydro$`initialize reservoir date`[[node]] <- reservoir_date
  hydro$`reservoir`[[node]]<-reservoir_management 
  hydro$`pumping efficiency`[[node]] <- pumping_effi 
  hydro$`reservoir capacity`[[node]]<-reservoir_capacity 
  hydro$`use water`[[node]] <- use_water
  hydro$`use heuristic`[[node]] <- use_heuristic
  hydro$`hard bounds`[[node]] <- hard_bounds
  
  writeIni(listData = hydro,
           pathIni = file.path(inputPath, "hydro", "hydro.ini"),
           overwrite = TRUE)
  
  maxpower <- matrix(data = rep(c(Power_turb, 24, Power_pump, 24), each = 365), ncol = 4)
  utils::write.table(
    x = maxpower, row.names = FALSE, col.names = FALSE, sep = "\t",
    file = file.path(inputPath, "hydro", "common", "capacity", paste0("maxpower_", node, ".txt"))
  )
  
  water_values(valeur=waterValues, inputPath = inputPath,node = node)
  
  fichier_a_lire = file.path(chemin_vers_donnees, "hydro", "common", "capacity", paste0("reservoir_", tolower(node), ".txt"))
  
  df =read.table(fichier_a_lire, header = F, sep = "\t")
  utils::write.table(
    x = df,
    file = file.path(inputPath, "hydro", "common", "capacity", paste0("reservoir_", tolower(node), ".txt")),
    sep = "\t",
    row.names = F,
    col.names = F
 
  )
  }
 
# * Appel de config_hydroSTOR sur chaque noeud * 

config_hydroSTOR(inputPath,node="A",follow_load = TRUE ,hard_bounds=TRUE,IDB =1 ,IDM = 3,IMB =1 ,reservoir_date =0 ,reservoir_management =TRUE ,
                 pumping_effi =1 ,reservoir_capacity = ReservoirA,use_water =FALSE ,use_heuristic = TRUE,Power_turb = PuissanceTurbine_A, Power_pump = 0, waterValues = 0)

config_hydroSTOR(inputPath,node="B",follow_load = TRUE ,hard_bounds=TRUE,IDB =1 ,IDM = 3,IMB =1 ,reservoir_date =0 ,reservoir_management =TRUE ,
                 pumping_effi =1 ,reservoir_capacity = ReservoirB,use_water =FALSE ,use_heuristic = TRUE,Power_turb = PuissanceTurbine_B, Power_pump = 0, waterValues = 0)

config_hydroSTOR(inputPath,node="STEP A",follow_load = FALSE ,hard_bounds=FALSE,IDB =1 ,IDM = 24,IMB =1 ,reservoir_date =0 ,reservoir_management =TRUE ,
                 pumping_effi =EfficacitePompe_StepA ,reservoir_capacity = ReservoirStepA,use_water =TRUE ,use_heuristic = FALSE,Power_turb = PuissanceTurbine_StepA, Power_pump = PuissancePompage_StepA, waterValues = 1)

config_hydroSTOR(inputPath,node="STEP B",follow_load = FALSE ,hard_bounds=FALSE,IDB =1 ,IDM = 24,IMB =1 ,reservoir_date =0 ,reservoir_management =TRUE ,
                 pumping_effi =EfficacitePompe_StepB ,reservoir_capacity = ReservoirStepB,use_water =TRUE ,use_heuristic = FALSE,Power_turb = PuissanceTurbine_StepB, Power_pump = PuissancePompage_StepB, waterValues = 1)

# *** Scenario builder *** 
{
vector_areas <- getAreas() 
vector_exclude_scenarios_hydro <- tolower(c("STEP A", "STEP B")) ## choix des marqueurs nous permettant de supprimer les zones sans scenarios
vector_exclude_scenarios <- tolower(c("STEP A", "STEP B")) ## choix des marqueurs nous permettant de supprimer les zones sans scenarios
vector_scenario_hydro <- c()
vector_rand_hydro <- c()
vector_scenario <- c()
vector_rand <- c()
for (areas_study in vector_areas){ 
  marqueur <- 0 # initialisation du marqueur permettant de rep?rer quelles zones ne sont pas ? sc?narios
  for (exclude_market in vector_exclude_scenarios){
    if (areas_study %in% vector_exclude_scenarios){ ## test si le nom de la zone contient les marqueurs d exclusion d?sign?s
      marqueur <- marqueur +1 ## sauvegarde dans marqueur
    }
  }
  if (marqueur >0){ # si le marqueur est superieur a 1, alors cette zone n a pas de scenarios
    vector_rand <- c(vector_rand, areas_study) # ajout aux zones randoms
  }else{
    vector_scenario <- c(vector_scenario, areas_study) ## sinon ajout aux zones avec scenarios
  }
}

# pareil pour les scenarios hydros
for (areas_study in vector_areas){ 
  marqueur <- 0 # initialisation du marqueur permettant de reperer quelles zones ne sont pas ? sc?narios
  for (exclude_market in vector_exclude_scenarios_hydro){
    if (grepl(pattern = exclude_market, areas_study)== TRUE){ ## test si le nom de la zone contient les marqueurs d exclusion d?sign?s
      marqueur <- marqueur +1 ## sauvegarde dans marqueur
    }
  }
  if (marqueur >0){ # si le marqueur est superieur a 1, alors cette zone n a pas de scenarios
    vector_rand_hydro <- c(vector_rand_hydro, areas_study) # ajout aux zones randoms
  }else{
    vector_scenario_hydro <- c(vector_scenario_hydro, areas_study) ## sinon ajout aux zones avec scenarios
  }
}

#1--> 1982 ; 15 --> 1996 ; 25 -->2006 et 35-->2016
if(MonteCarloYears <=1){
  choice_year <- choice_year # choix annee
  # construction scenarioBuilder
  sbuilder_general <- scenarioBuilder(
    n_scenario = MonteCarloYears,
    n_mc = choice_year,
    areas = vector_scenario,
    areas_rand = vector_rand
  )
  # construction scenarioBuilder pour le cas specifique hydro
  sbuilder_hydro <- scenarioBuilder(
    n_scenario = MonteCarloYears,
    n_mc = choice_year,
    areas = vector_scenario_hydro,
    areas_rand = vector_rand_hydro
  )
  # boucle pour ajouter quelle annee nous souhaitons utiliser pour les zones non random
  for (n in names(sbuilder_general[,1])){
    if (sbuilder_general[,1][n]!= "rand"){
      sbuilder_general[,1][n] <- as.character(choice_year)
    }
  }
  for (n in names(sbuilder_hydro[,1])){
    if (sbuilder_hydro[,1][n]!= "rand"){
      sbuilder_hydro[,1][n] <- as.character(choice_year)
    }
  }
} else {  
  # boucle annee
  vector_year_scenario <- c(seq(1:MonteCarloYears))
  # construction scenarioBuilder
  sbuilder_general <- scenarioBuilder(
    n_scenario =  MonteCarloYears,
    n_mc = MonteCarloYears,
    areas = vector_scenario,
    areas_rand = vector_rand
  )
  # construction scenarioBuilder pour le cas specifique hydro
  sbuilder_hydro <- scenarioBuilder(
    n_scenario = MonteCarloYears,
    n_mc = MonteCarloYears,
    areas = vector_scenario_hydro,
    areas_rand = vector_rand_hydro
  )
  # boucle pour ajouter quelle annee nous souhaitons utiliser pour les zones non random
  for(i in 1:length(choice_year))
  {
    for (n in names(sbuilder_general[,i])){
      if (sbuilder_general[,i][n]!= "rand"){
        sbuilder_general[,i][n] <- as.character(choice_year[i])
      }
    }
    for (n in names(sbuilder_hydro[,i])){
      if (sbuilder_hydro[,i][n]!= "rand"){
        sbuilder_hydro[,i][n] <- as.character(choice_year[i])
      }
    }
  }
}# end to if-else relating to MC years

updateScenarioBuilder(
  ldata = sbuilder_general,
  series = c("load", "renewables") 
)
updateScenarioBuilder(
  ldata = sbuilder_hydro,
  series = c("hydro") 
)
}
}
  
# *** Contrainte fortes pour DSR ***
if(Effacement){
 
name = paste("contrainte effacement journalier ","A", sep = "")  

createBindingConstraint(
  name,
  id = tolower(name),
  values = matrix(data = rep(MinUpTimeEffacement* get(paste("CapaEffacement", toupper("a"), sep = "_" )[1]), 365 * 3), ncol = 3),
  # values =  matrix(data = rep(c(0, MinUpTimeEffacement* get(paste("CapaEffacement", toupper("a"), sep = "_" )[1]), 0), each = 365), ncol = 3),
  enabled = TRUE,
  timeStep = c("daily"),
  operator = c("less"),
  coefficients = c("A.effacement 1" = 1,
                   "A.effacement 2" = 1),
                   overwrite = T
                   
)
  
name = paste("contrainte effacement journalier ","B", sep = "")  

createBindingConstraint(
  name,
  id = tolower(name),
  values = matrix(data = rep(MinUpTimeEffacement* get(paste("CapaEffacement", toupper("a"), sep = "_" )[1]), 365 * 3), ncol = 3),
  enabled = TRUE,
  timeStep = c("daily"),
  operator = c("less"),
  coefficients = c("B.effacement 1" = 1,
                   "B.effacement 2" = 1),
  overwrite = T
)
  
}

# *** Division en districts *** 
{

texte = "

[all areas]
caption = All areas
comments = Spatial aggregates on all areas
apply-filter = add-all

[FRANCE]
caption = set1
+ = a
+ = step a


[ALLEMAGNE]
caption = set2
+ = b
+ = step b


"

cheminsets = file.path(chemin_vers_studies, nom_etude, "input", "areas", "sets.ini" )
writeLines(text = texte, con = cheminsets)

}


# *** Lancement automatique de la simulation : ~ 40 secondes par etude *** 
  print(paste("Running the simulation of study ", nom_etude, sep = ""))
  
  {
runSimulation(nom_etude, 
              mode = "economy", #"economy", "adequacy" or "draft"
              path_solver = getOption("antares.solver"), wait = TRUE,
              show_output_on_console = TRUE, parallel = FALSE,
              opts = antaresRead::simOptions())
}
# *** Definition de la derniere simulation comme simulation etudiee *** 

setSimulationPath(
  path = paste(chemin_vers_studies, nom_etude, sep = "/"),
  simulation = -1 #ou input
)

}
}

  
  
