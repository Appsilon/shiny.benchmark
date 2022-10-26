PATH_DIR_REPORTS <- file.path("inst", "qmd")
PATH_DIR_TEMPLATES <- file.path("inst", "templates")
PATH_FILE_REPORT_TEMPLATE <- file.path(PATH_DIR_TEMPLATES,
                                       "report_template.qmd")

#' Create a performance report for the tests that were run
#'
#' @param report_params list of tests containing commits with dates, duration
#' time and test name
#' @param filename name of the file to which the report should be saved, without
#' the extension
#'
#' @export
create_report <- function(report_params,
                          filename) {
  report_file <- file.path(PATH_DIR_REPORTS, glue(filename, ".html"))
  quarto_render(input = PATH_FILE_REPORT_TEMPLATE,
                output_file = report_file,
                execute_params = report_params)
}
