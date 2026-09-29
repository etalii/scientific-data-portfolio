# Read-only compatibility audit and transient climate delivery interpretation.
# No pilot migration, human review fabrication, raw processing or project writes.
source('dataspec/v0.2/validators/core.R')
e<-load_legacy('dataspec')
roots<-c(dengue='argentina-dengue-analysis',climate='climate-biodiversity-vulnerability-argentina')
paths<-c(dengue='data/metadata/dataspec_rank_closure_v1/bundle.json',climate='data/metadata/dataspec_pair_closure_v1/bundle.json')
for(name in names(roots)) {
 root<-roots[[name]];path<-file.path(root,paths[[name]])
 before<-digest::digest(file=path,algo='sha256')
 b<-e$read_json_strict(path)
 old<-e$validate_bundle(b,root,'dataspec/schemas/bundle.schema.json')
 current<-validate_dataspec(b,root)
 stopifnot(old$valid,current$valid,identical(old,current),length(current$findings)==0L,digest::digest(file=path,algo='sha256')==before)
 cat('PASS',name,'historical 0.1: identical report;',length(current$records),'records; zero findings\n')
}
root<-roots[['climate']]
b<-e$read_json_strict(file.path(root,paths[['climate']]))
# References address existing artifacts only; derived view is not a new attestation.
ext<-function(path,locator)list(path=path,sha256=digest::digest(file=file.path(root,path),algo='sha256'),locator=locator,availability='verified_local')
record<-function(id)Filter(function(x)x$artifact_id==id,b$records)[[1]]
ref<-function(id)record(id)[c('project_id','artifact_id','revision')]
original<-e$read_json_strict(file.path(root,'data/metadata/dataspec_pair_pilot_v1/bundle.json'))
registration<-e$read_json_strict(file.path(root,'dataspec/studies/bio01_pair_eligibility/registration/registration.json'))
acceptance<-e$read_json_strict(file.path(root,'data/metadata/dataspec_pair_closure_v1/acceptance.json'))
b$schema_version<-'0.2.0';b$records<-lapply(b$records,function(x){x$schema_version<-'0.2.0';x})
source_ref<-acceptance$request_ref
report_ref<-ext('data/metadata/dataspec_pair_closure_v1/report.md','Accepted narrative and nonvisual rationale')
history_ref<-ext('data/metadata/dataspec_pair_pilot_v1/bundle.json','Preserved original revisions')
items<-list()
for(decision in acceptance$dispositions)for(id in unlist(decision$targets))for(d in unlist(decision$dimensions)) {
 items[[length(items)+1L]]<-list(requirement_id=paste(id,d,sep='_'),group_id=decision$id,target_ref=ref(id),dimension=d,disposition=decision$disposition,
 review_ref=ref(paste0('review_human_',tolower(decision$id))),source_ref=source_ref,
 previous_ref=if(decision$disposition=='ACCEPT WITH EDIT'&&id!='claim_direct_suitability')history_ref else NULL,
 edit_ref=if(decision$disposition=='ACCEPT WITH EDIT'&&id!='claim_direct_suitability')report_ref else NULL)
 # Exclusion was retained without an edit to the unsupported candidate itself.
 if(id=='claim_direct_suitability')items[[length(items)]]$disposition<-'ACCEPT'
}
contracts<-record('plan')$payload$contract_refs
fixed<-c(list(ref('question'),ref('plan')),contracts)
reg<-list(revision=1L,previous_ref=NULL,question_ref=ref('question'),plan_ref=ref('plan'),contract_refs=contracts,input_refs=registration$inputs,criteria=list('Documentary eligibility only; no new raster values'),registered_at=registration$registered_at,attestation='workspace',
 record_hashes=lapply(fixed,function(r)list(record_ref=r,sha256=digest::digest(e$canonical_json(record(r$artifact_id)),algo='sha256',serialize=FALSE))),
 gate_checks=lapply(c('question_defined','inputs_fixed','provenance_sufficient','semantics_documented','method_specified','failure_conditions_defined'),function(x)list(criterion=x,passed=TRUE,rationale='Interpretation of preserved original registration gate')))
