#' @title Create a temporary directory to store everything needed by shinytest2
#'
#' @param shinytest2_dir The path to the shinytest2 tests
create_shinytest2_structure <- function(shinytest2_dir) {
  # temp dir to run the tests
  dir_tests <- tempdir()

  # copy everything to the temporary directory
  system(glue("cp -r {shinytest2_dir} {dir_tests}"))

  # returning the project folder
  message(glue("Structure created at {dir_tests}"))
  return(dir_tests)
}
