shipIcon <- makeIcon(
  iconUrl = "https://www.svgrepo.com/show/235052/delivery-truck-transport.svg",
  iconWidth = 30, iconHeight = 30
)



make_routes <- function(res){
  
  lapply(res$routes, with, {
    list(
      geometry = googlePolylines::decode(geometry)[[1L]],
      dur= duration, 
      locations = lapply(steps, with, if (type=="job") location) %>%
        do.call(rbind, .) %>% data.frame %>% setNames(c("lon", "lat"))
    )
  }) 
  
}



## Helper function to add a list of routes and their ordered waypoints
addRoutes <- function(map, routes, colors) {
  routes <- mapply(c, routes, color = colors, SIMPLIFY = FALSE)
  f <- function (map, route) {
    with(route, {
      labels <- sprintf("<b>%s</b>", 1:nrow(locations))
      markers <- awesomeIcons(markerColor = color, text = labels, fontFamily = "arial")

      sdata = st_as_sf(geometry,coords =  c(2:1))
      sdata$duration= dur/nrow(sdata)
      map %>%
        addPolylines(data = geometry, lng = ~lon, lat = ~lat, col = ~color) %>%
        addMovingMarker(data = sdata,
                        duration = ~duration,
                        icon = shipIcon,
                        movingOptions = movingMarkerOptions(autostart = TRUE,
                                                            loop = FALSE,
                                                            pauseOnZoom = FALSE)
        )%>%
        addAwesomeMarkers(data = locations, lng = ~lon, lat = ~lat, icon = markers) 
    })
  }
  Reduce(f, routes, map)
}


