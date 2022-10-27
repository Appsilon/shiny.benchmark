test_that("Check if commit date is in fact a date", {
  commit_date <- get_commit_date(branch = "main")
  expect_s3_class(object = commit_date, class = "POSIXct")
})

test_that("Check if we are able to get the commit hash", {
  commit_hash <- shiny.performance:::get_commit_hash()
  expect_true(is.character(commit_hash))
})
