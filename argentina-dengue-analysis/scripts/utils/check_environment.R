###############################################################
# Argentina Dengue Analysis
#
# Script:
#   check_environment.R
#
# Purpose:
#   Validate that the project environment is correctly configured
#   before running the data pipeline.
###############################################################

cat("\n=========================================\n")
cat(" Argentina Dengue Analysis\n")
cat(" Environment Check\n")
cat("=========================================\n\n")

# ------------------------------------------------------------
# Report
# ------------------------------------------------------------

report_lines <- character()

log_report <- function(text) {
  report_lines <<- c(report_lines, text)
}

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

check_file <- function(path) {

  ok <- file.exists(path)

  msg <- if (ok)
    sprintf("[OK] File: %s", path)
  else
    sprintf("[ERROR] Missing file: %s", path)

  cat(msg, "\n")

  log_report(msg)

  ok

}

check_dir <- function(path) {

  ok <- dir.exists(path)

  msg <- if (ok)
    sprintf("[OK] Directory: %s", path)
  else
    sprintf("[ERROR] Missing directory: %s", path)

  cat(msg, "\n")

  log_report(msg)

  ok

}

check_package <- function(pkg) {

  ok <- requireNamespace(pkg, quietly = TRUE)

  msg <- if (ok)
    sprintf("[OK] Package: %s", pkg)
  else
    sprintf("[ERROR] Package missing: %s", pkg)

  cat(msg, "\n")

  log_report(msg)

  ok

}

# ------------------------------------------------------------
# System information
# ------------------------------------------------------------

log_report("----------------------------------------")
log_report("Environment Report")
log_report("----------------------------------------")

log_report(paste("Generated:", Sys.time()))
log_report(paste("R:", R.version.string))
log_report(paste("Platform:", R.version$platform))
log_report(
  paste(
    "OS:",
    Sys.info()[["sysname"]],
    Sys.info()[["release"]]
  )
)

# ------------------------------------------------------------
# Files
# ------------------------------------------------------------

cat("\nChecking configuration files...\n\n")

results <- logical()

files <- c(
  "config/project.yml",
  "DESCRIPTION",
  "README.md",
  ".Rprofile",
  "renv.lock"
)

for (f in files) {

  results <- c(results, check_file(f))

}

# ------------------------------------------------------------
# Directories
# ------------------------------------------------------------

cat("\nChecking directory structure...\n\n")

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

for (d in dirs) {

  results <- c(results, check_dir(d))

}

# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

cat("\nChecking packages...\n\n")

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
  "tibble",
  "cli",
  "glue",
  "fs"
)

for (pkg in packages) {

  results <- c(results, check_package(pkg))

}

# ------------------------------------------------------------
# Package versions
# ------------------------------------------------------------

log_report("")
log_report("Installed package versions")

for (pkg in packages) {

  if (requireNamespace(pkg, quietly = TRUE)) {

    log_report(
      paste(
        pkg,
        as.character(packageVersion(pkg))
      )
    )

  }

}

# ------------------------------------------------------------
# renv
# ------------------------------------------------------------

cat("\nChecking renv...\n\n")

renv_ok <- requireNamespace("renv", quietly = TRUE)

if (renv_ok) {

  cat("[OK] renv installed\n")

  log_report("[OK] renv installed")

} else {

  cat("[ERROR] renv not installed\n")

  log_report("[ERROR] renv not installed")

}

results <- c(results, renv_ok)

# ------------------------------------------------------------
# Write report
# ------------------------------------------------------------

dir.create(
  "outputs",
  showWarnings = FALSE
)

writeLines(
  report_lines,
  "outputs/environment_report.txt"
)

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

cat("\n=========================================\n")

if (all(results)) {

  cat("Environment ready.\n")

  cat("Report written to:\n")

  cat("outputs/environment_report.txt\n")

  cat("=========================================\n")

} else {

  cat("Some checks failed.\n")

  cat("See outputs/environment_report.txt\n")

  cat("=========================================\n")

  quit(status = 1)

}
