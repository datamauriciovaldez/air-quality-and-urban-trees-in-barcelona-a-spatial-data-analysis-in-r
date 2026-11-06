#Libraries
getwd()
setwd(C:User/mauri/OneDrive/Documentos/RStudio/Datos)

library(dplyr)
library(ggplot2)
library(tidyverse)
library(readr)
library(sf)
library(osmdata)
library(leaflet)
library(devtools)


#Data Reads

#Air Quality Data ( Month & Stations)
DataEnero   <- read_csv("R Studio/Datos/Air Quality/2024_01_Gener_qualitat_aire_BCN.csv")
DataFebrero <- read_csv("R Studio/Datos/Air Quality/2024_02_Febrer_qualitat_aire_BCN.csv")
DataMarzo   <- data.frame(read_csv("R Studio/Datos/Air Quality/2024_03_Marc_qualitat_aire_BCN.csv"))
DataAbril   <- read_csv("R Studio/Datos/Air Quality/2024_04_Abril_qualitat_aire_BCN.csv")
DataJunio   <- read_csv("R Studio/Datos/Air Quality/2024_06_Juny_qualitat_aire_BCN.csv")
DataJulio   <- read_csv("R Studio/Datos/Air Quality/2024_07_Juliol_qualitat_aire_BCN.csv")
DataAgosto  <- read_csv("R Studio/Datos/Air Quality/2024_08_Agost_qualitat_aire_BCN.csv")
DataSep     <- read_csv("R Studio/Datos/Air Quality/2024_09_Setembre_qualitat_aire_BCN.csv")
DataOctubre <- read_csv("R Studio/Datos/Air Quality/2024_10_Octubre_qualitat_aire_BCN.csv")
DataEst     <- read_csv("R Studio/Datos/Stations Air Quality 2023/2023_qualitat_aire_estacions.csv")

#Trees in Green areas and Street Data
DataTGA1    <- read_csv("R Studio/Datos/Trees in green areas/2024_1T_OD_Arbrat_Parcs_BCN.csv/2024_1T_OD_Arbrat_Parcs_BCN.csv")
DataTGA2    <- read_csv("R Studio/Datos/Trees in green areas/2024_2T_OD_Arbrat_Parcs_BCN.csv/2024_2T_OD_Arbrat_Parcs_BCN.csv")
DataTGA3    <- read_csv("R Studio/Datos/Trees in green areas/2024_3T_OD_Arbrat_Parcs_BCN.csv/2024_3T_OD_Arbrat_Parcs_BCN.csv")
DataTSTR1   <- read_csv("R Studio/Datos/Trees on the street/2024_1T_OD_Arbrat_Viari_BCN.csv/2024_1T_OD_Arbrat_Viari_BCN.csv")
DataTSTR2   <- read_csv("R Studio/Datos/Trees on the street/2024_2T_OD_Arbrat_Viari_BCN.csv/2024_2T_OD_Arbrat_Viari_BCN.csv")
DataTSTR3   <- read_csv("R Studio/Datos/Trees on the street/2024_3T_OD_Arbrat_Viari_BCN.csv/2024_3T_OD_Arbrat_Viari_BCN.csv")

#Population & Surface per District
DataPD      <- read_csv("R Studio/Datos/Population and Size/Taula estadística - Població.csv")
DataSFA     <- read_csv("R Studio/Datos/Surface for each area/SuperficieKm2.csv")

DataPD      <- select(DataPD, Territori, "Tipus de territori" ,"01 Gen. 2024", "01 Febr. 2024","01 Març 2024","01 Abr. 2024","01 Maig 2024","01 Juny 2024","01 Jul. 2024")
DataPD      <- filter(DataPD, DataPD$'Tipus de territori' == "Districte")
DataPD      <- cbind(DataPD, DataSFA)

#Code Manipulations
DataTGA1 <- select(DataTGA1, codi, latitud, longitud, espai_verd, geom, codi_barri, nom_barri, codi_districte, nom_districte, categoria_arbrat)
DataTGA2 <- select(DataTGA2, codi, latitud, longitud, espai_verd, geom, codi_barri, nom_barri, codi_districte, nom_districte, categoria_arbrat)
DataTGA3 <- select(DataTGA3, codi, latitud, longitud, espai_verd, geom, codi_barri, nom_barri, codi_districte, nom_districte, categoria_arbrat)

DataTSTR1 <- select(DataTSTR1, codi, latitud, longitud, espai_verd, codi_barri, nom_barri, codi_districte, nom_districte, categoria_arbrat)
DataTSTR2 <- select(DataTSTR2, codi, latitud, longitud, espai_verd, codi_barri, nom_barri, codi_districte, nom_districte, categoria_arbrat)
DataTSTR3 <- select(DataTSTR3, codi, latitud, longitud, espai_verd, codi_barri, nom_barri, codi_districte, nom_districte, categoria_arbrat)

