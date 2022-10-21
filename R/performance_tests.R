#' @title Execute performance tests for a list of commits
#'
#' @param commit_list A list of commit hash codes, branches' names or anything
#' else you can use with git checkout [...]
#' @param cypress_file The path to the .js file containing cypress tests
#' to be recorded. It can also be a vector of the same size of commit_list
#' @param shinytest2_dir The directory with tests recorded by shinytest2
#' It can also be a vector of the same size of commit_list
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
  # Number of commits to test
  n_commits <- length(commit_list)

  # Test whether we have everything we need
  if (is.null(cypress_file) && is.null(shinytest2_dir))
    stop("You must provide a cypress_file or the shinytest2_dir")

  if (!is.null(cypress_file) && !is.null(shinytest2_dir)) {
    message("Using the cypress file only")
    shinytest2_dir <- NULL
  }

  type <- ifelse(!is.null(cypress_file), "cypress", "shinytest2")
  obj_name <- ifelse(type == "cypress", "cypress_file", "shinytest2_dir")

  if (length(get(obj_name)) == 1)
    assign(obj_name, rep(cypress_file, n_commits))
  if (length(get(obj_name)) != n_commits)
    stop("You must provide 1 or {n_commits} paths for {obj_name}")

  # run tests
  if (type == "cypress") {
    perf_list <- ptest_cypress(
      commit_list = commit_list,
      cypress_file = cypress_file,
      app_dir = app_dir,
      port = port,
      use_renv = use_renv,
      renv_prompt = renv_prompt,
      debug = debug
    )
  } else {
    perf_list <- ptest_shinytest2(
      commit_list,
      shinytest2_dir,
      app_dir,
      use_renv = use_renv,
      renv_prompt = renv_prompt,
      debug
    )
  }

  return(perf_list)
}
