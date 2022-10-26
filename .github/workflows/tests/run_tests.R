#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
args <- strsplit(args, ",")

# packages
library(shiny)
library(testthat)

if (!require(shiny.performance)) {
  remotes::install_github(
    repo = 'Appsilon/experimental.performance',
    auth_token = Sys.getenv('GITHUB_PAT'),
    ref = 'douglas-31-create-test-environment',
    quiet = TRUE
  )
}

# commits to compare
type <- args[[1]]
commit_list <- args[[2]]
tests <- args[[3]]
use_renv <- args[[4]]

if (type == "cypress") {
  # run performance check using Cypress
  out <- shiny.performance::performance_tests(
    commit_list = commit_list,
    cypress_file = tests,
    app_dir = getwd(),
    use_renv = use_renv,
    renv_prompt = FALSE,
    port = 3333,
    debug = FALSE
  )
} else {
  # run performance check using shinytest2
  out <- shiny.performance::performance_tests(
    commit_list = commit_list,
    shinytest2_dir = tests,
    app_dir = getwd(),
    use_renv = use_renv,
    renv_prompt = FALSE,
    port = 3333,
    debug = FALSE
  )
}

# checks
stopifnot(length(out) == length(commit_list))
