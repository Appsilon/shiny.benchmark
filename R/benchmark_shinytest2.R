#' @title Run the performance test based on a multiple commits using shinytest2
#'
#' @param commit_list A list of commit hash codes, branches' names or anything
#' else you can use with git checkout [...]
#' @param shinytest2_dir The directory with tests recorded by shinytest2
#' It can also be a vector of the same size of commit_list
#' @param tests_pattern shinytest2 files pattern. E.g. 'performance'
#' It can also be a vector of the same size of commit_list. If it is NULL,
#' all the content in cypress_dir/shinytest2_dir will be used
#' @param app_dir The path to the application root
#' @param use_renv In case it is set as TRUE, package will try to apply
#' renv::restore() in all branches. Otherwise, the current loaded list of
#' packages will be used in all branches.
#' @param renv_prompt Prompt the user before taking any action?
#' @param n_rep Number of replications desired
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @return Return a `list` with the collected performance times
#'
#' @export
benchmark_shinytest2 <- function(
    commit_list,
    shinytest2_dir,
    tests_pattern,
    app_dir,
    use_renv,
    renv_prompt,
    n_rep,
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
        tests_pattern,
        FUN = run_shinytest2_ptest,
        app_dir = app_dir,
        project_path = project_path,
        use_renv = use_renv,
        renv_prompt = renv_prompt,
        n_rep = n_rep,
        debug = debug,
        SIMPLIFY = FALSE
      )
    },
    error = function(e) {
      message(e)
    },
    finally = {
      # Checkout to the main branch
      checkout(branch = current_branch, debug = debug)
      message(glue("Switched back to {current_branch}"))

      # Restore renv
      if (use_renv)
        restore_env(branch = current_branch, renv_prompt = renv_prompt)

      # Cleaning the temporary directory
      #  couldn't use fs::file_delete / fs::directory_delete as a process
      #  is accessing one of the files and it fails. unlink does not
      unlink(fs::path(project_path, "tests"))
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
#' @param tests_pattern shinytest2 files pattern. E.g. 'performance'. If it is NULL,
#' all the content will be used
#' @param use_renv In case it is set as TRUE, package will try to apply
#' renv::restore() in all branches. Otherwise, the current loaded list of
#' packages will be used in all branches.
#' @param renv_prompt Prompt the user before taking any action?
#' @param n_rep Number of replications desired
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @return Return a `data.frame` with the collected performance time
#'
#' @importFrom testthat ListReporter
#' @importFrom shinytest2 test_app
#' @export
run_shinytest2_ptest <- function(
    commit,
    project_path,
    app_dir,
    shinytest2_dir,
    tests_pattern,
    use_renv,
    renv_prompt,
    n_rep,
    debug
) {
  # checkout to the desired commit
  checkout(branch = commit, debug = debug)
  date <- get_commit_date(branch = commit)
  message(glue("Switched to {commit}"))
  if (use_renv) restore_env(branch = commit, renv_prompt = renv_prompt)

  # move test files to the project folder
  tests_dir <- move_shinytest2_tests(
    project_path = project_path,
    shinytest2_dir = shinytest2_dir
  )

  perf_file <- list()
  pb <- create_progress_bar(total = n_rep)
  for (i in 1:n_rep) {
    # increment progress bar
    pb$tick()

    # run tests there
    my_reporter <- ListReporter$new()
    test_app(
      app_dir = dirname(tests_dir),
      reporter = my_reporter,
      stop_on_failure = FALSE,
      stop_on_warning = FALSE,
      filter = tests_pattern
    )

    perf_file[[i]] <- as.data.frame(my_reporter$get_results())
    perf_file[[i]] <- perf_file[[i]][, c("test", "real")]
    perf_file[[i]]$test <- gsub(
      x = perf_file[[i]]$test,
      pattern = "\\{shinytest2\\} recording: ",
      replacement = ""
    )

    perf_file[[i]] <- cbind.data.frame(date = date, rep_id = i, perf_file[[i]])
    colnames(perf_file[[i]]) <- c("date", "rep_id", "test_name", "duration_ms")
  }

  # removing anything new in the github repo
  checkout_files(debug = debug)

  # return times
  return(perf_file)
}
