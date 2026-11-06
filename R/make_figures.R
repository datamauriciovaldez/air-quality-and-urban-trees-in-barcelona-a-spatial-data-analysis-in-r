# Re-generates the figures shown in the README from the project data.
# Run from the repository root after extracting the data (see README, "Run it yourself"):
#   Rscript R/make_figures.R
suppressMessages({library(dplyr); library(readr); library(ggplot2); library(sf); library(tidyr)})
DATA <- "data/Datos"
OUT  <- "assets/"

cont <- read_csv("data/qualitat_aire_contaminants.csv", show_col_types = FALSE) %>%
  select(CODI_CONTAMINANT = Codi_Contaminant, Pollutant = Desc_Contaminant, Unit = Unitats)

# ---- Air quality: 9 monthly files (May is not in the source data) --------------------------
files <- list.files(file.path(DATA, "Air Quality"), full.names = TRUE)
air <- bind_rows(lapply(files, function(x)
  read_csv(x, show_col_types = FALSE) %>% select(ESTACIO, CODI_CONTAMINANT, MES, DIA, matches("^H\\d\\d$"))))
hours <- grep("^H\\d\\d$", names(air), value = TRUE)
air$daily <- rowMeans(air[, hours], na.rm = TRUE)          # daily mean of the 24 hourly values
air <- left_join(air, cont, by = "CODI_CONTAMINANT") %>% filter(!is.nan(daily))

pal <- c(NO2 = "#EF4444", PM10 = "#F59E0B", O3 = "#3B82F6", `PM2.5` = "#8B5CF6")
d <- air %>% filter(Pollutant %in% names(pal)) %>% mutate(Pollutant = factor(Pollutant, levels = names(pal)))
theme_set(theme_minimal(base_size = 12) +
          theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank(), legend.position = "none"))

p1 <- ggplot(d, aes(factor(MES), daily, fill = Pollutant)) +
  geom_boxplot(outlier.size = .3, outlier.alpha = .3, color = "grey30", linewidth = .3) +
  stat_summary(aes(group = Pollutant), fun = mean, geom = "line", color = "black", linewidth = .8) +
  scale_fill_manual(values = pal) +
  facet_wrap(~Pollutant, scales = "free_y", ncol = 2, labeller = labeller(Pollutant = function(x) paste0(x, " (ug/m3)"))) +
  scale_x_discrete(labels = function(x) month.abb[as.integer(x)]) +
  labs(title = "Barcelona air quality, 2024: daily mean per pollutant and month",
       subtitle = "Box = daily means across the 8 stations; black line = monthly mean. May is missing from the source data.",
       x = NULL, y = NULL)
ggsave(paste0(OUT, "pollutants_monthly.png"), p1, width = 11, height = 6.2, dpi = 150, bg = "white")

# ---- Trees and stations (Q3 2024) -----------------------------------------------------------
barris <- st_read("https://raw.githubusercontent.com/martgnz/bcn-geodata/refs/heads/master/barris/barris.geojson", quiet = TRUE)
st <- read_csv(file.path(DATA, "Stations Air Quality 2023/2023_qualitat_aire_estacions.csv"), show_col_types = FALSE) %>%
  distinct(Estacio, nom_cabina, Longitud, Latitud, Nom_barri)
tg <- read_csv(file.path(DATA, "Trees in green areas/2024_3T_OD_Arbrat_Parcs_BCN.csv"), show_col_types = FALSE) %>%
  filter(!is.na(latitud), !is.na(longitud))
ts <- read_csv(file.path(DATA, "Trees on the street/2024_3T_OD_Arbrat_Viari_BCN.csv"), show_col_types = FALSE) %>%
  filter(!is.na(latitud), !is.na(longitud))

p2 <- ggplot() +
  geom_sf(data = barris, fill = "#F3F4F6", color = "white", linewidth = .2) +
  geom_point(data = ts, aes(longitud, latitud), color = "#0EA5E9", size = .05, alpha = .35) +
  geom_point(data = tg, aes(longitud, latitud), color = "#16A34A", size = .05, alpha = .35) +
  geom_point(data = st, aes(Longitud, Latitud), shape = 21, fill = "#EF4444", color = "black", size = 3.2, stroke = .6) +
  coord_sf(xlim = c(2.05, 2.23), ylim = c(41.32, 41.47)) +
  labs(title = "Where are the trees and the air-quality stations?",
       subtitle = "Street trees (blue), park trees (green), air-quality stations (red). Q3 2024.") +
  theme_void() + theme(plot.title = element_text(face = "bold", size = 14),
                       plot.subtitle = element_text(size = 10, color = "grey30"), plot.margin = margin(8, 8, 8, 8))
ggsave(paste0(OUT, "map_trees_stations.png"), p2, width = 8, height = 7, dpi = 150, bg = "white")

dist <- bind_rows(ts %>% mutate(type = "Street trees"), tg %>% mutate(type = "Park trees")) %>%
  filter(!is.na(nom_districte)) %>% count(nom_districte, type)
dist$nom_districte <- tools::toTitleCase(tolower(dist$nom_districte))
ord <- dist %>% group_by(nom_districte) %>% summarise(t = sum(n)) %>% arrange(t) %>% pull(nom_districte)
p3 <- ggplot(dist, aes(factor(nom_districte, levels = ord), n, fill = type)) + geom_col(width = .7) + coord_flip() +
  scale_fill_manual(values = c("Street trees" = "#0EA5E9", "Park trees" = "#16A34A")) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Trees per district (Q3 2024)", x = NULL, y = "Number of trees", fill = NULL) + theme(legend.position = "top")
ggsave(paste0(OUT, "trees_by_district.png"), p3, width = 8, height = 5, dpi = 150, bg = "white")