# Original contract records are imported, while question/plan are prospective.
b$governance<-list(adoption=list(mode='native',cutover_at=NULL,history_refs=list(ext('dataspec/studies/bio01_pair_eligibility/registration/registration.json','Original 0.1 registration; 0.2 hashes are derived in memory'))),
 visualization=list(decision='not_required',rationale='No new spatial/value result; tabular audit suffices.',spec_refs=list(),narrative_ref=ref('narrative'),decision_ref=report_ref,review_refs=list(ref('review_human_d3'))),review_items=items,
 reproducibility=list(dimensions=list(list(dimension='results',status='demonstrated',scope='Local deterministic documentary observations only',evidence_refs=list(ext('data/metadata/dataspec_pair_pilot_v1/checks.json','Original bounded checks'))),list(dimension='clean_clone',status='not_demonstrated',scope='Raw rasters, documentary snapshots and preservation files are local',evidence_refs=list())),dependencies=list(list(name='governed local inputs',availability='local_only',reference=ext('dataspec/studies/bio01_pair_eligibility/registration/registration.json','Exact local prerequisites')))),registration=reg)
# Stage a disposable local interpretation. Copies preserve source bytes;
# validation only reads them. Only the new snapshot is authored in this root.
# This derived binding is NOT claimed to have existed in the historical pilot.
source_root<-root;root<-tempfile('climate_v02_view_');dir.create(root)
for(entry in e$collect_refs(list(b,original,registration,acceptance),'external')) {
 path<-entry$value$path;source_path<-file.path(source_root,path)
 if(!file.exists(source_path))next
 target<-file.path(root,path);dir.create(dirname(target),recursive=TRUE,showWarnings=FALSE)
 if(!file.exists(target))stopifnot(file.copy(source_path,target))
}
frozen<-b$governance$registration
snapshot_path<-'data/metadata/dataspec_v02_interpretation/registration_v1.json'
dir.create(dirname(file.path(root,snapshot_path)),recursive=TRUE,showWarnings=FALSE)
writeLines(jsonlite::toJSON(frozen,auto_unbox=TRUE,null='null',pretty=TRUE,digits=NA),file.path(root,snapshot_path))
snapshot_ref<-ext(snapshot_path,'Derived v0.2 interpretation only; not historical preregistration')
b$governance$registration$snapshot_ref<-snapshot_ref
execution_index<-which(vapply(b$records,function(x)x$kind=='execution',logical(1)))
b$records[[execution_index]]$payload$config_refs<-c(b$records[[execution_index]]$payload$config_refs,list(snapshot_ref))
configs<-b$records[[execution_index]]$payload$config_refs
b$records[[execution_index]]$payload$config_refs<-configs[order(vapply(configs,function(x)paste(x$path,x$sha256,x$locator),''),method='radix')]
# D2 records ACCEPT WITH EDIT as a group; the unchanged excluded candidate has
# per-item ACCEPT for continued exclusion, never acceptance of its assertion.
r<-validate_dataspec(b,root)
if(!r$valid)print(r$findings)
stopifnot(r$valid,r$status$analysis_ready)
cat('PASS climate transient 0.2 governance: registration, accepted edits, bounded reproduction\n')
# A new manifest is a draft interpretation. No approval of this new identity is
# fabricated; existing project closure remains accepted in its original bytes.
delivery<-record('narrative');delivery$artifact_id<-'delivery_v02_interpretation';delivery$revision<-1L;delivery$kind<-'delivery';delivery$status<-'draft'
claims<-record('narrative')$payload$claim_refs
reviews<-lapply(c('review_human_d1','review_human_d2','review_human_d3'),ref)
delivery$payload<-list(question_ref=ref('question'),deliverable_refs=list(report_ref),spec_refs=list(ref('narrative')),
 claim_location_map=lapply(claims,function(c)list(claim_ref=c,artifact_ref=report_ref,location=c$artifact_id)),review_refs=reviews,
 dependency_snapshot=lapply(b$records,function(x)x[c('project_id','artifact_id','revision')]),reproduction_instructions='Use preserved climate check commands and local inputs; no clean-clone claim.',known_gaps=list('No new acceptance of this transient manifest; historical project closure unchanged.'),delivery_disposition='qualified_answer')
b$records<-c(b$records,list(delivery));b$candidate_refs<-lapply(b$records,function(x)x[c('project_id','artifact_id','revision')]);b$candidate_refs<-b$candidate_refs[order(vapply(b$candidate_refs,e$ref_key,''),method='radix')]
r<-validate_dataspec(b,root)
if(!r$valid)print(r$findings)
stopifnot(r$valid,length(r$findings)==0L,r$status$delivery=='review_pending',!any(vapply(b$records,function(x)x$kind=='visualization_spec',logical(1))))
cat('PASS climate nonvisual delivery manifest: valid with no fake visualization; new manifest acceptance not fabricated\n')

unlink(root,recursive=TRUE)
