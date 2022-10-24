#' @title Get the commit date in POSIXct format
#'
#' @param branch Commit hash code or branch name
#' @importFrom glue glue
get_commit_date <- function(branch) {
  date <- system(
    glue("git show -s --format=%ci {branch}"),
    intern = TRUE
  )
  date <- as.POSIXct(date[1])

  return(date)
}

#' @title Find the hash code of the current commit
#'
#' @importFrom glue glue
#' @importFrom stringr str_trim
get_commit_hash <- function() {
  hash <- system("git show -s --format=%H", intern = TRUE)[1]
  branch <- system(
    glue("git branch --contains {hash}"),
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
    glue("git rev-parse {branch}"),
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
checkout_files <- function() {
  system("git checkout .")
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

#' @title Checkout GitHub branch
#' @description checkout and go to a different branch
#'
#' @param branch Commit hash code or branch name
checkout <- function(branch) {
  system(
    glue("git checkout {branch}")
  )
}

#' @title Create a progress bar to follow the execution
#'
#' @param total Total number of replications
#' @importFrom progress progress_bar
create_progress_bar <- function(total = 100) {
  pb <- progress_bar$new(
    format = "Iteration :current/:total",
    total = total,
    clear = FALSE
  )

  return(pb)
}
