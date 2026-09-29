# Build the versioned envelope schema from the preserved 0.1 typed record model.
# Run from portfolio root; output is an authored, version-controlled core schema.
s <- jsonlite::fromJSON('dataspec/schemas/bundle.schema.json',simplifyVector=FALSE)
s$`$id` <- 'https://dataspec.local/schemas/0.2.0/bundle.schema.json'
s$title <- 'DataSpec 0.2.0 bundle'
# Change only explicit schema version constants, not domain data or examples.
version <- function(x) {
 if(!is.list(x)) return(x)
 if(!is.null(x$const) && identical(x$const,'0.1.0')) x$const <- '0.2.0'
 lapply(x,version)
}
s <- version(s)
# Typed schema constructors keep the extension declarative and closed.
obj <- function(properties, required=names(properties)) list(type='object',properties=properties,required=as.list(required),additionalProperties=FALSE)
str <- list(type='string',minLength=1)
arr <- function(items) list(type='array',items=items)
enum <- function(values) list(enum=as.list(values))
ref <- function(name) list('$ref'=paste0('#/$defs/',name))
nullable <- function(x) list(oneOf=list(x,list(type='null')))
time <- list(type='string',pattern='^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$')
review_dimensions <- c('scientific','narrative','visual','reproducibility')
s$properties$governance <- obj(list(
 adoption=obj(list(mode=enum(c('retrospective','in_place','native')),cutover_at=nullable(time),history_refs=arr(ref('external')))),
 visualization=obj(list(decision=enum(c('required','not_required','undecided')),rationale=str,spec_refs=arr(ref('internal')),narrative_ref=nullable(ref('internal')),decision_ref=nullable(ref('external')),review_refs=arr(ref('internal')))),
 review_items=arr(obj(list(requirement_id=str,group_id=str,target_ref=ref('internal'),dimension=enum(review_dimensions),disposition=enum(c('ACCEPT','ACCEPT WITH EDIT','REJECT','NEEDS INVESTIGATION')),review_ref=nullable(ref('internal')),source_ref=ref('external'),previous_ref=nullable(ref('external')),edit_ref=nullable(ref('external'))))),
 reproducibility=obj(list(dimensions=arr(obj(list(dimension=enum(c('input_identity','environment_identity','commands','results','rendered_artifacts','clean_clone','cross_platform')),status=enum(c('demonstrated','partial','not_demonstrated','not_applicable')),scope=str,evidence_refs=arr(ref('external'))))),dependencies=arr(obj(list(name=str,availability=enum(c('version_controlled','local_only','external','unavailable')),reference=ref('external')))))),
 registration=nullable(obj(list(revision=list(type='integer',minimum=1),snapshot_ref=ref('external'),previous_ref=nullable(ref('external')),question_ref=ref('internal'),plan_ref=ref('internal'),contract_refs=arr(ref('internal')),input_refs=arr(ref('external')),criteria=arr(str),registered_at=time,attestation=list(const='workspace'),record_hashes=arr(obj(list(record_ref=ref('internal'),sha256=list(type='string',pattern='^[0-9a-f]{64}$')))),gate_checks=arr(obj(list(criterion=enum(c('question_defined','inputs_fixed','provenance_sufficient','semantics_documented','method_specified','failure_conditions_defined')),passed=list(type='boolean'),rationale=str))))))
))
s$required <- c(s$required,list('governance'))
writeLines(jsonlite::toJSON(s,auto_unbox=TRUE,pretty=TRUE,null='null'), 'dataspec/v0.2/schemas/bundle.schema.json')
