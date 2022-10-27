#' Print for shiny_benchmark class
#'
#' @param object shiny_benchmark object to print
#'
#' @method print shiny_benchmark
#' @export
print.shiny_benchmark <- function(object){
  cat('Shiny benchmark: \n')
  cat('\n')
  cat('Call:')
  cat('\n')
  print(object$call)
  cat('\n')
  cat('Total time ellapsed:')
  cat('\n')
  print(object$time[["elapsed"]])
  cat('\n')
  cat('Fit measures: \n')
  print(object$performance)
}