DataEst <- select(DataEst,Estacio, Longitud, Latitud ,ubicacio, Nom_barri)


DataTGA1 <-filter(DataTGA1, !is.na(latitud), !is.na(longitud))

barris <- st_read('https://raw.githubusercontent.com/martgnz/bcn-geodata/refs/heads/master/barris/barris.geojson')


ggplot() +
  geom_sf(data = barris, aes(fill = DISTRICTE)) +
  geom_point(data = DataTGA1, 
             aes(x = longitud, y = latitud),
             alpha = 0.8, 
             color = "black",
             shape = 21,
             stroke = 0.5,
             fill = "darkgreen")
################################################################################

Barcelona <- getbb("Barcelona, España")

Ciudad <- "Barcelona"
posicion <- 1
url <- URLencode(paste0("https://nominatim.openstreetmap.org/search.php?q=",
                        Ciudad, "&polygon_geojson=1&format=geojson"))
destfile = paste0(tempdir(), "/limits.json")
download.file(url, destfile)
Barcelona_frontera <- st_read(destfile)[posicion,]


leaflet(Barcelona_frontera) %>% 
  addTiles() %>% 
  addPolygons()


Barcelona_calles <- opq(Barcelona) %>% 
  add_osm_feature(key="highway")


Barcelona_calles <- Barcelona_calles %>% 
  osmdata_sf()


Barcelona_calles <- Barcelona_calles$osm_lines

ggplot() + 
  geom_sf(data = Barcelona_calles, color = "gray20")


Barcelona_calles_Sensores <- DataEst %>%
  mutate(Estacio = as.numeric(Estacio), )


Barcelona_calles <- st_as_sf(Barcelona_calles)

DataTGA <- merge(x = DataTGA1, y = DataTGA2, z = DataTGA3)
DataTSTR <- merge(x = DataTSTR1, y = DataTSTR2, z = DataTSTR3)


ggplot()+
  geom_sf(data = Barcelona_calles, color = "gray20")+
  geom_point(data = Barcelona_calles_Sensores,
             aes(x = Longitud, y = Latitud),
             alpha = 0.8, 
             color = "black",
             shape = 21,
             stroke = 0.5,
             fill = "red",
             size = 3
  ) +
  geom_point(data = DataTGA,
             aes(x = longitud, y = latitud),
             alpha = 0.5, 
             color = "black",
             shape = 21,
             stroke = 0.5,
             fill = "darkgreen"
  ) +
  
  
  ggplot() +
  geom_sf(data = Barcelona_calles, color = "gray20")+
  geom_point(data = DataTSTR,
             aes(x = longitud, y = latitud),
             alpha = 0.8, 
             color = "black",
             shape = 21,
             stroke = 0.5,
             fill = "skyblue1"
  ) +
  geom_point(data = Barcelona_calles_Sensores,
             aes(x = Longitud, y = Latitud),
             alpha = 0.8, 
             color = "black",
             shape = 21,
             stroke = 0.5,
             fill = "red",
             size = 3,
             position = "jitter"
  )

A_E_S <- DataEnero[complete.cases(DataEnero),]

A_E_S <- data.frame(A_E_S)

A_E_S <- select(A_E_S,ESTACIO,CODI_CONTAMINANT,ANY,MES,DIA,H01,H02,H03,H04,H05,H06,H07,H08,H09,H10,H11,H12,H13,H14,H15,H16,H17,H18,H19,H20,H21,H22,H23,H24)

A_E_S2 <- data.frame(transmute(A_E_S, H01, H02, H03, H04, H05, H06, H07, H08, H09, H10, H11, H12, H13, H14, H15, 
                   H16, H17, H18, H19, H20, H21, H22, H23, H24))


A_E_S2 <- rowSums(A_E_S2 [, c(1:24)])
A_E_S2 <- data.frame(A_E_S2)

rowSums(A_E_S2, na.rm=FALSE)



MEAN <- A_E_S2/24

A_E_S2 <- data.frame(A_E_S2)

A_E_S <- cbind(A_E_S, MEAN)





vec <- read_csv("R Studio/Datos/Stations Air Quality 2023/2023_qualitat_aire_estacions.csv")
vec <- select(vec, Estacio,Longitud,Latitud)

vec <- rename(vec, ESTACIO=Estacio)
vec <- vec[!duplicated(vec), ]


DataFull <- rbind(DataEnero, DataFebrero, DataMarzo, DataAbril, DataJunio, DataJulio, DataAgosto, DataSep, DataOctubre)


DataFull <- select(DataFull,H01,H02,H03,H04,H05,H06,H07,H08,H09,H10,H11,H12,H13,H14,H15,H16,H17,H18,H19,H20,H21,H22,H23,H24)


DataFull <- DataFull[complete.cases(DataFull),]

MEANFull <- rowSums(DataFull [, c(1:24)])


MEANFull <- DataFullness/24

DataFull <- cbind(DataFullness, MEANFull) 




