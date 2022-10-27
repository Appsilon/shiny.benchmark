tmp_dir <- tempdir()
command <- paste0("git init ", tmp_dir)
system(command = command)
command <- paste0("cd ", tmp_dir, "; git add .; git commit --allow-empty -n -m 'Initial commit'")
system(command = command)

wd <- getwd()
setwd(tmp_dir)
on.exit(setwd(wd))

test_that("Check if commit date is in fact a date", {
  commit_date <- get_commit_date(branch = "master")
  expect_s3_class(object = commit_date, class = "POSIXct")
})

test_that("Check if we are able to get the commit hash", {
  commit_hash <- get_commit_hash()
  expect_true(is.character(commit_hash))
})
