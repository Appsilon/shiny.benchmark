#' @title Create a temporary directory to store everything needed by shinytest2
#'
#' @param app_dir The path to the application root
#'
#' @importFrom glue glue
#'
#' @keywords internal
create_shinytest2_structure <- function(app_dir) {
  # temp dir to run the tests
  dir_tests <- tempdir()

  # shiny call
  writeLines(
    text = glue('shiny::runApp(appDir = "{app_dir}")'),
    con = fs::path(dir_tests, "app.R")
  )

  # returning the project folder
  message(glue("Structure created at {dir_tests}"))

  return(dir_tests)
}

#' @title Move tests to a temporary folder
#'
#' @param project_path The path to the project
#' @param shinytest2_dir The directory with tests recorded by shinytest2
#'
#' @keywords internal
move_shinytest2_tests <- function(project_path, shinytest2_dir) {
  # copy everything to the temporary directory
  file.copy(from = shinytest2_dir, to = project_path, recursive = TRUE)
  tests_dir <- file.path(project_path, "tests")

  return(tests_dir)
}
