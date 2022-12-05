# Necessary test as fs::dir_copy with overwrite has a different behavior
#  than file.copy.
# It copies the content of the directory of the  "from" path into the
#  destination, instead of the directory itself
test_that("Load example creates correct structure", {
  example_path <- fs::path(tempdir(), "load_example")
  fs::dir_create(example_path)
  local({
    local_mock(menu = function(...) stop("Opps, shouldn't reach this"))
    load_example(example_path, force = TRUE)
  })

  files <- example_path |>
    fs::path(
      c(
        "run_tests.R",
        fs::path("app", "ui.R"),
        fs::path("app", "server.R"),
        fs::path("app", "global.R"),
        fs::path("app", "tests", "testthat.R"),
        fs::path("app", "tests", "testthat", "setup.R"),
        fs::path("app", "tests", "testthat", "test-use_this_one_1.R"),
        fs::path("app", "tests", "testthat", "test-use_this_one_2.R")
      )
    )

  dirs <- example_path |>
    fs::path(
      c(
        fs::path("app", "tests"),
        fs::path("app", "tests", "cypress"),
        fs::path("app", "tests", "testthat")
      )
    )

  expect_true(all(fs::file_exists(files)))
  expect_true(all(fs::is_file(files)))
  expect_false(all(fs::is_dir(files)))

  expect_true(all(fs::dir_exists(dirs)))
  expect_true(all(fs::is_dir(dirs)))
  expect_false(all(fs::is_file(dirs)))
})

test_that("Does not create load_examples on non-existing directory", {
  example_path <- fs::path(
    tempdir(),
    glue::glue("load_example_not_existing{unclass(Sys.time())}")
  )

  local({
    local_mock(menu = function(...) stop("Opps, shouldn't reach this"))
    load_example(example_path) |>
      expect_error("You must provide a valid path")
  })

  fs::dir_create(example_path)
  local({
    local_mock(menu = function(...) stop("Opps, shouldn't reach this"))
    load_example(example_path) |>
      expect_output("app created at")
  })
})

test_that("Does not create load_examples if there is a file in directory", {
  example_path <- fs::path(
    tempdir(),
    glue::glue("load_example_not_empty{unclass(Sys.time())}")
  )
  fs::dir_create(example_path)
  fs::file_create(fs::path(example_path, "touch.txt"))

  local({
    local_mock(menu = function(...) 2)
    load_example(example_path) |>
      expect_error("Consider creating a new empty path.")
  })

  local({
    local_mock(menu = function(...) 1)
    load_example(example_path) |>
      expect_output("app created at")
  })
})
