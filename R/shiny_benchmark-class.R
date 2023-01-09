#' @title An object of 'shiny_benchmark' class
#'
#' @slot call Function call
#' @slot time Time elapsed
#' @slot performance List of measurements (one entry for each commit)
#'
#' @importFrom methods new
#'
#' @export

shiny_benchmark_class <- setClass(
  Class = "shiny_benchmark",
  representation(
    call = "call",
    time = "proc_time",
    performance = "list"
  )
)
