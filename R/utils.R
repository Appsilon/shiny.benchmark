#' @title Get the commit date in POSIXct format
#'
#' @param branch Commit hash code or branch name
#' @importFrom glue glue
#'
#' @keywords internal
get_commit_date <- function(branch) {
  date <- system(
    command = glue("git show -s --format=%ci {branch}"),
    intern = TRUE
  )
  date <- as.POSIXct(date[1])

  return(date)
}

#' @title Find the hash code of the current commit
#'
#' @importFrom glue glue
#' @importFrom stringr str_trim
#'
#' @keywords internal
get_commit_hash <- function() {
  hash <- system(command = "git show -s --format=%H", intern = TRUE)[1]

  branch <- system(
    command = glue("git branch --contains {hash}"),
    intern = TRUE
  )

  branch <- str_trim(
    string = gsub(
      x = branch[length(branch)],
      pattern = "\\*\\s",
      replacement = ""
    ),
    side = "both"
  )

  hash_head <- system(
    command = glue("git rev-parse {branch}"),
    intern = TRUE
  )

  is_head <- hash == hash_head

  if (is_head) hash <- branch

  return(hash)
}

#' @title Checkout GitHub files
#'
#' @description Checkout anything created by the app. It prevents errors when
#' changing branches
#'
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @keywords internal
checkout_files <- function(debug) {
  system(
    command = "git checkout .",
    ignore.stdout = !debug,
    ignore.stderr = !debug
  )
}

#' @title Checkout GitHub branch
#'
#' @description checkout and go to a different branch
#'
#' @param branch Commit hash code or branch name
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @keywords internal
checkout <- function(branch, debug) {
  system(
    command = glue("git checkout {branch}"),
    ignore.stdout = !debug,
    ignore.stderr = !debug
  )
}

#' @title Running the node script "performance_test" is system-dependent
#'
#' @param project_path path to project directory (one level above node)
#'
#' @keywords internal
performance_test_cmd <- function(project_path) {
  if (grepl("win", .Platform$OS.type, ignore.case = TRUE)) {
    glue("yarn --cwd \"{path(project_path, 'node')}\" performance-test")
  } else {
    glue("cd {project_path}; set -eu; exec yarn --cwd node performance-test")
  }
}

#' @title Wrapper to call on Operating System commands
#'
#' @param cmd command
#' @param system a logical (not NA) which indicates whether to use
#' shell or system call (system is a more low-level call)
#' @param intern a logical (not NA) which indicates whether to capture
#' the output of the command as an R character vector.
#'
#' @param ... Other paramters passed to shell or system
#'
#' @return see system or shell
#'
#' @keywords internal
command_wrapper <- function(cmd, ...) {
  logger::log_debug("cmd (system): {cmd}")
  system(command = cmd, ...)
}

#' @title Check if git commit hash exists
#'
#' @description Can be anything git recognizes as a commit, such
#' as a commit hash, a branch, a tag, ...
#'
#' @param commit commit hash code, branch name or tag
#'
#' @return true if exists, an error message if not
#'
#' @keywords internal
commit_exists <- function(commit) {
  result <- command_wrapper(
    cmd = glue::glue("git rev-parse --verify {commit}"),
    intern = FALSE,
    wait = TRUE
  )
  if (result == 128) {
    rlang::abort(
      message = glue(
        "git error:: Commit/branch/tag/.. '{commit}' doesn't exist"
      )
    )
  }
  TRUE
}

#' @title Check for uncommitted files
#'
#' @keywords internal
check_uncommitted_files <- function() {
  changes <- system("git status --porcelain", intern = TRUE)

  if (length(changes) != 0) {
    system("git status -u")
    stop("You have uncommitted files. Please resolve it before running the performance checks.")
  } else {
    return(invisible(TRUE))
  }
}

#' @title Check and restore renv
#'
#' @description Check whether renv is in use in the current branch. Raise error
#' if renv is not in use or apply renv:restore() in the case the package is
#' present
#'
#' @param branch Commit hash code or branch name. Useful to create an
#' informative error message
#' @param renv_prompt Prompt the user before taking any action?
#' @importFrom glue glue
#' @importFrom renv activate restore
#'
#' @keywords internal
restore_env <- function(branch, renv_prompt) {
  # handling renv
  tryCatch(
    expr = {
      activate()
      restore(prompt = renv_prompt)
    },
    error = function(e) {
      stop(glue("Unexpected error activating renv in branch {branch}: {e}\n"))
    }
  )
}

#' @title Create a progress bar to follow the execution
#'
#' @param total Total number of replications
#' @importFrom progress progress_bar
#'
#' @keywords internal
create_progress_bar <- function(total = 100) {
  pb <- progress_bar$new(
    format = "Iteration :current/:total",
    total = total,
    clear = FALSE
  )

  return(pb)
}

#' @title Return statistics based on the set of tests replications
#'
#' @param object A shiny_benchmark object
#'
#' @import dplyr
#' @importFrom stats median
#'
#' @keywords internal
summarise_commit <- function(object) {
  out <- bind_rows(object) %>%
    group_by(test_name) %>%
    summarise(
      n = n(),
      mean = mean(duration_ms),
      median = median(duration_ms),
      sd = sd(duration_ms),
      min = min(duration_ms),
      max = max(duration_ms)
    )

  return(out)
}

#' @title Load an application and instructions to run shiny.benchmark
#' @description This function aims to generate a template to be used
#' by shiny.benchmark. It will create the necessary structure on `path` with
#' some examples of tests using Cypress and shinytest2. Also, a simple
#' application will be added to the folder as well as instructions on how
#' to perform the performance checks. Be aware that a new git repo is need in
#' the selected `path`.
#'
#' @param path A character vector of full path name
#'
#' @importFrom glue glue
#' @importFrom utils menu
#' @export
load_example <- function(path) {
  # see if path exists
  if (!file.exists(path))
    stop("You must provide a valid path")

  if (length(list.files(path))) {
    choice <- menu(
      choices = c("Yes", "No"),
      title = glue("{path} seems to not be empty. Would you like to proceed?")
    )

    if (choice == 2)
      stop("Process aborted by user. Consider creating a new empty path.")
  }

  ex_path <- system.file(
    "examples",
    package = "shiny.benchmark",
    mustWork = TRUE
  )
  files <- list.files(path = ex_path, full.names = TRUE)

  for (file in files) {
    file.copy(from = file, to = path, recursive = TRUE)
    print(glue("{basename(file)} created at {path}"))
  }

  fpath <- path(path, "run_tests.R") # nolint
  message(glue("Follow instructions in {fpath}"))
}
