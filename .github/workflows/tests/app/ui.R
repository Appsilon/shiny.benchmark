function() {
  bootstrapPage(
    tags$h1("Measuring time in different commits"),
    column(
      width = 4,
      actionButton(inputId = "run1", label = "Run 1"),
      uiOutput(outputId = "out1")
    ),
    column(
      width = 4,
      actionButton(inputId = "run2", label = "Run 2"),
      uiOutput(outputId = "out2")
    ),
    column(
      width = 4,
      actionButton(inputId = "run3", label = "Run 3"),
      uiOutput(outputId = "out3")
    )
  )
}
