# DataSpec command-line validator.
# Inputs: JSON bundle path and project root. Output: JSON on stdout; no writes.
# Exit 0: passed linkage checks; 1: validation failure; 2: invocation/runtime error.

arguments <- commandArgs(trailingOnly = TRUE)
script_argument <- grep("^--file=", commandArgs(), value = TRUE)
script_path <- normalizePath(sub("^--file=", "", script_argument[[1]]), mustWork = TRUE)
source(file.path(dirname(script_path), "core.R"))
exit_code <- tryCatch({
  if (length(arguments) != 2L) stop("Usage: Rscript validate.R BUNDLE PROJECT_ROOT")
  result <- validate_bundle(read_json_strict(arguments[[1]]), arguments[[2]],
    file.path(dirname(script_path), "..", "schemas", "bundle.schema.json"))
  cat(jsonlite::toJSON(result, auto_unbox = TRUE, null = "null", pretty = TRUE), "\n", sep = "")
  if (result$valid) 0L else 1L
}, error = function(error) {
  message("DataSpec runtime error: ", conditionMessage(error))
  2L
})
quit(status = exit_code)
