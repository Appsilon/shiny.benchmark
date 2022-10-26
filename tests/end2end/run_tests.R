#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
args <- strsplit(args, ",")

# packages
library(shiny)
library(testthat)
library(shiny.performance)

# commits to compare
type <- args[[1]]
commit_list <- args[[2]]
dir <- args[[3]]
pattern <- args[[4]]
use_renv <- args[[5]]
n_rep <- args[[6]]

if (type == "cypress") {
  # run performance check using Cypress
  out <- shiny.performance::performance_tests(
    commit_list = commit_list,
    cypress_dir = dir,
    tests_pattern = pattern,
    app_dir = getwd(),
    use_renv = use_renv,
    renv_prompt = FALSE,
    port = 3333,
    n_rep = n_rep,
    debug = FALSE
  )
} else {
  # run performance check using shinytest2
  out <- shiny.performance::performance_tests(
    commit_list = commit_list,
    shinytest2_dir = dir,
    tests_pattern = pattern,
    app_dir = getwd(),
    use_renv = use_renv,
    renv_prompt = FALSE,
    port = 3333,
    n_rep = n_rep,
    debug = FALSE
  )
}

# checks
stopifnot(length(out) == length(commit_list))
stopifnot(length(out[[1]]) >= n_rep)

# deactivate renv
renv::deactivate()
