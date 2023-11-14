#' @title Combine list of performances in a single data.frame
#'
#' @param performance_list list of tests containing commits with dates, duration
#' time and test name
#'
#' @export
combine_performances <- function(performance_list) {
  # create an unique data.frame for all branches and repetitions
  df_all <- mapply(
    performance_list,
    names(performance_list),
    FUN = function(x, y) {
      df <- bind_rows(x)
      df$branch <- y

      return(df)
    },
    SIMPLIFY = FALSE
  )

  # bind rows
  df_all <- bind_rows(df_all)

  # return a single data.frame
  return(df_all)
}

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

  # manage template in order to create the report
  report_dir <- dirname(file)
  report_file <- basename(file)
  report_template_file <- prepare_dir_and_template(
    report_dir = report_dir
  )
  report_template_file <- basename(report_template_file)

  # generate HTML
  # move work directory in order to run quarto
  wb <- getwd()
  on.exit(expr = {
    setwd(dir = wb)
  })

  setwd(dir = report_dir)
  quarto_render(
    input = report_template_file,
    output_file = report_file,
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
      "Report template was created at `{report_dir}`.
      You can edit the and re-render it in {file_paths$user}"
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
