



make_routes <- function(res){
  
  lapply(res$routes, with, {
    list(
      geometry = googlePolylines::decode(geometry)[[1L]],
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
      map %>%
        addPolylines(data = geometry, lng = ~lon, lat = ~lat, col = ~color) %>%
        addAwesomeMarkers(data = locations, lng = ~lon, lat = ~lat, icon = markers)
    })
  }
  Reduce(f, routes, map)
}


