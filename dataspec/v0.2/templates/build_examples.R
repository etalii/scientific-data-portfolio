# Generate sanitized 0.2 authoring examples from fictional regression assets.
# Run from repository root. These are NOT human approval or scientific evidence.
source('dataspec/v0.2/tests/helpers.R')
root <- 'dataspec'
b <- fixture_v02(root)
# Example paths share the DataSpec root; original 0.1 fixture assets stay intact.
example_paths <- function(x) {
 if(!is.list(x))return(x)
 if(!is.null(x$path)&&!is.null(x$availability))x$path<-file.path('tests/fixtures/minimal',x$path)
 lapply(x,example_paths)
}
b <- example_paths(b)
for(name in c('visual','nonvisual','prospective')) {
 value <- switch(name,visual=b,nonvisual=nonvisual(b),prospective=native(b,root,'v0.2/templates/registration_v1.json'))
 writeLines(jsonlite::toJSON(value,auto_unbox=TRUE,null='null',pretty=TRUE,digits=NA),
   file.path('dataspec/v0.2/templates',paste0(name,'.json')))
}
