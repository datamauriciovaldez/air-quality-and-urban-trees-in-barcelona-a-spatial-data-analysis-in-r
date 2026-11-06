#Libraries
library(readr)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(sf)
library(osmdata)
library(leaflet)
library(ggmap)


##firstly, we will read/upload all of the Data Air Quality csv (January to October)##
A_E <- read.csv('data/Datos/Air Quality/2024_01_Gener_qualitat_aire_BCN.csv')
A_F <- read.csv('data/Datos/Air Quality/2024_02_Febrer_qualitat_aire_BCN.csv')
A_M <- read.csv('data/Datos/Air Quality/2024_03_Marc_qualitat_aire_BCN.csv')
A_A <- read.csv('data/Datos/Air Quality/2024_04_Abril_qualitat_aire_BCN.csv')
A_J <- read.csv('data/Datos/Air Quality/2024_06_Juny_qualitat_aire_BCN.csv')
A_J2 <- read.csv('data/Datos/Air Quality/2024_07_Juliol_qualitat_aire_BCN.csv')
A_A2 <- read.csv('data/Datos/Air Quality/2024_08_Agost_qualitat_aire_BCN.csv')
A_S <- read.csv('data/Datos/Air Quality/2024_09_Setembre_qualitat_aire_BCN.csv')
A_O <- read.csv('data/Datos/Air Quality/2024_10_Octubre_qualitat_aire_BCN.csv')
Cont <- read.csv('data/qualitat_aire_contaminants.csv')


##To understand the results and correlate the results from the neighborhoods to the data given by the 
##different stations

vec <- read.csv('data/Datos/Stations Air Quality 2023/2023_qualitat_aire_estacions.csv')
vec <- select(vec, Estacio,Longitud,Latitud, Codi_barri)


##Join all the monthly Data frames in one

A_ToT <- rbind(A_E, A_F, A_M,A_A, A_J, A_J2, A_A2, A_S, A_O)
A_ToT <-transmute(A_ToT,ESTACIO,CODI_CONTAMINANT,MES,DIA,H01, H02, H03, H04, H05, H06, H07, H08, H09, H10, H11, H12, H13, H14, H15, 
                  H16, H17, H18, H19, H20, H21,H22,H23,H24)

##Reads DataTrees 

T_T1 <- read.csv('data/Datos/Trees in green areas/2024_1T_OD_Arbrat_Parcs_BCN.csv')
T_T2 <- read.csv('data/Datos/Trees in green areas/2024_2T_OD_Arbrat_Parcs_BCN.csv')
T_T3 <- read.csv('data/Datos/Trees in green areas/2024_3T_OD_Arbrat_Parcs_BCN.csv')
T_S <- read.csv('data/Datos/Trees on the street/2024_1T_OD_Arbrat_Viari_BCN.csv')

#Select from data the columns that may be useful

DataT_T1 <- select(T_T1, codi,latitud,longitud, espai_verd, geom, codi_barri, nom_barri, codi_districte, nom_districte)
DataT_T2 <- select(T_T2, codi, espai_verd,latitud,longitud, geom, codi_barri, nom_barri, codi_districte, nom_districte)
DataT_T3 <- select(T_T3, codi,latitud,longitud, espai_verd, geom, codi_barri, nom_barri, codi_districte, nom_districte)


##then, we will create a data frame with another csv to compare the total. population of all 
#available neighborhoods

Pop <- read.csv('data/Datos/Population and Size/Taula estadística.csv')
Pop <- select(Pop, Territori,  "X01.Jul..2024")


barris <- st_read('https://raw.githubusercontent.com/martgnz/bcn-geodata/refs/heads/master/barris/barris.geojson')


##Graphing map in the Trees in the street##

ggplot() +
  geom_sf(data = barris, aes(fill = DISTRICTE)) +
  geom_point(data = DataT_T1, 
             aes(x = longitud, y = latitud),
             alpha = 0.8, 
             color = "black",
             shape = 21,
             stroke = 0.5, 
             fill="darkgreen")

##Extracting streets of Barcelona to graph a map, (Lines 76-111).

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

Barcelona_calles

Barcelona_calles <- Barcelona_calles$osm_lines


Barcelona_calles <- st_intersection(Barcelona_calles, Barcelona_frontera)
vec <- rename(vec, ESTACIO=Estacio)

Barcelona_calles_Sensores <- vec %>%
mutate(ESTACIO = as.numeric(ESTACIO), )


