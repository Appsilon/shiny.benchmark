function(input, output, session) {
  # Sys.sleep
  react1 <- eventReactive(input$run1, {
    out <- system.time(
      Sys.sleep(6)
    )

    return(out[3])
  })

  react2 <- eventReactive(input$run2, {
    out <- system.time(
      Sys.sleep(3)
    )

    return(out[3])
  })

  react3 <- eventReactive(input$run3, {
    out <- system.time(
      Sys.sleep(1)
    )

    return(out[1])
  })

  # outputs
  output$out1 <- renderUI({
    tags$span(round(react1()), style = "font-size: 500px;")
  })

  output$out2 <- renderUI({
    tags$span(round(react2()), style = "font-size: 500px;")
  })

  output$out3 <- renderUI({
    tags$span(round(react3()), style = "font-size: 500px;")
  })
}
