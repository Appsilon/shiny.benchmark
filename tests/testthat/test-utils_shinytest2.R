library(fs)

test_that("Check if we are able to move files properly", {
  tmp_dir <- tempdir()

  # Create the folder that contains the tests, it's named tst
  # on purpuse as it won't be a valid directory and shinytests2 would
  # fail
  tmp_dir1 <- file.path(tmp_dir, "folder1")

  dir.create(path = tmp_dir1, recursive = TRUE)
  shinytest2_dir <- fs::path(tmp_dir1, "tst")
  dir.create(shinytest2_dir, showWarnings = FALSE)
  file.create(fs::path(shinytest2_dir, "some_example.txt"))
  file.create(fs::path(shinytest2_dir, "some_example2.txt"))
  file.create(fs::path(shinytest2_dir, "some_example3.txt"))

  # Create a mock project path base directory
  tmp_dir2 <- fs::path(tmp_dir, "folder2")
  dir.create(tmp_dir2, recursive = TRUE)
  project_path <- tmp_dir2
  dir.create(fs::path(tmp_dir2, "something"))
  file.create(fs::path(shinytest2_dir, "root.txt"))

  # The result of the copy should land on tests folder
  shinytest2_dir_copy_manual <- file.path(tmp_dir2, "tests")

  # [ACTION] Actual copy of the shinytest2 files
  shinytest2_dir_copy_auto <- move_shinytest2_tests(
    project_path = tmp_dir2,
    shinytest2_dir = shinytest2_dir
  )

  # Test if the copy was successful
  expect_true(dir.exists(shinytest2_dir_copy_manual))
  expect_true(dir.exists(shinytest2_dir_copy_auto))
  expect_equal(shinytest2_dir_copy_auto, shinytest2_dir_copy_manual)

  short_var <- shinytest2_dir_copy_auto
  str_mask <- "some_example{input}.txt"
  c("", 2, 3) |>
    sapply(function(input) {
      expect_true(file.exists(fs::path(short_var, glue(str_mask))))
    })
})

test_that("Check if we are able to create shinytest2 structure", {
  tmp_dir <- create_shinytest2_structure(app_dir = ".")
  expect_true(fs::file_exists(fs::path(tmp_dir, "app.R")))
})
