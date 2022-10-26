test_that("Check if we are able to add Cypress code to a txt file", {
  tmp_dir <- tempdir()
  add_sendtime2js(
    js_file = file.path(tmp_dir, "test.js"),
    txt_file = "test.txt"
  )

  expect_true(file.exists(file.path(tmp_dir, "test.js")))
})

test_that("Check if we are able to copy file content from a file to another", {
  tmp_dir <- tempdir()
  tmp_file <- tempfile(tmpdir = tmp_dir, fileext = ".txt")
  content_before <- "TEST"
  writeLines(text = content_before, con = tmp_file)

  files <- create_cypress_tests(project_path = tmp_dir, cypress_file = tmp_file)
  content_after <- readLines(con = files$js_file, n = 1)

  expect_true(content_after == content_before)
})

test_that("Check whether we have are able to create Cypress structure correctly or not", {
  tmp_dir <- create_cypress_structure(
    app_dir = getwd(),
    port = 3333,
    debug = FALSE
  )

  expect_true(file.exists(file.path(tmp_dir, "node")))
  expect_true(file.exists(file.path(tmp_dir, "node", "root")))
  expect_true(file.exists(file.path(tmp_dir, "node", "root", "DESCRIPTION")))
  expect_true(file.exists(file.path(tmp_dir, "tests")))
  expect_true(file.exists(file.path(tmp_dir, "tests", "cypress", "plugins")))
})


