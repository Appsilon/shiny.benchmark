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
#' @description checkout anything created by the app. It prevents errors when
#' changing branches
checkout_files <- function() {
  system("git checkout .")
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
