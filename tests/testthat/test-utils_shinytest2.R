test_that("Check if we are able to move files properly", {
  tmp_dir <- tempdir()

  tmp_dir1 <- fs::path(tmp_dir, "folder1")
  fs::dir_create(path = tmp_dir1)
  tmp_dir2 <- fs::path(tmp_dir, "folder2")
  fs::dir_create(path = tmp_dir2)

  shinytest2_dir <- fs::path(tmp_dir1, "tst")
  shinytest2_dir_copy <- fs::path(tmp_dir2, "tst")
  fs::dir_create(path = shinytest2_dir)

  move_shinytest2_tests(project_path = tmp_dir2, shinytest2_dir = shinytest2_dir)

  expect_true(fs::file_exists(shinytest2_dir_copy))
})

test_that("Check if we are able to create shinytest2 structure", {
  tmp_dir <- create_shinytest2_structure(app_dir = ".")
  expect_true(fs::file_exists(fs::path(tmp_dir, "app.R")))
})