Barcelona_calles <- st_as_sf(Barcelona_calles)


##Graphing maps of Barcelona with contamination sensors and trees.

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
  )

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
#The plot below is less demanding


##Joining neighborhoods by name

barris_P <- inner_join(barris,Pop, join_by("NOM"=="Territori"))
barris_P <- rename(barris_P, Population = X01.Jul..2024)

##Graphing the population map by neighborhood

ggplot(barris_P)+
  geom_sf(aes(fill = Population))+
  scale_fill_viridis_b()


##Overall manipulations

A_ToT2 <- rowSums(A_ToT [, c(5:28)],)
MEAN_T <- A_ToT2/24
A_ToT <- cbind(A_ToT,MEAN_T)

Cont <- select(Cont, Codi_Contaminant, Desc_Contaminant)
Cont <- Cont[!duplicated(Cont), ]
Cont <- rename(Cont, CODI_CONTAMINANT = Codi_Contaminant)
A_ToT <- left_join(A_ToT, Cont,)

A_ToT <- A_ToT[complete.cases(A_ToT),]


##Graphs that show the evolution in pollution of all the possible contaminants, including a summary graph
##where all of the pollutants are shown, (Lines: 188-248) . 

ggplot(A_ToT)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T,)+
  ylim(0,3000)


NO<- filter(A_ToT,Desc_Contaminant== "NO" )
NOx<- filter(A_ToT,Desc_Contaminant== "NOx" )
PM10<- filter(A_ToT,Desc_Contaminant== "PM10" | Desc_Contaminant== "PM2.5" )
O3 <- filter(A_ToT,Desc_Contaminant== "O3" )
SO2 <- filter(A_ToT,Desc_Contaminant== "SO2" )
NO2 <- filter(A_ToT,Desc_Contaminant== "NO2" )
CO<- filter(A_ToT,Desc_Contaminant== "CO" )
BC<-filter(A_ToT,Desc_Contaminant== "Black Carbon" )
BBC <- filter(A_ToT,Desc_Contaminant== "Biomassa Black Carbon" )


ggplot(NO)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T)+
  geom_smooth(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant),)+
  xlab("Month")+ ylab("Mean")


ggplot(NOx)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T)+
  geom_smooth(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant),)+
  xlab("Month")+ ylab("Mean")

ggplot(PM10)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T)+
  geom_smooth(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant),)+
  xlab("Month")+ ylab("Mean")

ggplot(O3)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T)+
  geom_smooth(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant),)+
  xlab("Month")+ ylab("Mean")

ggplot(SO2)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T)+
  geom_smooth(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant),)+
  xlab("Month")+ ylab("Mean")

ggplot(NO2)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T)+
  geom_smooth(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant),)+
  xlab("Month")+ ylab("Mean")

ggplot(CO)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T)+
  geom_smooth(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant),)+
  xlab("Month")+ ylab("Mean")

ggplot(BC)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T)+
  geom_smooth(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant),)+
  xlab("Month")+ ylab("Mean")

ggplot(BBC)+
  geom_boxplot(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant), show.legend = T)+
  geom_smooth(aes(x=as.factor(MES), y=MEAN_T, color=Desc_Contaminant),)+
  xlab("Month")+ ylab("Mean")


##To understand the results and correlate the results from the neighborhoods to the data given by the 
##different stations

vec <- read.csv('data/Datos/Stations Air Quality 2023/2023_qualitat_aire_estacions.csv')
vec <- select(vec, Estacio,Longitud,Latitud, Codi_barri)

vec <- rename(vec, ESTACIO=Estacio)
vec <- vec[!duplicated(vec), ]
vec <- mutate(vec, Codi_barri = as.integer(vec$Codi_barri))
barris <- mutate(barris, BARRI = as.integer(barris$BARRI))
barris <- inner_join(barris, vec, join_by("BARRI"=="Codi_barri"))  
barris <- inner_join(barris, A_ToT)


##Graphing Thermic map of the contamination by neighborhood

ggplot(barris)+
  geom_sf(aes(fill = BARRI))+
  geom_point(data = vec, 
             aes(x = Longitud, y = Latitud),
             alpha = 0.8, 
             color = "black",
             shape = 21,
             stroke = 0.5, 
             size = 3, 
             fill = "red")+
  geom_sf_label(mapping = aes(label=NOM), size = 2, color = "purple")+
  scale_fill_viridis_b()

##The last plot is really demanding, comment for saving time, without the label the plot runs better.

