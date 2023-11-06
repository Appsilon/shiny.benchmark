#' @title Create a performance report for the tests that were run
#'
#' @param report_params list of tests containing commits with dates, duration
#' time and test name
#' @param file name of the file to which the report should be saved (.html)
#'
#' @importFrom quarto quarto_render
#' @export
create_report <- function(report_params, file = NULL) {
  # stop execution in case file is not provided
  if (is.null(file)) {
    return(
      message("`file` cannot be NULL")
    )
  }

  # manage template in roder to create the report
  report_dir <- dirname(file)
  report_template_file <- prepare_dir_and_template(
    report_dir = report_dir
  )

  # generate HTML
  # move work directory in order to run quarto
  quarto_render(
    input = report_template_file,
    output_file = file,
    execute_params = report_params
  )
}

#' @title Prepare directory for the report
#' @description Prepare user's directory for the report and copy the report template from
#' the package to the user's directory
#'
#' @param report_dir name of the folder where the report should be saved
prepare_dir_and_template <- function(report_dir) {
  # create folders if needed
  file_paths <- prepare_file_paths(report_dir)
  dir.create(
    path = report_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )

  # copy file from template to report dir
  file.copy(
    from = file_paths$package,
    to = file_paths$user,
    overwrite = TRUE
  )

  # inform user about the report
  message(
    glue(
      "Report template was created at `{report_dir}`. You can edit the and re-render it in {file_paths$user}"
    )
  )

  # return template path
  return(file_paths$user)
}

#' @title Prepare file paths for package and user sides report templates
#'
#' @param report_dir name of the folder where the report should be saved
#'
#' @return two-element vector with paths to template reports
prepare_file_paths <- function(report_dir) {
  template_file_pkg <- system.file(
    "templates",
    "report_template.qmd",
    package = "shiny.benchmark"
  )
  template_file_usr <- file.path(report_dir, "report.qmd")

  out <- list(
    package = template_file_pkg,
    user = template_file_usr
  )
  return(out)
}
