#' @title Create a temporary directory to store everything needed by Cypress
#'
#' @param app_dir The path to the application root
#' @param port Port to run the app
#' @param debug Logical. TRUE to display all the system messages on runtime
#'
#' @importFrom jsonlite write_json
#'
#' @keywords internal
create_cypress_structure <- function(app_dir, port, debug) {
  # temp dir to run the tests
  dir_tests <- tempdir()

  # node path
  node_path <- fs::path(dir_tests, "node")
  root_path <- fs::path(node_path, "root") # nolint

  # test path
  tests_path <- fs::path(dir_tests, "tests")
  cypress_path <- fs::path(tests_path, "cypress")
  integration_path <- fs::path(cypress_path, "integration")
  plugins_path <- fs::path(cypress_path, "plugins")

  # creating paths
  fs::dir_create(path = node_path)
  fs::dir_create(path = tests_path)
  fs::dir_create(path = cypress_path)
  fs::dir_create(path = integration_path)
  fs::dir_create(path = plugins_path)

  # create a path root linked to the main directory app
  tryCatch(
    expr = {
      fs::link_create(app_dir, root_path, symbolic = TRUE)
    },
    error = function(e) {

      choice <- menu(
        choices = c("Yes", "No"),
        title = glue(
          "A symbolic link cannot be created, it is possible to clone ",
          "the repository, but it can take some time and space on disk. ",
          "Would you like to proceed with this operations?")
      )

      if (choice == 2)
        stop("Process aborted by user.")

      # If system cannot symlink then try to clone the repository
      #  This may happen on some windows versions
      #  This can be an expensive operation on big repositories
      message(
        "Could not create symbolic link with fs package, ",
        "trying with git clone..."
      )
      system(glue::glue("git clone \"{app_dir}\" \"{root_path}\""))
      system("git submodule init")
      system("git submodule update ")
    })

  # create the packages.json file
  json_txt <- create_node_list(tests_path = tests_path, port = port)
  json_file <- fs::path(node_path, "package.json")
  write_json(x = json_txt, path = json_file, pretty = TRUE, auto_unbox = TRUE)

  # install everything that is needed
  install_deps <- glue("yarn --cwd {node_path}")
  system(install_deps, ignore.stdout = !debug, ignore.stderr = !debug)

  # creating cypress plugin file
  js_txt <- create_cypress_plugins()
  js_file <- fs::path(plugins_path, "index.js")
  writeLines(text = js_txt, con = js_file)

  # creating cypress.json
  json_txt <- create_cypress_list(plugins_file = js_file, port = port)
  json_file <- fs::path(tests_path, "cypress.json")
  write_json(x = json_txt, path = json_file, pretty = TRUE, auto_unbox = TRUE)

  # returning the project folder
  message(glue("Structure created at {dir_tests}"))
  return(dir_tests)
}

#' @title Create the list of needed libraries
#'
#' @param tests_path The path to project
#' @param port Port to run the app
#'
#' @keywords internal
create_node_list <- function(tests_path, port) {
  json_list <- list(
    private = TRUE,
    scripts = list(
      "performance-test" = glue(
        "start-server-and-test run-app http://localhost:{port} run-cypress"
      ),
      "run-app" = glue(
        "cd root && ",
        "Rscript -e \"shiny::runApp(port = {port})\""
      ),
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
#' @param port Port to run the app
#'
#' @keywords internal
create_cypress_list <- function(plugins_file, port) {
  json_list <- list(
    baseUrl = glue("http://localhost:{port}"),
    pluginsFile = plugins_file,
    supportFile = FALSE
  )

  return(json_list)
}

#' @title Create the JS code to track execution time
#'
#' @keywords internal
create_cypress_plugins <- function() {
  js_txt <- "
  const fs = require('fs')
  module.exports = (on, config) => {
    on('task', {
      performanceTimes (attributes) {
        fs.writeFile(
          attributes.fileOut,
          `${ attributes.title }; ${ attributes.duration }\n`,
          { flag: 'a' }
        )
        return null
      }
    })
  }"

  return(js_txt)
}

#' @title Create the cypress files under project directory
#'
#' @param project_path The path to the project with all needed packages
#' installed
#' @param cypress_dir The directory with tests recorded by Cypress
#' @param tests_pattern Cypress files pattern. E.g. 'performance'. If it is NULL,
#' all the content will be used
#'
#' @keywords internal
create_cypress_tests <- function(project_path, cypress_dir, tests_pattern) {
  # locate files
  cypress_files <- list.files(
    path = cypress_dir,
    pattern = tests_pattern,
    full.names = TRUE,
    recursive = TRUE
  )
  cypress_files <- grep(x = cypress_files, pattern = "\\.js$", value = TRUE)

  # creating a copy to be able to edit the js file
  js_file <- fs::path(
    project_path,
    "tests",
    "cypress",
    "integration",
    "app.spec.js"
  )

  # combine all files into one
  for (i in seq_along(cypress_files)) {
    text <- readLines(con = cypress_files[i])
    write(x = text, file = js_file, append = TRUE)
  }

  # file to store the times
  txt_file <- fs::path(project_path, "tests", "cypress", "performance.txt")

  add_sendtime2js(js_file = js_file, txt_file = txt_file)

  # returning the file location
  return(list(js_file = js_file, txt_file = txt_file))
}

#' @title Add the sendTime function to the .js file
#'
#' @param js_file Path to the .js file to add code
#' @param txt_file Path to the file to record the execution times
#'
#' @keywords internal
add_sendtime2js <- function(js_file, txt_file) {
  lines_to_add <- glue(
    "
  describe('Finalizing tests', () => {it('Ending tests', () => {})})

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
  ",
    .open = "{{", .close = "}}"
  )

  write(x = lines_to_add, file = js_file, append = TRUE)
}
