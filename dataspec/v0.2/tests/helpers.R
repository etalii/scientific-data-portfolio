# Synthetic 0.2 fixture builders; never operate on scientific project artifacts.
source('dataspec/v0.2/validators/core.R')
e <- load_legacy('dataspec')
# Locate a record by its stable local artifact ID.
idx <- function(b,id) which(vapply(b$records,function(x)x$artifact_id==id,logical(1)))
# Build exact references without relying on conversation state.
iref <- function(id,revision=1L) list(project_id='synthetic',artifact_id=id,revision=revision)
# Write deterministic fixture bytes and return a contained external reference.
fixture_file <- function(root,name,value,json=FALSE) {
 path<-file.path(root,name);dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
 if(json)writeLines(jsonlite::toJSON(value,auto_unbox=TRUE,null='null',pretty=TRUE,digits=NA),path)else writeLines(value,path)
 list(path=name,sha256=digest::digest(file=path,algo='sha256'),locator='Synthetic fixture',availability='verified_local')
}
# Rebuild selected identities and the exact delivery closure after fixture edits.
relink <- function(b) {
 b$records<-b$records[order(vapply(b$records,e$ref_key,''),method='radix')]
 b$candidate_refs<-lapply(b$records,function(r)r[c('project_id','artifact_id','revision')])
 graph<-setNames(lapply(b$records,function(r){p<-r$payload;p$dependency_snapshot<-NULL;vapply(e$collect_refs(list(p,r$depends_on),'internal'),function(x)e$ref_key(x$value),'')}),vapply(b$records,e$ref_key,''))
 for(i in seq_along(b$records))if(b$records[[i]]$kind=='delivery') {
  keys<-e$dependency_closure(e$ref_key(b$records[[i]]),graph)
  b$records[[i]]$payload$dependency_snapshot<-lapply(keys,function(k)b$records[[match(k,names(graph))]][c('project_id','artifact_id','revision')])
 }
 b
}
# Remove a fixture artifact and all its references, preserving other graph edges.
remove_artifact <- function(b,id) {
 walk<-function(x){if(!is.list(x))return(x);if(is.null(names(x)))x<-Filter(function(z)!(is.list(z)&&!is.null(z$artifact_id)&&z$artifact_id==id),x);lapply(x,walk)}
 relink(walk(b))
}
# Create a retrospective visual delivery with explicit grouped synthetic reviews.
fixture_v02 <- function(root) {
 b<-e$read_json_strict('dataspec/tests/fixtures/minimal/bundle.json')
 b$schema_version<-'0.2.0'
 b$records<-lapply(b$records,function(r){r$schema_version<-'0.2.0';if(r$kind%in%c('question','analysis_plan'))r$record_origin<-'retrospective';r})
 check<-b$records[[idx(b,'review')]]$payload$checks[[1]]$evidence_refs[[1]]
 closure<-b$records[[idx(b,'review')]];closure$artifact_id<-'review_closure';closure$payload$target_refs<-list(iref('delivery'));closure$payload$review_dimensions<-list('scientific')
 b$records<-c(b$records,list(closure))
 items<-list()
 for(id in c('claim','narrative','visual','delivery'))for(d in switch(id,claim='scientific',narrative=c('narrative','reproducibility'),visual=c('visual','reproducibility'),delivery='scientific')) {
  items[[length(items)+1L]]<-list(requirement_id=paste(id,d,sep='_'),group_id='human_group',target_ref=iref(id),dimension=d,disposition='ACCEPT',review_ref=iref(if(id=='delivery')'review_closure'else'review'),source_ref=check,previous_ref=NULL,edit_ref=NULL)
 }
 b$governance<-list(adoption=list(mode='retrospective',cutover_at=NULL,history_refs=list(check)),
  visualization=list(decision='required',rationale='Synthetic representation has analytical purpose.',spec_refs=list(iref('visual')),narrative_ref=iref('narrative'),decision_ref=check,review_refs=list(iref('review'))),
  review_items=items,reproducibility=list(dimensions=list(list(dimension='commands',status='demonstrated',scope='Synthetic local command only',evidence_refs=list(check)),list(dimension='clean_clone',status='not_demonstrated',scope='Local dependencies required',evidence_refs=list())),dependencies=list(list(name='local input',availability='local_only',reference=b$records[[idx(b,'execution')]]$payload$input_refs[[1]]))),registration=NULL)
 relink(b)
}
# Change only the explicit visualization branch and references.
nonvisual <- function(b) {
 b<-remove_artifact(b,'visual');b$governance$review_items<-Filter(function(x)x$target_ref$artifact_id!='visual',b$governance$review_items)
 b$governance$visualization$decision<-'not_required';b
}
# Add a workspace registration with exact question/plan/contract bytes.
native <- function(b, fixture_root=root, snapshot_path='assets/registration_v1.json') {
 b$governance$adoption<-list(mode='native',cutover_at=NULL,history_refs=list())
 b$records<-lapply(b$records,function(r){r$record_origin<-'prospective';r})
 for(i in seq_along(b$records))if(b$records[[i]]$kind%in%c('question','analysis_plan','data_contract_ref')) {
  b$records[[i]]$record_origin<-'prospective';b$records[[i]]$created_at<-'2026-01-01T00:00:00Z'
 }
 fixed<-list(iref('question'),iref('plan'),iref('contract'))
 g<-list(question_ref=iref('question'),plan_ref=iref('plan'),contract_refs=list(iref('contract')),
 input_refs=b$records[[idx(b,'execution')]]$payload$input_refs,criteria=list('Diagnostic compatibility only'),registered_at='2026-01-01T12:00:00Z',attestation='workspace',
 record_hashes=lapply(fixed,function(ref)list(record_ref=ref,sha256=digest::digest(e$canonical_json(b$records[[idx(b,ref$artifact_id)]]),algo='sha256',serialize=FALSE))),
 gate_checks=lapply(c('question_defined','inputs_fixed','provenance_sufficient','semantics_documented','method_specified','failure_conditions_defined'),function(id)list(criterion=id,passed=TRUE,rationale='Synthetic declared criterion')))
 g$revision<-1L;g['previous_ref']<-list(NULL)
 b$governance$registration<-g
 freeze_registration(b,fixture_root,snapshot_path)
}

# Preserve complete registration bytes and bind each current execution to them.
# Call only when authoring a new registration/execution, never when validating.
freeze_registration <- function(b,fixture_root,path) {
 g<-b$governance$registration;old<-g$snapshot_ref;g$snapshot_ref<-NULL
 ref<-fixture_file(fixture_root,path,g,TRUE)
 b$governance$registration$snapshot_ref<-ref
 for(i in seq_along(b$records))if(b$records[[i]]$kind=='execution') {
  configs<-b$records[[i]]$payload$config_refs
  if(!is.null(old))configs<-Filter(function(x)!identical(x$path,old$path),configs)
  configs<-c(configs,list(ref))
  b$records[[i]]$payload$config_refs<-configs[order(vapply(configs,function(x)paste(x$path,x$sha256,x$locator),''),method='radix')]
 }
 b
}
