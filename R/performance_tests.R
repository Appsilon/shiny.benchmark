#' @title Execute performance tests for a list of commits
#'
#' @param commit_list A list of commit hash codes, branches' names or anything
#' else you can use with git checkout [...]
#' @param cypress_file The path to the .js file containing cypress tests
#' to be recorded
#' @param shinytest2_dir The directory with tests recorded by shinytest2
#' @param app_dir The path to the application root
#' @param port Port to run the app
#' @param use_renv In case it is set as TRUE, package will try to apply
#' renv::restore() in all branches. Otherwise, the current loaded list of
#' packages will be used in all branches.
#' @param renv_prompt Prompt the user before taking any action?
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @export
performance_tests <- function(
    commit_list,
    cypress_file = NULL,
    shinytest2_dir = NULL,
    app_dir = getwd(),
    port = 3333,
    use_renv = TRUE,
    renv_prompt = TRUE,
    debug = FALSE
) {
  # Test whether we have everything we need
  if (is.null(cypress_file) && is.null(shinytest2_dir))
    stop("You must provide a cypress_file or the shinytest2_dir")

  if (!is.null(cypress_file) && !is.null(shinytest2_dir)) {
    message("Using the cypress file only")
    shinytest2_dir <- NULL
  }

  type <- ifelse(!is.null(cypress_file), "cypress", "shinytest2")

  # getting the current branch
  current_branch <- get_commit_hash()

  # check if the repo is ready for running the checks
  check_uncommitted_files()

  if (type == "cypress") {
    # creating the structure
    project_path <- create_cypress_structure(
      app_dir = app_dir,
      port = port,
      debug = debug
    )

    # copy the cypress test file from the current location and store it
    cypress_file_cp <- file.path(project_path, "cypress_tests.js")
    file.copy(from = cypress_file, to = cypress_file_cp)

    # apply the tests for each branch/commit
    perf_list <- tryCatch(
      expr = {
        lapply(
          X = commit_list,
          FUN = run_cypress_ptest,
          project_path = project_path,
          cypress_file = cypress_file_cp,
          use_renv = use_renv,
          renv_prompt = renv_prompt,
          debug = debug
        )
      },
      error = function(e) {
        message(e)
      },
      finally = {
        # Restore initital setup
        checkout(branch = current_branch)
        message(glue("Switched back to {current_branch}"))
        if (use_renv) restore_env(branch = current_branch, renv_prompt = renv_prompt)

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
          FUN = run_shinytest2_ptest,
          app_dir = app_dir,
          project_path = project_path,
          use_renv = use_renv,
          renv_prompt = renv_prompt,
          debug = debug
        )
      },
      error = function(e) {
        message(e)
      },
      finally = {
        # Restore initital setup
        checkout(branch = current_branch)
        message(glue("Switched back to {current_branch}"))
        if (use_renv) restore_env(branch = current_branch, renv_prompt = renv_prompt)

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
#' @param project_path The path to the project with all needed
#' packages installed
#' @param cypress_file The path to the .js file conteining cypress tests
#' to be recorded
#' @param use_renv In case it is set as TRUE, package will try to apply
#' renv::restore() in all branches. Otherwise, the current loaded list of
#' packages will be used in all branches.
#' @param renv_prompt Prompt the user before taking any action?
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @importFrom utils read.table
#' @export
run_cypress_ptest <- function(commit, project_path, cypress_file, use_renv, renv_prompt, debug) {
  files <- create_cypress_tests(
    project_path = project_path,
    cypress_file = cypress_file
  )

  js_file <- files$js_file
  txt_file <- files$txt_file

  # checkout to the desired commit
  checkout(branch = commit)
  date <- get_commit_date(branch = commit)
  message(glue("Switched to {commit}"))

  # check if we are able to restore packages using renv
  if (use_renv) restore_env(branch = commit, renv_prompt = renv_prompt)

  # run tests there
  command <- glue(
    "cd {project_path}; ",
    "set -eu; exec yarn --cwd node performance-test"
  )
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
#' @param app_dir The path to the application root
#' @param project_path The path to the project with all needed
#' packages installed
#' @param use_renv In case it is set as TRUE, package will try to apply
#' renv::restore() in all branches. Otherwise, the current loaded list of
#' packages will be used in all branches.
#' @param renv_prompt Prompt the user before taking any action?
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @importFrom testthat ListReporter
#' @importFrom shinytest2 test_app
#' @export
run_shinytest2_ptest <- function(commit, app_dir, project_path, use_renv, renv_prompt, debug) {
  # checkout to the desired commit
  checkout(branch = commit)
  date <- get_commit_date(branch = commit)
  message(glue("Switched to {commit}"))

  # check if we are able to restore packages using renv
  if (use_renv) restore_env(branch = commit, renv_prompt = renv_prompt)

  # run tests there
  my_reporter <- ListReporter$new()
  test_app(
    app_dir = app_dir,
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

check_uncommitted_files <- function() {
  changes <- system("git status --porcelain", intern = TRUE)

  if (length(changes) != 0) {
    system("git status -uno")
    stop("You have uncommitted files. Please resolve it before running the performance checks.")
  } else {
    return(TRUE)
  }
}
