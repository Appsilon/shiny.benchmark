#!/bin/sh

# starting
git init

# STANDARD FUNCTIONALITIES
## master
git add .
git commit -m "first commit"

## develop
git checkout -b develop
git commit --allow-empty -m "dummy commit to change hash"

# RENV FUNCTIONALITIES
## No renv at all
git branch renv_missing master
git checkout renv_missing
git commit --allow-empty -m "dummy commit to change hash"

## Creating renv
git branch renv_shiny1 master
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
