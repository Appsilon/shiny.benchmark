#' @title Execute performance tests for a list of commits
#'
#' @param commit_list A list of commit hash codes, branches' names or anything
#' else you can use with git checkout [...]
#' @param cypress_dir The directory with tests recorded by Cypress.
#' It can also be a vector of the same size of commit_list
#' @param shinytest2_dir The directory with tests recorded by shinytest2
#' It can also be a vector of the same size of commit_list
#' @param tests_pattern Cypress/shinytest2 files pattern. E.g. 'performance'
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
#' @return Return a `shiny_benchmark` object containing the `benchmark` call,
#' elapsed time and a `list` with the collected performance times
#'
#' @importFrom glue glue
#' @export
benchmark <- function(
    commit_list,
    cypress_dir = NULL,
    shinytest2_dir = NULL,
    tests_pattern = NULL,
    app_dir = getwd(),
    port = 3333,
    use_renv = TRUE,
    renv_prompt = TRUE,
    n_rep = 1,
    debug = FALSE
) {
  # Get the call parameters
  call_benchmark <- match.call()

  # Number of commits to test
  n_commits <- length(commit_list)

  # Test whether we have everything we need
  if (is.null(cypress_dir) && is.null(shinytest2_dir))
    stop("You must provide a cypress_dir or the shinytest2_dir")

  if (!is.null(cypress_dir) && !is.null(shinytest2_dir)) {
    message("Using the cypress file only")
    shinytest2_dir <- NULL
  }

  type <- ifelse(!is.null(cypress_dir), "cypress", "shinytest2")
  obj_name <- ifelse(type == "cypress", "cypress_dir", "shinytest2_dir")

  if (length(get(obj_name)) == 1)
    assign(obj_name, rep(get(obj_name), n_commits))
  if (length(get(obj_name)) != n_commits)
    stop(glue("You must provide 1 or {n_commits} paths for {obj_name}"))

  if (is.null(tests_pattern))
    tests_pattern <- vector(mode = "list", length = n_commits)
  if (length(tests_pattern) == 1)
    tests_pattern <- as.list(rep(tests_pattern, n_commits))

  n_rep <- as.integer(n_rep)
  if (n_rep < 1)
    stop("You must provide an integer greater than 1 for n_rep")

  # check if the repo is ready for running the checks
  check_uncommitted_files()

  # run tests
  total_time <- system.time(
    if (type == "cypress") {
      perf_list <- benchmark_cypress(
        commit_list = commit_list,
        cypress_dir = cypress_dir,
        tests_pattern = tests_pattern,
        app_dir = app_dir,
        port = port,
        use_renv = use_renv,
        renv_prompt = renv_prompt,
        n_rep = n_rep,
        debug = debug
      )
    } else {
      perf_list <- benchmark_shinytest2(
        commit_list,
        shinytest2_dir,
        tests_pattern = tests_pattern,
        app_dir,
        use_renv = use_renv,
        renv_prompt = renv_prompt,
        n_rep = n_rep,
        debug = debug
      )
    }
  )

  out <- list(
    call = call_benchmark,
    time = total_time,
    performance = perf_list
  )
  class(out) <- "shiny_benchmark"

  return(out)
}
