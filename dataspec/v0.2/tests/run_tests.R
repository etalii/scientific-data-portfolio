# Targeted 0.2 governance regressions; all file mutations confined to temp root.
source('dataspec/v0.2/tests/helpers.R')
root<-tempfile('dataspec_v02_');dir.create(root)
invisible(file.copy(list.files('dataspec/tests/fixtures/minimal',full.names=TRUE),root,recursive=TRUE))
# Run one scenario and require its precise validity/diagnostic contract.
check <- function(name,b,code=NULL,inspect=NULL) {
 r<-validate_dataspec(b,root)
 if(is.null(code)) {if(!r$valid)print(r$findings);stopifnot(r$valid)} else stopifnot(!r$valid,code%in%vapply(r$findings,`[[`,'','code'))
 if(!is.null(inspect))inspect(r)
 cat('PASS',name,'\n');count<<-count+1L
}
count<-0L
b<-fixture_v02(root)
check('required visual present',b)
nv<-nonvisual(b);check('explicit reviewed nonvisual delivery',nv)
x<-nv;x$governance$visualization$decision<-'required';check('required visual missing',x,'VISUALIZATION')
x<-nv;x$governance$visualization$decision<-'undecided';check('undecided closure blocked',x,'VISUALIZATION')
x<-nv;x$governance$visualization<-NULL;check('omission is not not_required',x,'SCHEMA')
x<-nv;x$governance$visualization$review_refs<-list();check('nonvisual rationale requires human review',x,'REVIEW')
x<-b;x$governance$visualization$decision<-'not_required';check('not_required cannot hide visual',x,'VISUALIZATION')
check('group retains six exact individual requirements',b,inspect=function(r)stopifnot(length(r$review_requirements)==6L))
x<-b;x$governance$review_items[[1]]$disposition<-'NEEDS INVESTIGATION';check('unresolved item blocks closure',x,'REVIEW')
x<-b;x$governance$review_items[[1]]$disposition<-'REJECT';check('rejection blocks closure',x,'REVIEW')
x<-b;x$governance$review_items[[1]]$disposition<-'ACCEPT WITH EDIT';check('edit without provenance rejected',x,'REVIEW')
x<-b
previous<-fixture_file(root,'assets/previous.json',x,TRUE)
# Revise the claim and every current reference, leaving the previous bytes intact.
revise<-function(z){if(!is.list(z))return(z);if(!is.null(z$artifact_id)&&z$artifact_id=='claim'&&!is.null(z$revision))z$revision<-2L;lapply(z,revise)}
x<-relink(revise(x));x$governance$review_items[[1]]$disposition<-'ACCEPT WITH EDIT';x$governance$review_items[[1]]$previous_ref<-previous;x$governance$review_items[[1]]$edit_ref<-x$governance$review_items[[1]]$source_ref
check('accepted edit preserves earlier revision source',x)
y<-x;y$governance$review_items[[1]]$previous_ref<-y$governance$review_items[[1]]$source_ref;check('unrelated previous bytes cannot prove revision',y,'REVIEW')
x<-b;x$governance$review_items[[1]]$review_ref<-iref('review',2L);check('review wrong revision rejected',x,'REFERENCE')
x<-b;x$governance$review_items<-c(x$governance$review_items,x$governance$review_items[1]);check('duplicate requirement rejected',x,'REVIEW')
check('bounded local reproduction and clean-clone not demonstrated',b)
x<-b;x$governance$reproducibility$dimensions[[1]]$status<-'partial';check('partial reproduction supported',x)
x<-b;x$governance$reproducibility$dimensions[[2]]$status<-'demonstrated';x$governance$reproducibility$dimensions[[2]]$evidence_refs<-list(x$governance$review_items[[1]]$source_ref);check('clean clone overclaim contradicts local dependency',x,'REPRODUCIBILITY')
x<-b;x$governance$reproducibility$dimensions[[1]]$evidence_refs<-list();check('demonstrated reproduction requires evidence',x,'REPRODUCIBILITY')
x<-native(b);check('prospective registration before execution',x,inspect=function(r)stopifnot(r$status$analysis_ready))
y<-x;y$records[[idx(y,'execution')]]$payload$started_at<-'2025-12-31T00:00:00Z';check('execution before registration rejected',y,'TIMING')
y<-x;y$governance['registration']<-list(NULL);check('native registration required',y,'GATE')
y<-x;y$governance$registration$gate_checks[[1]]$passed<-FALSE;check('failed gate blocks',y,'GATE')
y<-x;y$records[[idx(y,'plan')]]$payload$stopping_rule<-'Changed after freeze';check('plan content drift rejected',y,'HASH')
y<-x;y$governance$registration$input_refs<-list();check('registered inputs cannot disappear',y,'GATE')
y<-x;y$governance$registration$attestation<-'externally_certified';check('no trusted timestamp assertion',y,'SCHEMA')
check('retrospective reconstruction accepted',b)
y<-b;y$governance$registration<-x$governance$registration;check('retrospective cannot claim preregistration',y,'ADOPTION')
y<-x;y$governance$adoption<-list(mode='in_place',cutover_at='2026-01-01T06:00:00Z',history_refs=b$governance$adoption$history_refs);check('in-place cutover with preserved history',y)
z<-y;z$governance$adoption['cutover_at']<-list(NULL);check('in-place requires cutover',z,'ADOPTION')
z<-y;z$governance['registration']<-list(NULL);check('post-cutover run needs registration',z,'GATE')
x<-remove_artifact(remove_artifact(b,'delivery'),'review_closure');x$governance$review_items<-list();x$records[[idx(x,'review')]]$status<-'draft';check('zero findings with pending human review',x,inspect=function(r)stopifnot(r$status$human_acceptance=='pending',r$status$delivery=='not_requested'))
check('accepted reviews never certify science',b,inspect=function(r)stopifnot(r$certification=='not_assessed',r$status$scientific_certification=='not_assessed'))
x<-b;candidate<-x$records[[idx(x,'claim')]];candidate$artifact_id<-'unsupported';candidate$payload$disposition<-'unsupported';candidate$payload$supporting_evidence_refs<-list();x$records<-c(x$records,list(candidate));x<-relink(x);check('unsupported candidate may exist',x)
y<-x;y$records[[idx(y,'narrative')]]$payload$claim_refs<-c(y$records[[idx(y,'narrative')]]$payload$claim_refs,list(iref('unsupported')));y<-relink(y);check('unsupported candidate cannot enter narrative',y,'CLAIM')
y<-nv;y$governance$visualization$decision_ref$sha256<-paste(rep('0',64),collapse='');check('governance reference hashes checked',y,'HASH')
y<-nv;y$governance$visualization$decision_ref$path<-'../outside';check('governance containment checked',y,'PATH')
# Validate the pre-execution gate with only framing/plan/contract records.
y<-native(b);y$records<-Filter(function(r)r$kind%in%c('question','analysis_plan','data_contract_ref','metric'),y$records);y<-relink(y)
y$governance$review_items<-list();y$governance$visualization<-list(decision='undecided',rationale='Planning only',spec_refs=list(),narrative_ref=NULL,decision_ref=NULL,review_refs=list())
check('analysis-ready gate works before execution',y,inspect=function(r)stopifnot(r$status$analysis_ready,r$status$next_action=='execute_registered_plan'))
# The dual reader must not change historical 0.1 output.
old<-e$read_json_strict(file.path(root,'bundle.json'))
stopifnot(identical(validate_dataspec(old,root),e$validate_bundle(old,root,'dataspec/schemas/bundle.schema.json')))
count<-count+1L;cat('PASS historical 0.1 output unchanged\n')
# Additional boundary cases exercise malformed input and final acceptance.
x<-b;for(id in c('claim','narrative','visual','delivery'))x$records[[idx(x,id)]]$status<-'accepted'
check('accepted visual delivery remains uncertified',x,inspect=function(r)stopifnot(r$status$delivery=='closed',r$status$scientific_certification=='not_assessed'))
x<-nonvisual(x);check('accepted nonvisual delivery closes without fake visual',x,inspect=function(r)stopifnot(r$status$delivery=='closed'))
x<-nv;x$governance$review_items<-Filter(function(item)item$target_ref$artifact_id!='delivery',x$governance$review_items)
check('new valid delivery identity can await its own acceptance',x,inspect=function(r)stopifnot(r$status$delivery=='review_pending',r$status$human_acceptance=='pending'))
x<-nv;x$governance$visualization['narrative_ref']<-list(NULL);check('missing decision narrative fails without runtime exception',x,'VISUALIZATION')
x<-nv;x$records[[idx(x,'delivery')]]$payload$dependency_snapshot<-x$records[[idx(x,'delivery')]]$payload$dependency_snapshot[-1];check('nonvisual branch preserves closure snapshot rules',x,'DELIVERY')
x<-nv;x$records[[idx(x,'claim')]]$payload$supporting_evidence_refs<-list();check('nonvisual branch preserves claim evidence rules',x,'CLAIM')
x<-native(b);x$records[[idx(x,'evidence')]]$created_at<-'2025-12-31T00:00:00Z';check('prospective evidence cannot predate registration',x,'TIMING')
x<-native(b);x$governance$registration$gate_checks<-c(x$governance$registration$gate_checks,x$governance$registration$gate_checks[1]);check('duplicate gate criteria rejected',x,'GATE')
x<-native(b);x$governance$registration$registered_at<-'2026-02-30T00:00:00Z';check('impossible registration date rejected',x,'TIMING')
x<-b;x$governance$reproducibility$dimensions[[1]]$status<-'partial';missing<-list(path='absent.csv',sha256=NULL,locator=NULL,availability='unavailable',reason='Unavailable on this machine')
x$governance$reproducibility$dependencies<-list(list(name='missing external dependency',availability='unavailable',reference=missing));check('bounded report can declare unavailable extra dependency',x)
x<-b;x$records<-'malformed';check('malformed record array returns schema finding',x,'SCHEMA')
check('non-object bundle returns schema finding','malformed','SCHEMA')
x<-b;x$schema_version<-'9.0.0';check('unknown version rejected',x,'SCHEMA')
# Read-only validation cannot rewrite earlier reviewer bytes.
history<-fixture_file(root,'assets/review_history.json',b,TRUE)
x<-b;rewrite_review<-function(z){if(!is.list(z))return(z);if(!is.null(z$artifact_id)&&z$artifact_id=='review'&&!is.null(z$revision))z$revision<-2L;lapply(z,rewrite_review)}
x<-relink(rewrite_review(x));x$governance$adoption$history_refs<-list(history)
check('previous human review revision preserved as hashed history',x,inspect=function(r)stopifnot(digest::digest(file=file.path(root,history$path),algo='sha256')==history$sha256))
# New CLI works away from repository cwd, preserves exit-code distinctions.
cli<-normalizePath('dataspec/v0.2/validators/validate.R')
valid_path<-file.path(root,'v02.json');writeLines(jsonlite::toJSON(nv,auto_unbox=TRUE,null='null',digits=NA),valid_path)
invalid_path<-file.path(root,'invalid.json');writeLines('{"schema_version":"9.0.0"}',invalid_path)
stdout<-file.path(root,'cli.json');stderr<-file.path(root,'cli.err')
run_cli<-function(path) {old<-getwd();on.exit(setwd(old));setwd(tempdir());suppressWarnings(system2(file.path(R.home('bin'),'Rscript'),c('--vanilla',shQuote(cli),shQuote(path),shQuote(root)),stdout=stdout,stderr=stderr))}
stopifnot(run_cli(valid_path)==0L,e$read_json_strict(stdout)$valid,run_cli(invalid_path)==1L)
writeLines('{bad json',invalid_path);stopifnot(run_cli(invalid_path)==2L)
count<-count+1L;cat('PASS dual CLI root independence and exit codes\n')
x<-nv;extra_review<-x$records[[idx(x,'review')]];extra_review$artifact_id<-'review_visual_decision';x$records<-c(x$records,list(extra_review));x<-relink(x);x$governance$visualization$review_refs<-list(iref('review_visual_decision'));check('visual decision review must be in delivery closure',x,'REVIEW')
x<-nv;x$governance$visualization$decision_ref['sha256']<-list(NULL);check('verified governance reference cannot omit SHA',x,'SCHEMA')
x<-nv;x$governance$visualization$decision_ref['locator']<-list(NULL);check('verified governance reference cannot omit locator',x,'SCHEMA')
x<-b;x$records<-rev(x$records);check('record order does not change governance report',x,inspect=function(r)stopifnot(identical(r,validate_dataspec(b,root))))
# Release corrections: semantics are enforced before a delivery exists.
base<-remove_artifact(remove_artifact(b,'delivery'),'review_closure')
base$governance$review_items<-Filter(function(i)i$target_ref$artifact_id!='delivery',base$governance$review_items)
base$records[[idx(base,'narrative')]]$status<-'accepted'
candidate<-base$records[[idx(base,'claim')]];candidate$artifact_id<-'unsupported';candidate$payload$disposition<-'unsupported';candidate$payload$supporting_evidence_refs<-list()
base$records<-c(base$records,list(candidate));base<-relink(base)
x<-base;x$records[[idx(x,'narrative')]]$payload$ordered_sections[[1]]$claim_refs<-c(list(iref('claim')),list(iref('unsupported')))
check('accepted narrative rejects nested unsupported claim without delivery',x,'CLAIM',function(r)stopifnot(any(vapply(r$findings,function(f)f$record==e$ref_key(x$records[[idx(x,'narrative')]])&&grepl(e$ref_key(candidate),f$message,fixed=TRUE),logical(1))),identical(r,validate_dataspec(x,root))))
x<-base;x$records[[idx(x,'narrative')]]$payload$excluded_claims_with_reasons<-list(list(claim_ref=iref('unsupported'),reason='Unsupported candidate retained only as exclusion'))
check('accepted narrative permits explicit unsupported exclusion',x)
check('accepted narrative permits reviewed supported top and section claims',base)
x<-base;x$records[[idx(x,'narrative')]]$payload$ordered_sections[[1]]$claim_refs<-list()
check('accepted narrative requires section and top-level consistency',x,'CLAIM')
x<-base;x$governance$review_items<-Filter(function(i)i$target_ref$artifact_id!='claim',x$governance$review_items)
check('accepted narrative requires scientific disposition for asserted claim',x,'REVIEW')
# Preserve a complete predecessor and its human review when already accepted.
prior_bundle<-b;prior_bundle$records[[idx(prior_bundle,'claim')]]$status<-'accepted'
prior_source<-fixture_file(root,'assets/prior_complete.json',prior_bundle,TRUE)
edited<-relink(revise(b));edited$governance$review_items[[1]]$disposition<-'ACCEPT WITH EDIT';edited$governance$review_items[[1]]$previous_ref<-prior_source;edited$governance$review_items[[1]]$edit_ref<-edited$governance$review_items[[1]]$source_ref
check('edited revision preserves accepted predecessor content and review',edited)
x<-edited;x$governance$review_items[[1]]$previous_ref<-fixture_file(root,'assets/prior_identifiers.json',list(schema_version='0.2.0',project_id='synthetic',artifact_id='claim',revision=1L,kind='claim'),TRUE)
check('identifier-only predecessor rejected',x,'REVIEW')
prior<-b$records[[idx(b,'claim')]];prior$artifact_id<-'different'
x<-edited;x$governance$review_items[[1]]$previous_ref<-fixture_file(root,'assets/prior_other.json',prior,TRUE)
check('complete predecessor with wrong identity rejected',x,'REVIEW')
prior<-b$records[[idx(b,'claim')]];prior$revision<-2L
x<-edited;x$governance$review_items[[1]]$previous_ref<-fixture_file(root,'assets/prior_same_revision.json',prior,TRUE)
check('complete non-earlier predecessor rejected',x,'REVIEW')
prior<-b$records[[idx(b,'claim')]];prior$schema_version<-'0.1.0'
x<-edited;x$governance$review_items[[1]]$previous_ref<-fixture_file(root,'assets/prior_draft_v01.json',prior,TRUE)
check('complete historical draft predecessor needs no invented acceptance',x)
prior$status<-'accepted'
x<-edited;x$governance$review_items[[1]]$previous_ref<-fixture_file(root,'assets/prior_no_review.json',prior,TRUE)
check('accepted predecessor without exact prior human review rejected',x,'REVIEW')
# The execution binds the entire local registration, including gate and criteria.
registered<-native(b)
x<-registered;x$governance$registration$criteria<-list('Changed expectation after execution')
check('changed registration expectation invalidates snapshot',x,'HASH')
x<-registered;x$governance$registration$gate_checks[[1]]$rationale<-'Changed authorization criterion'
check('changed gate rationale invalidates snapshot',x,'HASH')
x<-registered;x$records[[idx(x,'execution')]]$payload$config_refs<-b$records[[idx(b,'execution')]]$payload$config_refs
check('execution without registration identity rejected',x,'GATE')
x<-registered;x$governance$registration$criteria<-list('New explicitly registered expectation');x$governance$registration$revision<-2L;x$governance$registration$previous_ref<-registered$governance$registration$snapshot_ref;x$governance$registration$registered_at<-'2026-01-01T18:00:00Z'
# New execution revision and refreshed downstream references, old bytes retained.
execution_history<-fixture_file(root,'assets/execution_before_reregistration.json',registered,TRUE)
new_execution<-function(z){if(!is.list(z))return(z);if(!is.null(z$artifact_id)&&z$artifact_id=='execution'&&!is.null(z$revision))z$revision<-2L;lapply(z,new_execution)}
x<-relink(new_execution(x));x$governance$adoption$history_refs<-list(execution_history)
x<-freeze_registration(x,root,'assets/registration_v2.json')
check('new registration and execution revisions preserve valid chronology',x)
y<-x;y$records[[idx(y,'execution')]]$payload$config_refs<-registered$records[[idx(registered,'execution')]]$payload$config_refs
check('new snapshot cannot reuse old execution registration reference',y,'GATE')
y<-x;y$records[[idx(y,'execution')]]$payload$started_at<-'2026-01-01T17:00:00Z'
check('new registration still must precede new execution',y,'TIMING')
y<-x;y$governance$registration['previous_ref']<-list(NULL)
check('new registration must retain preceding snapshot',y,'GATE')

