template_file_usr <- "performance_report/report.qmd"

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
  report_file <-
    file.path("performance_report", glue(report_name, ".html"))
  quarto_render(input = template_file_usr,
                output_file = report_file,
                execute_params = report_params)
}


#' Prepare user's directory for the report and copy the report template from
#' the package to the user's directory
prepare_dir_and_template <- function() {
  template_file_pkg <- system.file("templates", "report_template.qmd",
                                   package = "shiny.benchmark")
  dir.create(path = "performance_report", showWarnings = FALSE)
  file.copy(from = template_file_pkg,
            to = template_file_usr,
            overwrite = TRUE)
}
