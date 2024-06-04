library(sf)
library(leaflet)
library(tidyverse)
library(shiny)
library(RColorBrewer)

## load the map data
temp_shapefile <- tempfile()
download.file("https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/world-administrative-boundaries/exports/shp?lang=en&timezone=Europe%2FLondon", temp_shapefile)
unzip(temp_shapefile)
worldmap <- st_read("world-administrative-boundaries.shp")
worldmap <- worldmap[,-c(2,3,7,8)]
#rename variables
worldmap <- worldmap %>% rename(country = name)

## Reading the energy data (from https://ourworldindata.org/energy-production-consumption)
energy <- read_csv("primary-energy-cons.csv")[,-1]
#rename variables
energy <- energy %>% rename (iso3 = names(energy)[1], year = names(energy)[2], consumption = names(energy)[3])

## Reading the GDP data
gdp <- read_csv("gdp.csv", n_max = 11704)[,-c(2,3)]
#Rename econ variables
gdp <- gdp %>% rename(year = names(gdp)[1], iso3 = names(gdp)[2], gdp = names(gdp)[3])
# change gdp variable to numeric
gdp$gdp <- as.numeric(gdp$gdp)

#Merge energy and GDP data
temp <- inner_join(gdp, energy, by = c("iso3", "year"))
# convert energy consumption from TWh to Wh
temp$consumption <- temp$consumption * 1000000000000
# assign NA to observations with 0 consumption
temp$consumption[temp$consumption==0] <- NA
# calculate watt.gdp as number of watts used per dollar of gdp
temp <- temp %>% mutate(watt.gdp = round(consumption/gdp, 0))

# Define server logic required to create the map 
function(input, output, session) {
        output$map <- renderLeaflet({
                #filter temp data by selected year
                filtered_temp <- temp %>% filter(year == input$year)
                
                # create dataframe for analysis by joining map data and temp data for selected year
                filtered_data <- left_join(worldmap, filtered_temp, by = "iso3")
                
                #create color palette with user-specified bins
                bins <- c(0, 1000, 2000, 3000, 5000, Inf)
                mypalette <- colorBin(palette = "YlOrBr", domain = filtered_data$watt.gdp, na.color = "transparent", bins = bins)
                
                #prepare text for tooltips: first, create a list of text to be displayed for each country using paste (note the use of <br/> introduce second line, and the format formula adds comma separators), then lappy marks each element of list as HTML
                mytext <- paste(filtered_data$country, "<br/>", "Wh/GDP: ", format(filtered_data$watt.gdp, big.mark = ",", scientific = FALSE), sep ="") %>% lapply(htmltools::HTML)
                
                #create the leaflet map
                leaflet(filtered_data) %>% 
                        addTiles() %>% 
                        setView (lat = 10, lng = 0, zoom = 1.5) %>% 
                        addPolygons(fillColor = ~ mypalette(watt.gdp), stroke = TRUE, 
                                    fillOpacity = 0.9, color = "white", weight = 0.3, label = mytext, 
                                    labelOptions = labelOptions(style = list("font-weight" = "normal", padding = "3px 8px"), 
                                                                textsize = "13px", direction = "auto")) %>% 
                        addLegend(pal = mypalette, values = ~watt.gdp, opacity = 0.9, 
                              title = "Primary Energy Consumption (kWh/person)", position = "bottomleft")
        })
}