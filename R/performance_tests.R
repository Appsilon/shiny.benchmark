#' @title Execute performance tests for a list of commits
#'
#' @param commit_list A list of commit hash codes, branches' names or anything else you can use with git checkout [...]
#' @param cypress_file The path to the .js file containing cypress tests to be recorded
#' It can also be a vector of the same size of commit_list
#' @param shinytest2_dir The directory with tests recorded by shinytest2
#' It can also be a vector of the same size of commit_list
#' @param app_dir The path to the application root
#' @param port Port to run the app
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @importFrom git2r checkout
#'
#' @export
performance_tests <- function(
    commit_list,
    cypress_file = NULL,
    shinytest2_dir = NULL,
    app_dir = getwd(),
    port = 3333,
    debug = FALSE
) {
  # Number of commits to test
  n_commits <- length(commit_list)

  # Test whether we have everything we need
  if (is.null(cypress_file) & is.null(shinytest2_dir))
    stop("You must provide cypress_file or shinytest2_dir")

  if (!is.null(cypress_file) & !is.null(shinytest2_dir)) {
    message("Using the cypress files only")
    shinytest2_dir <- NULL

    if (length(cypress_file) == 1)
      cypress_file <- rep(cypress_file, n_commits)
    if (length(cypress_file) != n_commits)
      stop("You must provide 1 or {n_commits} paths for cypress_file")
  } else {
    if (length(shinytest2_dir) == 1)
      shinytest2_dir <- rep(shinytest2_dir, n_commits)
    if (length(shinytest2_dir) != n_commits)
      stop("You must provide 1 or {n_commits} paths for shinytest2_dir")
  }

  type <- ifelse(!is.null(cypress_file), "cypress", "shinytest2")

  # getting the current branch
  current_branch <- get_commit_hash()

  if (type == "cypress") {
    # creating the structure
    project_path <- create_cypress_structure(app_dir = app_dir, port = port, debug = debug)

    # apply the tests for each branch/commit
    perf_list <- tryCatch(
      expr = {
        mapply(
          commit_list,
          cypress_file,
          FUN = run_cypress_performance_test,
          project_path = project_path,
          debug = debug
        )
      },
      error = function(e) {
        message(e)
      },
      finally = {
        checkout(branch = current_branch)
        message(glue("Switched back to {current_branch}"))

        # Cleaning the temporary directory
        unlink(
          x = c(
            file.path(project_path, "node"),
            file.path(project_path, "tests")
          ),
          recursive = TRUE
        )
      }
    )
  } else {
    # creating the structure
    project_path <- create_shinytest2_structure(shinytest2_dir = shinytest2_dir)

    # apply the tests for each branch/commit
    perf_list <- tryCatch(
      expr = {
        lapply(
          X = commit_list,
          FUN = run_shinytest2_performance_test,
          app_dir = app_dir,
          project_path = project_path,
          debug = debug
        )
      },
      error = function(e) {
        message(e)
      },
      finally = {
        checkout(branch = current_branch)
        message(glue("Switched back to {current_branch}"))

        # Cleaning the temporary directory
        unlink(x = file.path(project_path, "tests"), recursive = TRUE)
      }
    )
  }

  return(perf_list)
}

#' @title Run the performance test based on a single commit using Cypress
#'
#' @param commit A commit hash code or a branch's name
#' @param project_path The path to the project with all needed packages installed
#' @param cypress_file The path to the .js file conteining cypress tests to be recorded
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @export
run_cypress_performance_test <- function(commit, project_path, cypress_file, debug) {
  # copy the cypress test file from the current location and store it
  cypress_file_cp <- file.path(project_path, "cypress_tests.js")
  file.copy(from = cypress_file, to = cypress_file_cp)

  files <- create_cypress_tests(project_path = project_path, cypress_file = cypress_file)
  js_file <- files$js_file
  txt_file <- files$txt_file

  # checkout to the desired commit
  checkout(branch = commit)
  date <- get_commit_date(branch = commit)
  message(glue("Switched to {commit}"))

  # run tests there
  command <- glue("cd {project_path}; set -eu; exec yarn --cwd node performance-test")
  system(command, ignore.stdout = !debug, ignore.stderr = !debug)

  # read the file saved by cypress
  perf_file <- read.table(file = txt_file, header = FALSE, sep = ";")
  perf_file <- cbind.data.frame(date = date, perf_file)
  colnames(perf_file) <- c("date", "test_name", "duration_ms")

  # removing temp files
  unlink(x = c(js_file, txt_file))

  # removing anything new in the github repo
  checkout_files()

  # return times
  return(perf_file)
}

#' @title Run the performance test based on a single commit using shinytest2
#'
#' @param commit A commit hash code or a branch's name
#' @param project_path The path to the project with all needed packages installed
#' @param cypress_file The path to the .js file conteining cypress tests to be recorded
#' @param txt_file The path to the file where it is aimed to save the times
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @importFrom testthat ListReporter
#' @importFrom shinytest2 test_app
#' @export
run_shinytest2_performance_test <- function(commit, app_dir, project_path, debug) {
  # checkout to the desired commit
  checkout(branch = commit)
  date <- get_commit_date(branch = commit)
  message(glue("Switched to {commit}"))

  # run tests there
  my_reporter <- ListReporter$new()
  test_app(app_dir = app_dir, reporter = my_reporter, stop_on_failure = FALSE, stop_on_warning = FALSE)
  perf_file <- as.data.frame(my_reporter$get_results())
  perf_file <- perf_file[, c("test", "real")]
  perf_file$test <- gsub(x = perf_file$test, pattern = "\\{shinytest2\\} recording: ", replacement = "")

  perf_file <- cbind.data.frame(date = date, perf_file)
  colnames(perf_file) <- c("date", "test_name", "duration_ms")

  # removing anything new in the github repo
  checkout_files()

  # return times
  return(perf_file)
}
