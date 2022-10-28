###############################################################################
# Start a git repo under app/ folder here and create some branches. It can be #
# more fun if you change the parameters in app/server.R                       #
#                                                                             #
# suggestion:                                                                 #
# git init                                                                    #
#                                                                             #
# main                                                                        #
# git add .                                                                   #
# git commit -m "first commit"                                                #
#                                                                             #
# # develop                                                                   #
# git checkout -b develop                                                     #
# git commit --allow-empty -m "dummy commit to change hash"                   #
#                                                                             #
# # feature                                                                   #
# git checkout -b feature                                                     #
# git commit --allow-empty -m "dummy commit to change hash"                   #
###############################################################################

# packages
library(shiny.benchmark)

# commits to compare
type <- "cypress"
commit_list <- c("develop", "feature") # be sure you created these branches
dir <- "tests/cypress"
pattern <- "use_this_one_[0-9]"
use_renv <- FALSE
n_rep <- 5

if (type == "cypress") {
  # run performance check using Cypress
  out <- benchmark(
    commit_list = commit_list,
    cypress_dir = dir,
    tests_pattern = pattern,
    app_dir = getwd(),
    use_renv = use_renv,
    renv_prompt = TRUE,
    port = 3333,
    n_rep = n_rep,
    debug = FALSE
  )
} else {
  # run performance check using shinytest2
  out <- benchmark(
    commit_list = commit_list,
    shinytest2_dir = dir,
    tests_pattern = pattern,
    app_dir = getwd(),
    use_renv = use_renv,
    renv_prompt = TRUE,
    port = 3333,
    n_rep = n_rep,
    debug = FALSE
  )
}
