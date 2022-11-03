TEMPLATE_FILE_USR <- "performance_report/report.qmd"
TEMPLATE_FILE_PKG <-
  system.file("templates", "report_template.qmd",
              package = "shiny.benchmark")

#' Create a performance report for the tests that were run
#'
#' @param report_params list of tests containing commits with dates, duration
#' time and test name
#' @param report_name name of the file to which the report should be saved, without
#' the extension
#'
#' @importFrom quarto quarto_render
#' @export
create_report <- function(report_params, report_name) {
  prepare_dir_and_template()
  report_file <- file.path("performance_report", glue(report_name, ".html"))
  quarto_render(input = TEMPLATE_FILE_USR,
                output_file = report_file,
                execute_params = report_params)
}


#' Prepare user's directory for the report and copy the report template from
#' the package to the user's directory
prepare_dir_and_template <- function() {
  dir.create(path = "performance_report", showWarnings = FALSE)
  file.copy(from = TEMPLATE_FILE_PKG,
            to = TEMPLATE_FILE_USR,
            overwrite = TRUE)
}
