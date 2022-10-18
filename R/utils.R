#' @title Create a temporary directory to store everything needed by shinytest2
#'
#' @param shinytest2_dir The path to the shinytest2 tests
create_shinytest2_structure <- function(shinytest2_dir) {
  # temp dir to run the tests
  dir_tests <- tempdir()

  # copy everything to the temporary directory
  system(glue("cp -r {shinytest2_dir} {dir_tests}"))

  # returning the project folder
  message(glue("Structure created at {dir_tests}"))
  return(dir_tests)
}

#' @title Create a temporary directory to store everything needed by Cypress
#'
#' @param app_dir The path to the application root
#' @param port Port to run the app
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @importFrom jsonlite write_json
create_cypress_structure <- function(app_dir, port, debug) {
  # temp dir to run the tests
  dir_tests <- tempdir()

  # node path
  node_path <- file.path(dir_tests, "node")
  root_path <- file.path(node_path, "root")

  # test path
  tests_path <- file.path(dir_tests, "tests")
  cypress_path <- file.path(tests_path, "cypress")
  integration_path <- file.path(cypress_path, "integration")
  plugins_path <- file.path(cypress_path, "plugins")

  # creating paths
  dir.create(path = node_path, showWarnings = FALSE)
  dir.create(path = tests_path, showWarnings = FALSE)
  dir.create(path = cypress_path, showWarnings = FALSE)
  dir.create(path = integration_path, showWarnings = FALSE)
  dir.create(path = plugins_path, showWarnings = FALSE)

  # create a path root linked to the main directory app
  symlink_cmd <- glue("cd {dir_tests}; ln -s {app_dir} {root_path}")
  system(symlink_cmd)

  # create the packages.json file
  json_txt <- create_node_list(tests_path = tests_path, port = port)
  json_file <- file.path(node_path, "package.json")
  write_json(x = json_txt, path = json_file, pretty = TRUE, auto_unbox = TRUE)

  # install everything that is needed
  install_deps <- glue("yarn --cwd {node_path}")
  system(install_deps, ignore.stdout = !debug, ignore.stderr = !debug)

  # creating cypress plugin file
  js_txt <- create_cypress_plugins()
  js_file <- file.path(plugins_path, "index.js")
  writeLines(text = js_txt, con = js_file)

  # creating cypress.json
  json_txt <- create_cypress_list(plugins_file = js_file, port = port)
  json_file <- file.path(tests_path, "cypress.json")
  write_json(x = json_txt, path = json_file, pretty = TRUE, auto_unbox = TRUE)

  # returning the project folder
  message(glue("Structure created at {dir_tests}"))
  return(dir_tests)
}

#' @title Create the list of needed libraries
#'
#' @param tests_path The path to project
create_node_list <- function(tests_path, port) {
  json_list <- list(
    private = TRUE,
    scripts = list(
      "performance-test" = glue("start-server-and-test run-app http://localhost:{port} run-cypress"),
      "run-app" = glue("cd root && Rscript -e 'shiny::runApp(port = {port})'"),
      "run-cypress" = glue("cypress run --project {tests_path}")
    ),
    "devDependencies" = list(
      "cypress" = "^7.6.0",
      "start-server-and-test" = "^1.12.6"
    )
  )

  return(json_list)
}

#' @title Create the cypress configuration list
#'
#' @param plugins_file The path to the Cypress plugins
create_cypress_list <- function(plugins_file, port) {
  json_list <- list(
    baseUrl = glue("http://localhost:{port}"),
    pluginsFile = plugins_file,
    supportFile = FALSE
  )

  return(json_list)
}

#' @title Create the JS code to track execution time
create_cypress_plugins <- function() {
  js_txt <- "
  const fs = require('fs')
  module.exports = (on, config) => {
    on('task', {
      performanceTimes (attributes) {
        fs.writeFile(attributes.fileOut, `${ attributes.title }; ${ attributes.duration }\n`, { flag: 'a' })
        return null
      }
    })
  }"

  return(js_txt)
}

#' @title Create the cypress files under project directory
#'
#' @param project_path The path to the project with all needed packages installed
#' @param cypress_file The path to the .js file conteining cypress tests to be recorded
create_cypress_tests <- function(project_path, cypress_file) {
  # creating a copy to be able to edit the js file
  js_file <- file.path(project_path, "tests", "cypress", "integration", "app.spec.js")
  file.copy(from = cypress_file, to = js_file, overwrite = TRUE)

  # file to store the times
  txt_file <- file.path(project_path, "tests", "cypress", "performance.txt")
  add_sendtime2js(js_file = js_file, txt_file = txt_file)

  # returning the file location
  return(list(js_file = js_file, txt_file = txt_file))
}

#' @title Add the sendTime function to the .js file
#'
#' @param js_file Path to the .js file to add code
#' @param txt_file Path to the file to record the execution times
add_sendtime2js <- function(js_file, txt_file) {
  lines_to_add <- glue(
    "
  // Returning the time for each test
  // https://www.cypress.io/blog/2020/05/22/where-does-the-test-spend-its-time/
  let commands = []
  let performanceAttrs
  Cypress.on('test:before:run', () => {
    commands.length = 0
  })
  Cypress.on('test:after:run', (attributes) => {
    performanceAttrs = {
      title: attributes.title,
      duration: attributes.duration,
      commands: Cypress._.cloneDeep(commands),
    }
  })
  const sendTestTimings = () => {
    if (!performanceAttrs) {
      return
    }
    const attr = performanceAttrs
    attr.fileOut = '{{txt_file}}'
    performanceAttrs = null
    cy.task('performanceTimes', attr)
  }
  // Calling the sendTestTimings function
  beforeEach(sendTestTimings)
  after(sendTestTimings)
  ",
    .open = "{{", .close = "}}"
  )

  write(x = lines_to_add, file = js_file, append = TRUE)
}

#' @title Get the commit date in POSIXct format
#'
#' @param branch Commit hash code or branch name
#' @importFrom glue glue
get_commit_date <- function(branch) {
  date <- system(
    glue("git show -s --format=%ci {branch}"),
    intern = TRUE
  )
  date <- as.POSIXct(date[1])

  return(date)
}

#' @title Find the hash code of the current commit
#' @importFrom glue glue
#' @importFrom stringr str_trim
get_commit_hash <- function() {
  hash <- system("git show -s --format=%H", intern = TRUE)[1]
  branch <- system(
    glue("git branch --contains {hash}"),
    intern = TRUE
  )

  branch <- str_trim(
    string = gsub(x = branch[length(branch)], pattern = "\\*\\s", replacement = ""),
    side = "both"
  )

  hash_head <- system(
    glue("git rev-parse {branch}"),
    intern = TRUE
  )

  is_head <- hash == hash_head

  if (is_head) hash <- branch

  return(hash)
}

#' @title Checkout GitHub files
#'
#' @description Checkout anything created by the app. It prevents errors when
#' changing branches
checkout_files <- function() {
  system("git checkout .")
}

#' @title Check and restore renv
#'
#' @description Check whether renv is in use in the current branch. Raise error
#' if renv is not in use or apply renv:restore() in the case the package is
#' present
#'
#' @param branch Commit hash code or branch name. Useful to create an
#' informative error message
#' @importFrom glue glue
#' @importFrom renv activate restore
restore_env <- function(branch) {
  # handling renv
  tryCatch(
    expr = {
      activate()
      restore()
    },
    error = function(e) {
      stop(glue("Unexpected error activating renv in branch {branch}: {e}\n"))
    }
  )
}
