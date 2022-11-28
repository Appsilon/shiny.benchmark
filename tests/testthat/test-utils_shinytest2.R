test_that("Check if we are able to move files properly", {
  tmp_dir <- tempdir()

  tmp_dir1 <- file.path(tmp_dir, "folder1")
  dir.create(tmp_dir1, showWarnings = FALSE)
  tmp_dir2 <- file.path(tmp_dir, "folder2")
  dir.create(tmp_dir2, showWarnings = FALSE)

  shinytest2_dir <- file.path(tmp_dir1, "tst")
  shinytest2_dir_copy <- file.path(tmp_dir2, "tst")
  dir.create(path = shinytest2_dir, showWarnings = FALSE)

  move_shinytest2_tests(project_path = tmp_dir2, shinytest2_dir = shinytest2_dir)

  expect_true(file.exists(shinytest2_dir_copy))
})

test_that("Check if we are able to create shinytest2 structure", {
  tmp_dir <- create_shinytest2_structure(app_dir = ".")
  expect_true(file.exists(file.path(tmp_dir, "app.R")))
})
