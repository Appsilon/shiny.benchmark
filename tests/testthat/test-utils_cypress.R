test_that("Check if we are able to add Cypress code to a txt file", {
  tmp_dir <- tempdir()
  add_sendtime2js(
    js_file = fs::path(tmp_dir, "test.js"),
    txt_file = "test.txt"
  )

  expect_true(fs::file_exists(fs::path(tmp_dir, "test.js")))
})

test_that("Check if we are able to copy file content from a file to another", {
  tmp_dir <- tempdir()
  tmp_file <- tempfile(tmpdir = tmp_dir, fileext = ".js")
  content_before <- "TEST"
  writeLines(text = content_before, con = tmp_file)

  integration_dir <- fs::path(tmp_dir, "tests", "cypress", "integration")
  fs::dir_create(path = integration_dir)
  files <- create_cypress_tests(
    project_path = tmp_dir,
    cypress_dir = tmp_dir,
    tests_pattern = ".js"
  )
  content_after <- readLines(con = files$js_file, n = 1)

  expect_true(content_after == content_before)
})
