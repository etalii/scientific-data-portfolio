###############################################################
# Argentina Dengue Analysis
#
# Script:
#   check_environment.R
#
# Purpose:
#   Verify that the project environment is correctly configured
#   before running the data pipeline.
###############################################################

cat("\n")
cat("=========================================\n")
cat(" Argentina Dengue Analysis\n")
cat(" Environment Check\n")
cat("=========================================\n\n")

#--------------------------------------------------------------
# Helper function
#--------------------------------------------------------------

check_file <- function(path) {
  if (file.exists(path)) {
    cat(sprintf("[OK] File found: %s\n", path))
    return(TRUE)
  } else {
    cat(sprintf("[ERROR] Missing file: %s\n", path))
    return(FALSE)
  }
}

check_dir <- function(path) {
  if (dir.exists(path)) {
    cat(sprintf("[OK] Directory found: %s\n", path))
    return(TRUE)
  } else {
    cat(sprintf("[ERROR] Missing directory: %s\n", path))
    return(FALSE)
  }
}

check_package <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("[OK] Package available: %s\n", pkg))
    return(TRUE)
  } else {
    cat(sprintf("[ERROR] Package missing: %s\n", pkg))
    return(FALSE)
  }
}

#--------------------------------------------------------------
# Files
#--------------------------------------------------------------

cat("Checking configuration...\n\n")

results <- c()

results <- c(results, check_file("config/project.yml"))
results <- c(results, check_file("DESCRIPTION"))
results <- c(results, check_file("README.md"))
results <- c(results, check_file(".Rprofile"))
results <- c(results, check_file("renv.lock"))

#--------------------------------------------------------------
# Directories
#--------------------------------------------------------------

cat("\nChecking project structure...\n\n")

dirs <- c(
  "config",
  "data",
  "data/raw",
  "data/processed",
  "data/metadata",
  "docs",
  "scripts",
  "reports",
  "figures",
  "outputs",
  "references"
)

for (d in dirs)
  results <- c(results, check_dir(d))

#--------------------------------------------------------------
# Packages
#--------------------------------------------------------------

cat("\nChecking R packages...\n\n")

packages <- c(
  "yaml",
  "httr2",
  "jsonlite",
  "dplyr",
  "readr",
  "stringr",
  "purrr",
  "janitor",
  "lubridate",
  "tibble"
)

for (pkg in packages)
  results <- c(results, check_package(pkg))

#--------------------------------------------------------------
# renv
#--------------------------------------------------------------

cat("\nChecking renv...\n\n")

if (requireNamespace("renv", quietly = TRUE)) {
  cat("[OK] renv installed\n")
} else {
  cat("[ERROR] renv is not installed\n")
  results <- c(results, FALSE)
}

#--------------------------------------------------------------
# Summary
#--------------------------------------------------------------

cat("\n=========================================\n")

if (all(results)) {

  cat(" Environment ready.\n")

  cat("=========================================\n")

} else {

  cat(" Some checks failed.\n")

  cat(" Please fix the reported issues.\n")

  cat("=========================================\n")

  quit(status = 1)

}
