library(shinytest2)

test_that("{shinytest2} recording: test1", {
  app <- AppDriver$new(name = "test1", height = 975, width = 1619)
  app$click("run1")
  app$expect_values(output = "out1")
})

test_that("{shinytest2} recording: test2", {
  app <- AppDriver$new(name = "test2", height = 975, width = 1619)
  app$click("run2")
  app$expect_values(output = "out2")
})

test_that("{shinytest2} recording: test3", {
  app <- AppDriver$new(name = "test3", height = 975, width = 1619)
  app$click("run3")
  app$expect_values(output = "out3")
})
