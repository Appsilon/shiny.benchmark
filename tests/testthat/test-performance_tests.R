test_that("Function fails in case of missing cypress_file or shinytest2dir", {
  expect_error(
    performance_tests(
      commit_list = list("commit_1", "commit_2"),
      cypress_file = NULL,
      shinytest2_dir = NULL,
      app_dir = getwd(),
      port = 3333,
      use_renv = TRUE,
      renv_prompt = TRUE,
      debug = FALSE
    )
  )
})

test_that("Function fails in case of divergences between commit_list and files length", {
  expect_error(
    performance_tests(
      commit_list = list("commit_1", "commit_2"),
      cypress_file = c("file_1", "file_2", "file_3"),
      shinytest2_dir = NULL,
      app_dir = getwd(),
      port = 3333,
      use_renv = TRUE,
      renv_prompt = TRUE,
      debug = FALSE
    )
  )

  expect_error(
    performance_tests(
      commit_list = list("commit_1", "commit_2"),
      cypress_file = NULL,
      shinytest2_dir = c("file_1", "file_2", "file_3"),
      app_dir = getwd(),
      port = 3333,
      use_renv = TRUE,
      renv_prompt = TRUE,
      debug = FALSE
    )
  )
})
