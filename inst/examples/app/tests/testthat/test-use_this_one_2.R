library(shinytest2)

app <- AppDriver$new(name = "test1", height = 975, width = 1619)

test_that("{shinytest2} recording: test4", {
  app$click("run1")
  app$expect_values(output = "out1")
})

test_that("{shinytest2} recording: test5", {
  app$click("run2")
  app$expect_values(output = "out2")
})

test_that("{shinytest2} recording: test6", {
  app$click("run3")
  app$expect_values(output = "out3")
})

app$close()
