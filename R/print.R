#' Print for shiny_benchmark class
#'
#' @param x shiny_benchmark object
#' @param ... Other parameters
#'
#' @return Print on the console information about the `shiny_benchmark` object
#'
#' @method print shiny_benchmark
#' @export
print.shiny_benchmark <- function(x, ...) {
  cat("shiny benchmark: \n")
  cat("\n")
  cat("Call:")
  cat("\n")
  print(x$call)
  cat("\n")
  cat("Total time ellapsed:")
  cat("\n")
  print(x$time[["elapsed"]])
  cat("\n")
  cat("Fit measures: \n")
  print(x$performance)
}
