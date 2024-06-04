## load relevant libraries
library(leaflet)
library(shiny)

# Define UI for application that draws a histogram
fluidPage(
    # Application title
    titlePanel("Energy Consumption in Watt/hour per Dollar of GDP"),
    # Sidebar with a slider input
    sidebarLayout(
        sidebarPanel(
                tags$p("Use the slider to select a year"),
                sliderInput("year",
                        "Select Year:",
                        min = 1980,
                        max = 2022,
                        value = 2022,
                        step = 1,
                        animate = TRUE,
                        sep = "")
        ),
        # Show the map for the specified year
        mainPanel(
            leafletOutput("map", height = 600)
        )
    )
)
