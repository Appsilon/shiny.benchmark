#' Summary for shiny_benchmark class
#'
#' @param object shiny_benchmark object
#' @param ... Other parameters
#'
#' @return Return a `data.frame` with performance tests' summary statistics
#'
#' @method summary shiny_benchmark
#' @export
summary.shiny_benchmark <- function(object, ...) {
  if (!requireNamespace(package = "dplyr", quietly = TRUE))
    stop("dplyr is missing. Please, consider intalling dplyr.")

  summary_results <- lapply(X = object$performance, FUN = summarise_commit)
  summary_results <- bind_rows(summary_results, .id = "commit")

  return(summary_results)
}
