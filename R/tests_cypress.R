#' @title Run the performance test based on multiple commits using Cypress
#'
#' @param commit_list A list of commit hash codes, branches' names or anything
#' else you can use with git checkout [...]
#' @param cypress_file The path to the .js file conteining cypress tests to
#' be recorded
#' @param app_dir The path to the application root
#' @param port Port to run the app
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @export
ptest_cypress <- function(commit_list, cypress_file, app_dir, port, debug) {
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
        cypress_file,
        FUN = run_cypress_ptest,
        project_path = project_path,
        debug = debug,
        SIMPLIFY = FALSE
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

  return(perf_list)
}

#' @title Run the performance test based on a single commit using Cypress
#'
#' @param commit A commit hash code or a branch's name
#' @param project_path The path to the project with all needed packages
#' installed
#' @param cypress_file The path to the .js file conteining cypress tests to
#' be recorded
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @importFrom utils read.table
#' @export
run_cypress_ptest <- function(commit, project_path, cypress_file, debug) {
  # checkout to the desired commit
  checkout(branch = commit)
  date <- get_commit_date(branch = commit)
  message(glue("Switched to {commit}"))

  # get Cypress files
  files <- create_cypress_tests(
    project_path = project_path,
    cypress_file = cypress_file
  )

  js_file <- files$js_file
  txt_file <- files$txt_file

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
