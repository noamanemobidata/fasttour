library(shiny)
library(leaflet)
library(bs4Dash)
library(shinyWidgets)
library(openrouteservice)
library(htmlwidgets)
library(dplyr)
library(shinyjs)
library(glue)
library(leaflet.extras2)

source("utils.R")


home_base <- data.frame(lon = 2.4, lat = 48.92)
cls <- c("purple", "green", "red")

ui <- fluidPage(
  tags$html(lang="en"),
  tags$head(tags$title('🚚   Fasttour - tour optimisation app')),
  tags$head(tags$meta(name="description", content="Author: miskowski85@hotmail.fr")),
  tags$head(tags$meta(name="title", content="Fasttour - tour optimisation app")),
  shinyWidgets::useBs4Dash(), 
  useShinyjs(), 
  includeCSS("www/style.css"),
  uiOutput("map_ui"), 
  uiOutput('model_input'), 
  fixedPanel(top = 10, right = 52,
             
             actionBttn(inputId = "go", label = NULL, icon = icon("rocket"), style = "material-circle",color = "warning",size = "sm"), 
             actionBttn(inputId = "delete", label = NULL, icon = icon("trash-alt"), style = "material-circle",color = "danger", size = "sm"), 
             )
  
)



server <- function(input, output, session) {
  
  
  depot <- reactiveValues(coords=home_base)
  
  
  
  output$map_ui <- renderUI({

    div(
      class = "outer",
      leafletOutput("map_init", height = "100%")
    )
  })
  
  
  output$map_init <- renderLeaflet({
  
    
    leaflet(options = leafletOptions(zoomControl = FALSE)) %>%
     # addTiles() %>%
      addProviderTiles(provider = "CartoDB.Voyager") %>%
      onRender(
        "function(el, x) {
          L.control.zoom({position:'topright'}).addTo(this);
        }")%>%
      addAwesomeMarkers(data = depot$coords, icon = awesomeIcons("home"),options = markerOptions(interactive = T, riseOnHover = T,draggable = T),layerId = 'home') %>%
      setView(lng = depot$coords$lon, lat = depot$coords$lat, zoom = 11)
    
      
    
  })
  
  
  observeEvent(input$map_init_marker_dragend, {
   
    depot$coords <- data.frame(lon=input$map_init_marker_dragend$lng, lat= input$map_init_marker_dragend$lat)
  
    })
  
  output$model_input <- renderUI({
    
    absolutePanel(top = 10, left = 10,width = "100%",  style="pointer-events:none;", 
                  
                  fluidPage(
                    
                    fluidRow(
                      column(4, 

                             tabBox(
                               title = "Fasttour",
                               side = "right",
                               id = "tabcard2",
                               type = "tabs",
                               elevation = 2,
                               width = 12,
                               footer =uiOutput("control_move"), 
                               status = "warning",
                               maximizable = F,
                               collapsible = TRUE, 
                               closable = F,
                               selected = "Stops",
                               tabPanel(
                                 "Stops",
                                 icon =icon('map-marker-alt'), 
                                 uiOutput("stops")
                               ), 
                               tabPanel(
                                 "Vehicles",
                                 icon =icon('truck-pickup'), 
                                 uiOutput("veh")
                               )
                              
                             )
                      )
                    ), 
                    
                    
                    fluidRow(
                      column(4, 
                             
                             uiOutput("timeline")
                             
                             )
                    )
                    
                    
                  )
                  
                  )
    
    

    
  })
  
  data_input <- reactiveValues(locations=NULL,
                               veh_df= vehicles(
    id = 1:2,
    profile = "driving-car",
    capacity = 4,
    time_window = c(28800, 43200)
  )
  ) 
  
  solution <- reactiveValues(res=NULL)
  
  
  
  output$veh <- renderUI({
    
    
    n <- ifelse(is.null(data_input$veh_df), 0,nrow(data_input$veh_df))
    
    div(
      style="text-align:center;", 
      h1(n, style="color:#DB4437;height:50%;font-size: 60px;"), 
      h4("Vehicles in the fleet", style="color:#F4B400;height:50%;" ), 
      tags$i(   actionBttn(
        inputId = "add_veh",
        icon = icon("plus"), size = "xs",
        color = "primary",
        style = "material-circle"
      ) , "add new vehicles")
      
    )
    

  })
  
  
  

  

  observeEvent(input$map_init_click, {
    
    nb_stops <- ifelse(is.null(data_input$locations), 0, nrow(data_input$locations )) 
    
    if(nb_stops>=50){
      
      showNotification( ui = glue("Too many stops ( { nb_stops} ) in query, maximum is set to 50"), type = "error")
    }else{
      
      
      
      
      data_input$locations <- data_input$locations%>%
        rbind(
          data.frame(
            lng= input$map_init_click$lng,
            lat= input$map_init_click$lat 
            
          )
        )
      
      id <- ifelse(is.null(data_input$locations), 0, nrow(data_input$locations )) 
      leafletProxy("map_init")%>%
        addMarkers(lng =  input$map_init_click$lng, lat =  input$map_init_click$lat, layerId = id)
    }
    
  })
  
  output$stops<- renderUI({
    
    n <- ifelse(is.null(data_input$locations), 0,nrow(data_input$locations))
    
    div(
      style="text-align:center;", 
      h1(n, style="color:#DB4437;height:50%;font-size: 60px;"), 
      h4("Stops planned", style="color:#F4B400;height:50%;" ), 
      tags$i(HTML('<i class="fas fa-info-circle"></i> You can add stops by clicking on the map and edit them by clicking on the marker.<br> You can change depot location by grag and drop '))
      
    )
    
  })
  
  
  changes_marker_data <- reactiveValues(data=NULL)
  
  
  observeEvent(input$map_init_marker_click, {
    
    req(input$map_init_marker_click$id)
      
    
    if(input$map_init_marker_click$id!= "home"){
      
      showModal(
        modalDialog(title = NULL, 
                    footer = actionBttn(inputId = "save_marker", label = "Save" , icon = icon("save"), style = "material-flat", color = "success"),
                    size = "m",easyClose = T, fade = F, 
                    
                    fluidPage(
                      fluidRow(
                        column(12, 
                                numericInput(inputId = "service", label = "service time", value = 5, min = 0, width = '100%')
                               )
                      ), 
                      
                      fluidRow(
                        column(12, 
                               numericInput(inputId = "amount", label = "Quantity", value = 1, min = 1, width = '100%')
                        )
                      )
                      
                    )
                    
                    
                    
                    )
      )
      
      
      
    }
    
  })

  
  observeEvent(input$save_marker, {
    
        changes_marker_data$data <- data.frame(id= input$map_init_marker_click$id, amount_edit= (as.integer(input$amount)), service_edit=as.integer(input$service*60) ) 

        removeModal()
  })
    
  
  observeEvent(input$add_veh,{
    
    showModal(
      
      div(class='mdx', 
          
          modalDialog(
            title = "Add vehicles",footer = NULL, size = "l",easyClose = T, fade = F,
            
            uiOutput("add_veh_ui")
            
          )
          
      )
      
    )
    
    
    
  })
  

  output$add_veh_ui <- renderUI({
    
    library(purrr)
    
    fluidPage(
      
      fluidRow(
        
        column(3, 
               pickerInput(
                 inputId = "profile",
                 label = "profile", 
                 choices = c("driving-car", "driving-hgv", "cycling-regular")
               )
               ), 
        
        column(3, 
               numericInput(inputId = "capacity",label = "capacity", value = 7, min = 1, step = 1,width = "100%")
               
               ), 
        column(3,
               sliderInput(inputId = "time_window", label = "time_window",min = 0,max = 24,value = c(8, 18),step = 1, ticks = F, width = '100%',timeFormat = "%H %M")
               
           
        ), 
        column(3, 
               
               br(),
               actionBttn(inputId = "add_v",label = "Add to fleet",icon = icon("plus"),style = 'material-flat',size = "sm",block = T)
               )
        
      ), 
      hr(),
      h4("Available vehicles:"), 
      fluidRow(
        DT::datatable(data = data_input$veh_df %>%
                        select(-id)%>%
                        mutate(
                          Actions = sprintf('<button class="btn btn-danger btn-sm delete-fav-btn" data-row="%d"><i class="fas fa-trash-alt"></i></button>', row_number() )
                          )%>%
                        mutate(time_window = map_chr(time_window, ~ glue("from {first(.x)/3600} to {last(.x)/3600}")))
                      
                        ,
                      escape = FALSE,
                      rownames = F,
                      selection = "none",
                      style = "bootstrap4",
                      class = "hover compact",
                      options = list(
                        dom = "t",
                        ordering = FALSE,
                        scrollY = "300px",
                        scrollCollapse = TRUE
                      )
                      
        )
        
      )
      
    )
    
    
  })
  
  
  # Ajoutez le JavaScript pour gérer les clics sur les boutons
  shinyjs::runjs("
  $(document).on('click', '.delete-fav-btn', function() {
    var row = $(this).data('row');
    Shiny.setInputValue('delete_fav_button_clicked', row, {priority: 'event'});
  });")
  
  # Gérez la suppression des favoris
  observeEvent(input$delete_fav_button_clicked, {
    
    data_input$veh_df  <- data_input$veh_df %>%
      filter(row_number()!=input$delete_fav_button_clicked)

  })
  
  
  
  observeEvent(input$add_v, {

    idmax<- max(data_input$veh_df$id) 
    
    nb_veh <- nrow(data_input$veh_df)
    
    if(nb_veh>=3){
      
      showNotification(ui =glue("Too many vehicles in query, maximum is set to 3"),type = "error")
      
    }else{
      
      data_input$veh_df <-data_input$veh_df%>%
        add_row(
          id=idmax+1, 
          profile= input$profile, 
          capacity= I(list(input$capacity)), 
          time_window=I(list( c(input$time_window[1]*3600,input$time_window[2]*3600 )))
        )
    
      
    }
  
    
  })
  
  
  observeEvent(input$go, {
    
    req(data_input$locations)
    req(data_input$veh_df )
    
    locations <- data_input$locations%>%asplit(MARGIN = 1)
    
    
    jobs = jobs(
      id = 1:length(locations),
      service = 300,
      amount = 1,
      location = locations
    )

    n_changes <- ifelse(is.null(changes_marker_data$data ),0, nrow(changes_marker_data$data ) )
    
    
    
    if(n_changes>0){
    
      changes_marker_data$data$amount_edit <- as.list(changes_marker_data$data$amount_edit)
        

      jobs <- jobs%>%
        left_join(
          changes_marker_data$data, 
          by= "id"
        )%>%
        mutate(
          service= ifelse(!is.na(service_edit), service_edit,service ),
          amount= ifelse(!map_lgl(amount_edit, is.null), amount_edit,amount )
        ) 
    }
    
    vehs <- data_input$veh_df 

    
    vehicles <-vehicles(
      id =1:nrow(vehs),
      profile = vehs$profile, 
      start = depot$coords,
      end = depot$coords,
      capacity = vehs$capacity,
      time_window = vehs$time_window
    )
    

    res <- ors_optimization(jobs, vehicles, options = list(g = TRUE), api_key = Sys.getenv('TOUR_API_KEY')  )
    if(res$code==0){
      
      solution$res <- res
      
      make_routes(res)-> routes
      
      leafletProxy("map_init") %>%
        addRoutes(routes, cls[1:length(res[["routes"]])]  ) %>%
        startMoving()
      
      output$control_move <- renderUI({
        tagList(
          
          actionBttn(inputId = "pause", label = NULL, icon = icon("pause"),style = "material-circle",color = "default",size = 'xs'),
          actionBttn(inputId = "resume", label = NULL, icon = icon("play"),style = "material-circle",color = "default",size = 'xs'),
          actionBttn(inputId = "play", label = NULL, icon = icon("undo"),style = "material-circle",color = "default",size = 'xs')
          
        )
      })
       
    }else{
      
    
      showNotification(ui = "Error ",type = "error")
      output$control_move <- renderUI({
        tagList(
          
          NULL
          
        )
      })
      
    }
    
    

    
    
  })
  
  
  observeEvent(input$pause,{
    
    leafletProxy("map_init")%>%
      pauseMoving()
    
  })
  
  observeEvent(input$resume,{
    
    leafletProxy("map_init")%>%
      resumeMoving()
    
  })
  
  observeEvent(input$play,{
    
    leafletProxy("map_init")%>%
      startMoving()
    
  })
  observeEvent(input$delete,{
    
    
    leafletProxy("map_init") %>%
      leaflet::clearShapes()%>%
      leaflet::clearMarkers() %>%
      addAwesomeMarkers(data = depot$coords, icon = awesomeIcons("home"),options = markerOptions(interactive = T, riseOnHover = T,draggable = T),layerId = 'home') %>%
      setView(lng = depot$coords$lon, lat = depot$coords$lat, zoom = 11)
    
    data_input$locations <- NULL
    solution$res  <- NULL
    
    
  })
  

  output$timeline <- renderUI({
    
    req(solution$res)
    
    lapply(solution$res$routes, function(x){
      
      
      # Div container for the entire card
      tags$div(class = "col-sm-12",
               # Card element with custom classes
               tags$div(class = "card card-outline collapsed-card elevation-1",
                        # Card header with title and tools
                        tags$div(class = "card-header",style=glue("background: linear-gradient(to left, {cls[as.integer(x$vehicle)]} 8%, transparent 40%);"), 
                                 # Card title
                                 tags$h3(class = "card-title",tagList(bs4Badge(color = "primary",position = "left",rounded = T,paste0("Veh N° ", x$vehicle) ), 
                                                                                               bs4Badge(color = "warning",position = "left",rounded = T,lubridate::duration(x$duration)),
                                                                                               bs4Badge(color = "info",position = "left",rounded = T,paste0(round( x$distance/1000,1) ," Km") )  )),
                                 # Tools section on the right
                                 tags$div(class = "card-tools float-right",
                                          # Collapse button with icon
                                          tags$button(class = "btn btn-tool btn-sm", type = "button", `data-card-widget` = "collapse",
                                                      tags$i(class = "fas fa-plus", role = "presentation", `aria-label` = "plus icon")
                                          )
                                 )
                        ),
                        # Card body content
                        tags$div(class = "card-body",
                                 
                                 timelineBlock(
                                   width = 12,
                                   reversed = F,  
                                   lapply(1:length(x$steps), function(i){
                                     
                                     y= x$steps[[i]]
                                     
                                     timelineItem(
                                       elevation = 0, 
                                       title =ifelse(y$type=="job",paste0(y$type ," ",i-1 ), y$type ) ,
                                       icon = icon("circle"),border = F, 
                                       color = "olive",
                                       time = format(as.POSIXct(paste0(Sys.Date(), ' 00:00:00'))+as.integer(y$arrival) ,"%H:%M" )   ,
                                       footer =NULL,
                                       HTML(glue("Vehicle load after : {y$load} units"))
                                     )
                                     
                                   })
                                 ) 
                                 
                                 )
               ),
               # JSON script tag (not typically needed in Shiny, added for completeness)
               tags$script(type = "application/json",
                           '{"title":"TITRE","status":"primary","solidHeader":false,"width":12,"collapsible":true,"closable":false,"maximizable":false,"gradient":false}'
               )
      )
      
      
      
      
      
    })
    
    
    
  })
  
  
  
}


shiny::shinyApp(ui, server,options = list(port =3838 ,host = "0.0.0.0"))
