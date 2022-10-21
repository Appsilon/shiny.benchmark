#' @title Run the performance test based on a multiple commits using shinytest2
#'
#' @param commit_list A list of commit hash codes, branches' names or anything
#' else you can use with git checkout [...]
#' @param shinytest2_dir The directory with tests recorded by shinytest2
#' It can also be a vector of the same size of commit_list
#' @param app_dir The path to the application root
#' @param use_renv In case it is set as TRUE, package will try to apply
#' renv::restore() in all branches. Otherwise, the current loaded list of
#' packages will be used in all branches.
#' @param renv_prompt Prompt the user before taking any action?
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @export
ptest_shinytest2 <- function(
    commit_list,
    shinytest2_dir,
    app_dir,
    use_renv,
    renv_prompt,
    debug
) {
  # creating the structure
  project_path <- create_shinytest2_structure(app_dir = app_dir)

  # getting the current branch
  current_branch <- get_commit_hash()

  # apply the tests for each branch/commit
  perf_list <- tryCatch(
    expr = {
      mapply(
        commit_list,
        shinytest2_dir,
        FUN = run_shinytest2_ptest,
        app_dir = app_dir,
        project_path = project_path,
        debug = debug,
        SIMPLIFY = FALSE
      )
    },
    error = function(e) {
      message(e)
    },
    finally = {
      # Checkout to the main branch
      checkout(branch = current_branch)
      message(glue("Switched back to {current_branch}"))

      # Restore renv
      if (use_renv)
        restore_env(branch = current_branch, renv_prompt = renv_prompt)

      # Cleaning the temporary directory
      unlink(x = file.path(project_path, "tests"), recursive = TRUE)
    }
  )

  return(perf_list)
}

#' @title Run the performance test based on a single commit using shinytest2
#'
#' @param commit A commit hash code or a branch's name
#' @param app_dir The path to the application root
#' @param project_path The path to the project
#' @param shinytest2_dir The directory with tests recorded by shinytest2
#' @param use_renv In case it is set as TRUE, package will try to apply
#' renv::restore() in all branches. Otherwise, the current loaded list of
#' packages will be used in all branches.
#' @param renv_prompt Prompt the user before taking any action?
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @importFrom testthat ListReporter
#' @importFrom shinytest2 test_app
#' @export
run_shinytest2_ptest <- function(
    commit,
    project_path,
    app_dir,
    shinytest2_dir,
    use_renv,
    renv_prompt,
    debug
) {
  # checkout to the desired commit
  checkout(branch = commit)
  date <- get_commit_date(branch = commit)
  message(glue("Switched to {commit}"))
  if (use_renv) restore_env(branch = commit, renv_prompt = renv_prompt)

  # move test files to the project folder
  tests_dir <- move_shinytest2_tests(project_path = project_path, shinytest2_dir = shinytest2_dir)

  # run tests there
  my_reporter <- ListReporter$new()
  test_app(
    app_dir = dirname(tests_dir),
    reporter = my_reporter,
    stop_on_failure = FALSE,
    stop_on_warning = FALSE
  )

  perf_file <- as.data.frame(my_reporter$get_results())
  perf_file <- perf_file[, c("test", "real")]
  perf_file$test <- gsub(
    x = perf_file$test,
    pattern = "\\{shinytest2\\} recording: ",
    replacement = ""
  )

  perf_file <- cbind.data.frame(date = date, perf_file)
  colnames(perf_file) <- c("date", "test_name", "duration_ms")

  # removing anything new in the github repo
  checkout_files()

  # return times
  return(perf_file)
}
