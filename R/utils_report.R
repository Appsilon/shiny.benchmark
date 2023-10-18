#' Create a performance report for the tests that were run
#'
#' @param report_params list of tests containing commits with dates, duration
#' time and test name
#' @param report_name name of the file to which the report should be saved, without
#' the extension
#' @param report_dir name of the folder where the report should be saved
#'
#' @importFrom quarto quarto_render
#' @importFrom rstudioapi selectDirectory
#' @export
create_report <- function(report_params, report_name, report_dir) {
  if (report_dir == "") {
    message("The name specified for the report's directory cannot be an empty string.")
    report_dir <- selectDirectory(caption = "Please pick the report's directory")
    message(glue("The report will be automatically saved in folder {report_dir}."))
  }

  file_paths <- prepare_file_paths(report_dir)
  prepare_dir_and_template(report_dir = report_dir,
                           file_paths = file_paths)
  message(
    glue(
      "Report template was copied for you. ",
      "You can edit and re-render it in {file_paths[2]}"
    )
  )
  message(
    glue(
      "You're creating a report named {report_name}. ",
      "It'll be created in the following dir: {report_dir}"
    )
  )
  message("This function is experimental!")

  report_file <- file.path(report_dir, glue(report_name, ".html"))
  quarto_render(input = file_paths[2],
                output_file = report_file,
                execute_params = report_params)
}


#' Prepare user's directory for the report and copy the report template from
#' the package to the user's directory
#'
#' @param report_dir name of the folder where the report should be saved
#' @param file_paths two-element vector with paths to template reports
prepare_dir_and_template <- function(report_dir, file_paths) {
  dir.create(path = report_dir, showWarnings = FALSE)
  file.copy(from = file_paths[1],
            to = file_paths[2],
            overwrite = TRUE)
}

#' Prepare file paths for package and user sides report templates
#'
#' @param report_dir name of the folder where the report should be saved
#'
#' @return two-element vector with paths to template reports
prepare_file_paths <- function(report_dir) {
  template_file_pkg <- system.file("templates", "report_template.qmd",
                                   package = "shiny.benchmark")
  template_file_usr <- file.path(report_dir, "report.qmd")
  return(c(template_file_pkg, template_file_usr))
}
