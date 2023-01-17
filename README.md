# shiny.benchmark <a href="https://appsilon.github.io/shiny.benchmark/"><img src="man/figures/shiny_benchmark.png" align="right" alt="shiny.benchmark logo" style="height: 140px;"></a>

> _Tools to measure performance improvements in shiny apps._

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/shiny.benchmark)](https://cran.r-project.org/package=shiny.benchmark)
[![R-CMD-check](https://github.com/Appsilon/shiny.benchmark/workflows/R-CMD-check/badge.svg)](https://github.com/Appsilon/shiny.benchmark/actions?workflow=R-CMD-check)
<!-- badges: end -->

`shiny.benchmark` is a tool aimed to measure and compare the performance of different versions of a `shiny` application. Based on a list of different application versions, accessible by a git repo by its refs (commit hash or branch name), the user can write instructions to be executed using Cypress or `shinytest2`. These instructions are then evaluated by the different versions of your `shiny` application and therefore the performance's improvement/deterioration (time elapsed) are be recorded.

The package is flexible enough to allow different sets of tests for the different refs as well as different package versions (via `renv`). Also, the user can replicate the tests to have more accurate measures of performance.

## How to install?

```r
remotes::install_github("Appsilon/shiny.benchmark")
```

## Dependencies

`shiny.benchmark` can use two different engines to test the change in the performance of your application: [shinytest2](https://rstudio.github.io/shinytest2/) and [Cypress](https://www.cypress.io/).
The latter requires `Node` (version 12 or higher) and `yarn` (version 1.22.17 or higher) to be available.
To install them on your computer, follow the guidelines on the documentation pages:

- [Node](https://nodejs.org/en/download/)
- [yarn](https://yarnpkg.com/getting-started/install)

Besides that, on Linux, it might be required to install other `Cypress` dependencies.
Check the [documentation](https://docs.cypress.io/guides/getting-started/installing-cypress#Linux-Prerequisites) to find out more.

## How to use it?

The best way to start using `shiny.benchmark` is through an example. If you want a start point, you can use the `load_example` function. In order to use this, create a new folder in your computer and use the following code to generate an application to serve us as example for our performance checks:

```r
library(shiny.benchmark)

load_example(path = "path/to/new/project")
```

It will create some useful files under `path/to/new/project`. The most important one is the `run_tests.R` which provides several instructions at the very top.

As we are comparing versions of the same application, we need different app versions in different branches/commits in `git`. Start using `cd app; git init` to initiate git inside `app/` folder.

Get familiar with `app/server.R` file in order to generate more interesting scenarios. The basic idea is to use the `Sys.sleep` function to simulate some app's functionalities. Remember that, when running the benchmark, that is the amount of time it will take to measure the performance.

When you are ready, commit your changes in master/main using `git add .; git commit -m "your commit message"`. Make some editions and commit these new changes into a new branch or in the same branch your are testing (it will have a different commit hash). Repeat the process adding as many new modifications as you want. E.g. add renv, add more tests, change the names of the tests/test files and so on.

Here is a complete example on how to setup your `git`:

```git
# starting
git init
echo .Rproj.user >> .gitignore
echo *.Rproj >> .gitignore
echo .Rprofile >> .gitignore
echo renv >> .gitignore
echo .Rprofile >> .gitignore

# master
git add .
git commit -m "first commit"

# develop (decrease Sys.sleep times in server.R)
git checkout -b develop
git add .
git commit -m "improving performance"

## Using renv
git branch renv_shiny1 develop
git checkout renv_shiny1
R -e 'renv::init()'
git add .
git commit -m "renv active"

## Downgrading shiny
git checkout -b renv_shiny2
R -e 'renv::install("shiny@1.7.0")'
R -e 'renv::snapshot()'
git add .
git commit -m "downgrading shiny"

## Switching back to develop
git checkout develop
```

Now you are ready to go. The `benchmark` function provides several arguments to make your life easier when running your performance checks. The mandatory arguments are:

- `commit_list`: A vector with commits, branches or anything else you can use in `git checkout`
- `cypress_dir` or `shinytest2_dir`: Folder containing the tests we want to check the performance. In our case it is `tests/cypress` and `tests` respectively.

The default behavior is to try to use `renv` in your project. If you do not have the renv structure, you can turn `renv` off using `use_renv = FALSE`

```r
library(shiny.benchmark)

# commits to compare
commit_list <- c("develop", "renv_shiny1", "renv_shiny2")

# run performance check using Cypress
benchmark(
  commit_list = commit_list,
  cypress_dir = "tests/cypress"
)
```

That is all you need to run your `Cypress` tests. If you don't use `Cypress`, you may want to use `shinytest2` instead:

```r
benchmark(
  commit_list = commit_list,
  shinytest2_dir = "tests"
)
```

To run just specific tests, you can take advantage of the `tests_pattern` argument. It will filter the test file's names based on regular expression:

```r
benchmark(
  commit_list = commit_list,
  shinytest2_dir = "tests",
  tests_pattern = "use_this_one_[0-9]"
)
```

If your project has `renv` structure, you can set `use_renv` to `TRUE` to guarantee that, for each application version your are using the correct packages. If you want to approve/reprove `renv::restore()`, you can set `renv_prompt = TRUE`.

```r
benchmark(
  commit_list = commit_list,
  shinytest2_dir = "tests",
  tests_pattern = "use_this_one_[0-9]",
  use_renv = TRUE, # default
  renv_prompt = TRUE
)
```

To have more accurate information about the time your application takes to perform some actions, you may need to replicate the tests. In this case, you can use the `n_rep` argument:

```r
out <- benchmark(
  commit_list = commit_list,
  cypress_dir = "tests/cypress",
  tests_pattern = "use_this_one_[0-9]",
  use_renv = FALSE,
  n_rep = 15
)

out
```

For fast information about the tests results, you can use the `summary` and also the `plot` methods:

```r
summary(out)
plot(out)
```

## How to contribute?

If you want to contribute to this project please submit a regular PR, once you're done with new feature or bug fix.

Reporting a bug is also helpful - please use [GitHub issues](https://github.com/Appsilon/shiny.benchmark/issues) and describe your problem as detailed as possible.

## Appsilon

<img src="https://avatars0.githubusercontent.com/u/6096772" align="right" alt="" width="6%" />

Appsilon is a **Posit (formerly RStudio) Full Service Certified Partner**. Learn more
at [appsilon.com](https://appsilon.com).

Get in touch [opensource@appsilon.com](mailto:opensource@appsilon.com)

<a href = "https://appsilon.com/careers/" target="_blank"><img src="http://d2v95fjda94ghc.cloudfront.net/hiring.png" alt="We are hiring!"/></a>
