# Dual-version DataSpec CLI: validate BUNDLE PROJECT_ROOT; no filesystem writes.
args <- commandArgs(TRUE)
file_arg <- grep('^--file=',commandArgs(),value=TRUE)[[1]]
script <- normalizePath(sub('^--file=','',file_arg),mustWork=TRUE)
core_root <- normalizePath(file.path(dirname(script),'../..'),mustWork=TRUE)
source(file.path(dirname(script),'core.R'))
exit <- tryCatch({
  if(length(args)!=2L) stop('Usage: Rscript validate.R BUNDLE PROJECT_ROOT')
  engine <- load_legacy(core_root)
  result <- validate_dataspec(engine$read_json_strict(args[[1]]),args[[2]],core_root)
  cat(jsonlite::toJSON(result,auto_unbox=TRUE,null='null',pretty=TRUE),'\n')
  if(result$valid)0L else 1L
},error=function(e){message(conditionMessage(e));2L})
quit(status=exit)
