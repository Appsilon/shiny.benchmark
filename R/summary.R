#' Summary for shiny_benchmark class
#'
#' @param object shiny_benchmark object
#'
#' @method summary shiny_benchmark
#' @import dplyr
#' @export
summary.shiny_benchmark <- function(object){
  if (!require(dplyr))
    stop("dplyr is missing. Please, consider intalling dplyr.")

  summary_results <- lapply(X = object$performance, FUN = summarise_commit)
  summary_results <- bind_rows(summary_results, .id = "commit")

  return(summary_results)
}