# A previously accepted 0.2 specification retains all required review dimensions.
prior_bundle<-b;prior_bundle$records[[idx(prior_bundle,'narrative')]]$status<-'accepted'
prior_source<-fixture_file(root,'assets/prior_narrative_complete.json',prior_bundle,TRUE)
revise_narrative<-function(z){if(!is.list(z))return(z);if(!is.null(z$artifact_id)&&z$artifact_id=='narrative'&&!is.null(z$revision))z$revision<-2L;lapply(z,revise_narrative)}
x<-relink(revise_narrative(b))
for(i in seq_along(x$governance$review_items))if(x$governance$review_items[[i]]$target_ref$artifact_id=='narrative') {
 x$governance$review_items[[i]]$disposition<-'ACCEPT WITH EDIT'
 x$governance$review_items[[i]]$previous_ref<-prior_source
 x$governance$review_items[[i]]$edit_ref<-x$governance$review_items[[i]]$source_ref
}
check('accepted predecessor specification preserves both review dimensions',x)
prior_bundle$records[[idx(prior_bundle,'review')]]$payload$review_dimensions<-list('narrative','scientific','visual')
missing_dimension<-fixture_file(root,'assets/prior_narrative_missing_dimension.json',prior_bundle,TRUE)
for(i in seq_along(x$governance$review_items))if(x$governance$review_items[[i]]$target_ref$artifact_id=='narrative')x$governance$review_items[[i]]$previous_ref<-missing_dimension
check('accepted predecessor specification missing reproduction review rejected',x,'REVIEW')
cat('DataSpec 0.2:',count,'scenarios passed\n')
unlink(root,recursive=TRUE)
