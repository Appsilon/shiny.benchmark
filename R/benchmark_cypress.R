#' @title Run the performance test based on multiple commits using Cypress
#'
#' @param commit_list A list of commit hash codes, branches' names or anything
#' else you can use with git checkout [...]
#' @param cypress_dir The directory with tests recorded by Cypress.
#' It can also be a vector of the same size of commit_list
#' @param tests_pattern Cypress/shinytest2 files pattern. E.g. 'shinytest2'
#' It can also be a vector of the same size of commit_list. If it is NULL,
#' all the content in cypress_dir/shinytest2_dir will be used
#' @param app_dir The path to the application root
#' @param port Port to run the app
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
benchmark_cypress <- function(
    commit_list,
    cypress_dir,
    tests_pattern,
    app_dir,
    port,
    use_renv,
    renv_prompt,
    n_rep,
    debug
) {
  # creating the structure
  project_path <- create_cypress_structure(
    app_dir = app_dir,
    port = port,
    debug = debug
  )

  # getting the current branch
  current_branch <- get_commit_hash()

  # apply the tests for each branch/commit
  perf_list <- tryCatch(
    expr = {
      mapply(
        commit_list,
        cypress_dir,
        tests_pattern,
        FUN = run_cypress_ptest,
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
      fs::file_delete(fs::path(project_path, "node"))
      fs::file_delete(fs::path(project_path, "tests"))
    }
  )

  return(perf_list)
}

#' @title Run the performance test based on a single commit using Cypress
#'
#' @param commit A commit hash code or a branch's name
#' @param project_path The path to the project with all needed packages
#' installed
#' @param cypress_dir The directory with tests recorded by Cypress
#' @param tests_pattern Cypress files pattern. E.g. 'performance'. If it is NULL,
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
#' @importFrom utils read.table
#' @export
run_cypress_ptest <- function(
    commit,
    project_path,
    cypress_dir,
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

  # get Cypress files
  files <- create_cypress_tests(
    project_path = project_path,
    cypress_dir = cypress_dir,
    tests_pattern = tests_pattern
  )
  js_file <- files$js_file
  txt_file <- files$txt_file

  # replicate tests
  perf_file <- list()
  pb <- create_progress_bar(total = n_rep)
  for (i in 1:n_rep) {
    # increment progress bar
    pb$tick()

    # run tests there
    command <- performance_test_cmd(project_path)
    system(command, ignore.stdout = !debug, ignore.stderr = !debug)

    # read the file saved by cypress
    perf_file[[i]] <- read.table(file = txt_file, header = FALSE, sep = ";")
    perf_file[[i]] <- cbind.data.frame(date = date, rep_id = i, perf_file[[i]])
    colnames(perf_file[[i]]) <- c("date", "rep_id", "test_name", "duration_ms")

    # removing txt measures
    fs::file_delete(txt_file)
  }

  # removing js tests
  fs::file_delete(js_file)

  # removing anything new in the github repo
  checkout_files(debug = debug)

  # return times
  return(perf_file)
}
