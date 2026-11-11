# DataSpec 0.2 read-only governance validation; 0.1 runtime remains immutable.
# Source this library, then call validate_dataspec(bundle, project_root, core_root).

# Load the preserved engine into a private namespace, isolating version dispatch.
load_legacy <- function(core_root) {
  engine <- new.env(parent = globalenv())
  sys.source(file.path(core_root, 'validators/core.R'), engine)
  engine
}

# Validate either historical 0.1 or the explicit 0.2 governance envelope.
validate_dataspec <- function(bundle, project_root, core_root = 'dataspec') {
  engine <- load_legacy(core_root)
  old_schema <- file.path(core_root, 'schemas/bundle.schema.json')
  if (is.list(bundle) && identical(bundle$schema_version, '0.1.0')) return(engine$validate_bundle(bundle, project_root, old_schema))
  schema <- engine$read_json_strict(file.path(core_root, 'v0.2/schemas/bundle.schema.json'))
  engine$check_schema_profile(schema)
  findings <- list()
  schema_valid <- FALSE
  add <- function(code, record, field, message, severity = 'error') {
    findings[[length(findings)+1L]] <<- list(code=code,severity=severity,record=record,field=field,message=message)
  }
  # Produce deterministic status axes without granting scientific certification.
  finish <- function(records=list(), requirements=list(), analysis_ready=FALSE, delivery='not_requested') {
    if(length(findings)) findings <<- findings[order(vapply(findings,function(x)paste(x$record,x$field,x$code,x$message),''),method='radix')]
    valid <- !any(vapply(findings,function(x)x$severity=='error',logical(1)))
    pending <- Filter(function(x)x$status!='satisfied',requirements)
    automated <- if(!schema_valid) list() else Filter(function(x)x$kind=='review' && x$payload$review_mode=='automated',bundle$records)
    if(length(automated)) automated <- automated[order(vapply(automated,engine$ref_key,''),method='radix')]
    list(schema_version='0.2.0',valid=valid,certification='not_assessed',findings=findings,records=records,
      review_requirements=requirements, status=list(
        schema_validity=schema_valid, structural_validity=valid,
        reproducibility=if(!schema_valid) NULL else bundle$governance$reproducibility,
        automated_review=lapply(automated,function(x)list(review_ref=x[c('project_id','artifact_id','revision')],status=x$status,disposition=x$payload$disposition)),
        human_acceptance=if(!valid) 'blocked' else if(length(pending)) 'pending' else if(length(requirements)) 'recorded' else 'not_assessed',
        scientific_certification='not_assessed', analysis_ready=valid && analysis_ready,
        delivery=if(valid) delivery else 'blocked',
        next_action=if(!valid) 'resolve_findings' else if(delivery=='closed') 'complete' else if(length(pending)) 'request_human_review' else if(analysis_ready && !any(vapply(bundle$records,function(x)x$kind=='execution',logical(1)))) 'execute_registered_plan' else 'continue_lifecycle'))
  }
  errors <- engine$schema_errors(bundle,schema)
  if(length(errors)) {for(error in errors)add('SCHEMA','bundle','$',error); return(finish())}
  schema_valid <- TRUE
  g <- bundle$governance
  keys <- vapply(bundle$records,engine$ref_key,'')
  if(anyDuplicated(keys)) {add('IDENTITY','bundle','records','Duplicate record identity'); return(finish())}
  records <- setNames(bundle$records,keys)
  keys <- sort(keys,method='radix'); records <- records[keys]
  selected <- vapply(bundle$candidate_refs,engine$ref_key,'')
  # Resolve current exact references and enforce their artifact kinds.
  resolve <- function(ref, kinds=NULL, field='governance') {
    if(is.null(ref)) return(NULL)
    key <- engine$ref_key(ref)
    if(!key %in% keys || !key %in% selected) {add('REFERENCE','bundle',field,paste('Missing or unselected revision',key)); return(NULL)}
    r <- records[[key]]
    if(!is.null(kinds) && !r$kind %in% kinds) {add('REFERENCE','bundle',field,'Wrong artifact kind'); return(NULL)}
    r
  }
  root <- normalizePath(project_root,mustWork=TRUE)
  # All governance bytes receive the same containment and checksum discipline.
  verify <- function(ref, field) {
    if(is.null(ref)) return(FALSE)
    if(ref$availability!='verified_local') {add('UNAVAILABLE','bundle',field,'Governance evidence must be locally verified'); return(FALSE)}
    if(is.null(ref$sha256)||is.null(ref$locator)) {add('SCHEMA','bundle',field,'Verified governance evidence requires SHA-256 and locator'); return(FALSE)}
    path <- engine$safe_file(ref$path,root)
    if(is.null(path)) {add('PATH','bundle',field,'Missing or escaping governance reference');return(FALSE)}
    if(digest::digest(file=path,algo='sha256')!=ref$sha256) {add('HASH','bundle',field,'Governance SHA-256 mismatch');return(FALSE)}
    TRUE
  }
  for(ref in engine$collect_refs(g,'external')) {
    declared_missing <- grepl('reproducibility.dependencies',ref$path,fixed=TRUE) &&
      ref$value$availability=='unavailable' && any(vapply(g$reproducibility$dependencies,
        function(x)x$availability=='unavailable' && identical(x$reference,ref$value),logical(1)))
    if(declared_missing) {
      if(is.null(ref$value$reason)) add('SCHEMA','bundle',ref$path,'Unavailable dependency needs a reason')
    } else verify(ref$value,ref$path)
  }
  for(ref in engine$collect_refs(g,'internal')) resolve(ref$value,field=ref$path)
  engine$check_sets(g,'bundle',add,'governance')
  # Check an existing attestation, not the truth or independence of its author.
  attests <- function(review, target, dimension) {
    !is.null(target) && !is.null(review) && review$kind=='review' && review$status=='accepted' &&
      review$payload$review_mode!='automated' && review$payload$disposition=='pass' &&
      all(vapply(review$payload$checks,function(x)x$result=='pass',logical(1))) &&
      dimension %in% unlist(review$payload$review_dimensions) &&
      engine$ref_key(target) %in% vapply(review$payload$target_refs,engine$ref_key,'')
  }
  has_source <- function(review, ref) {
    if(is.null(review)||is.null(ref)) return(FALSE)
    any(vapply(engine$collect_refs(review$payload$checks,'external'),function(x)
      identical(x$value$path,ref$path)&&identical(x$value$sha256,ref$sha256),logical(1)))
  }
  # Validate preserved record content using its own explicit historical version.
  complete_record <- function(record) {
    if(!is.list(record) || !engine$json_type_matches(record$schema_version,'string') || !record$schema_version %in% c('0.1.0','0.2.0')) return(FALSE)
    record_schema <- if(record$schema_version=='0.1.0') engine$read_json_strict(old_schema) else schema
    !length(engine$schema_errors(record,record_schema$`$defs`$record,record_schema))
  }
  current <- records[intersect(keys,selected)]
  deliveries <- Filter(function(x)x$kind=='delivery',current)
  closing <- length(deliveries)>0L
  # Individual requirements are not a Cartesian product of a group's dimensions.
  item_keys <- vapply(g$review_items,function(x)paste(engine$ref_key(x$target_ref),x$dimension),'')
  if(anyDuplicated(item_keys)||anyDuplicated(vapply(g$review_items,`[[`,'','requirement_id'))) add('REVIEW','bundle','review_items','Duplicate current requirement/item')
  for(item in g$review_items) {
    target <- resolve(item$target_ref,field='review_items.target_ref')
    review <- resolve(item$review_ref,'review','review_items.review_ref')
    positive <- item$disposition %in% c('ACCEPT','ACCEPT WITH EDIT')
    if(positive && (!attests(review,item$target_ref,item$dimension)||!has_source(review,item$source_ref))) add('REVIEW',engine$ref_key(item$target_ref),'review_items','Accepted item needs exact human attestation and preserved decision source')
    if(!positive && ((!is.null(target)&&target$status=='accepted')||closing)) add('REVIEW',engine$ref_key(item$target_ref),'review_items','Rejected/unresolved item blocks acceptance or closure')
    if(item$disposition=='ACCEPT WITH EDIT') {
      if(is.null(item$previous_ref)||is.null(item$edit_ref)||!has_source(review,item$edit_ref)) add('REVIEW',engine$ref_key(item$target_ref),'edit_ref','Edit needs previous revision bytes and review-linked edit provenance')
      if(!is.null(target) && !is.null(item$previous_ref) && verify(item$previous_ref,'previous_ref')) {
        previous <- tryCatch(engine$read_json_strict(engine$safe_file(item$previous_ref$path,root)),error=function(e)NULL)
        old <- if(is.list(previous)&&!is.null(previous$records)) previous$records else list(previous)
        matches <- Filter(function(x)complete_record(x)&&x$artifact_id==target$artifact_id&&x$project_id==target$project_id&&identical(x$study_id,target$study_id)&&x$kind==target$kind&&x$revision<target$revision,old)
        if(length(matches)!=1L) {
          add('REVIEW',engine$ref_key(target),'previous_ref','Preserve one complete, schema-valid earlier revision of this logical object')
        } else {
          prior <- matches[[1]]
          for(source in engine$collect_refs(prior,'external')) verify(source$value,'previous_ref.content')
          prior_reviews <- Filter(function(x)complete_record(x)&&x$kind=='review'&&engine$ref_key(prior)%in%vapply(x$payload$target_refs,engine$ref_key,''),c(old,bundle$records))
          for(prior_review in prior_reviews) for(source in engine$collect_refs(prior_review,'external')) verify(source$value,'previous_ref.review')
          if(prior$status=='accepted' && !prior$kind%in%c('review','change')) {
            dimension <- if(prior$kind=='narrative_spec')'narrative' else if(prior$kind=='visualization_spec')'visual' else 'scientific'
            dimensions <- dimension
            if(prior$schema_version=='0.2.0' && prior$kind%in%c('narrative_spec','visualization_spec')) dimensions <- c(dimensions,'reproducibility')
            for(d in dimensions) if(!any(vapply(prior_reviews,function(x)attests(x,prior,d),logical(1)))) add('REVIEW',engine$ref_key(target),'previous_ref',paste('Accepted predecessor lacks preserved exact human review provenance:',d))
          }
          if(!is.null(target$supersedes)&&engine$ref_key(target$supersedes)!=engine$ref_key(prior)) add('REVIEW',engine$ref_key(target),'previous_ref','Predecessor conflicts with supersedes lineage')
        }
      }
    }
  }
  requirements <- list()
  for(r in current) {
    if(r$kind=='claim' && r$status=='accepted' && r$payload$disposition=='unsupported')
      add('CLAIM',engine$ref_key(r),'status','Accept exclusion through review; do not accept an unsupported proposition')
    dims <- if(r$kind=='claim' && r$payload$disposition!='unsupported') 'scientific' else if(r$kind=='narrative_spec') c('narrative','reproducibility') else if(r$kind=='visualization_spec') c('visual','reproducibility') else if(r$kind=='delivery') 'scientific' else character()
    for(d in dims) {
      id <- paste(engine$ref_key(r),d)
      idx <- match(id,item_keys)
      satisfied <- !is.na(idx) && g$review_items[[idx]]$disposition %in% c('ACCEPT','ACCEPT WITH EDIT')
      requirements[[length(requirements)+1L]] <- list(target_ref=r[c('project_id','artifact_id','revision')],dimension=d,status=if(satisfied)'satisfied'else'pending',group_id=if(is.na(idx))NULL else g$review_items[[idx]]$group_id)
      if(!satisfied && (r$status=='accepted'||(closing && r$kind!='delivery'))) add('REVIEW',engine$ref_key(r),d,'Missing explicit per-item human disposition')
    }
    if(r$kind=='narrative_spec') {
      # The closed narrative schema has assertion refs and an explicit exclusion
      # branch. Walk every other internal reference, including section refs.
      content <- r$payload; content$excluded_claims_with_reasons <- NULL
      refs <- engine$collect_refs(content,'internal')
      reviewed <- r$status%in%c('accepted','in_review') || any(vapply(g$review_items,function(x)engine$ref_key(x$target_ref)==engine$ref_key(r)&&x$disposition%in%c('ACCEPT','ACCEPT WITH EDIT'),logical(1)))
      for(entry in refs) {
        claim <- resolve(entry$value,'claim',entry$path)
        if(is.null(claim)) next
        claim_key <- engine$ref_key(claim)
        if(claim$payload$disposition=='unsupported') add('CLAIM',engine$ref_key(r),entry$path,paste('Unsupported narrative assertion',claim_key,'must remain excluded'))
        if(reviewed && claim$payload$disposition!='unsupported') {
          accepted_item <- Filter(function(x)engine$ref_key(x$target_ref)==claim_key&&x$dimension=='scientific'&&x$disposition%in%c('ACCEPT','ACCEPT WITH EDIT'),g$review_items)
          if(!length(accepted_item)||claim$status%in%c('rejected','superseded')) add('REVIEW',engine$ref_key(r),entry$path,paste('Narrative claim lacks allowed scientific review state:',claim_key))
        }
      }
      section_keys <- unlist(lapply(r$payload$ordered_sections,function(x)vapply(x$claim_refs,engine$ref_key,'')),use.names=FALSE)
      if(reviewed && !setequal(section_keys,vapply(r$payload$claim_refs,engine$ref_key,''))) add('CLAIM',engine$ref_key(r),'ordered_sections','Narrative section claims and declared claims differ')
    }
  }
  v <- g$visualization
  narrative <- resolve(v$narrative_ref,'narrative_spec','visualization.narrative_ref')
  visuals <- lapply(v$spec_refs,function(ref)resolve(ref,'visualization_spec','visualization.spec_refs'))
  if(v$decision=='undecided' && closing) add('VISUALIZATION','bundle','visualization','Undecided visual requirement blocks delivery')
  if(v$decision=='required' && closing && !length(visuals)) add('VISUALIZATION','bundle','spec_refs','Required visualization is missing')
  if(v$decision=='not_required' && length(visuals)) add('VISUALIZATION','bundle','spec_refs','not_required cannot declare visual specifications')
  if(v$decision!='undecided' && (is.null(narrative)||is.null(v$decision_ref))) add('VISUALIZATION','bundle','visualization','Decided branch requires narrative and preserved rationale')
  if(closing) {
    approved <- any(vapply(v$review_refs,function(ref) {
      review <- resolve(ref,'review'); attests(review,v$narrative_ref,'narrative')&&has_source(review,v$decision_ref)
    },logical(1)))
    if(!approved) add('REVIEW','bundle','visualization','Visual decision needs human narrative review linked to its preserved rationale')
    for(delivery in deliveries) {
      if(!all(vapply(v$review_refs,engine$ref_key,'') %in% vapply(delivery$payload$review_refs,engine$ref_key,'')))
        add('REVIEW',engine$ref_key(delivery),'review_refs','Visualization decision review must be inside the delivery dependency closure')
      delivered <- vapply(delivery$payload$spec_refs,engine$ref_key,'')
      if(is.null(v$narrative_ref)||!engine$ref_key(v$narrative_ref)%in%delivered) add('VISUALIZATION',engine$ref_key(delivery),'spec_refs','Decision narrative differs from delivered narrative')
      actual <- delivered[vapply(delivered,function(k)k%in%keys&&records[[k]]$kind=='visualization_spec',logical(1))]
      if(!setequal(actual,vapply(v$spec_refs,engine$ref_key,''))) add('VISUALIZATION',engine$ref_key(delivery),'spec_refs','Delivered visuals differ from explicit decision')
    }
  }
  # Structured reproduction reports evidence only for claimed dimensions.
  dimensions <- g$reproducibility$dimensions
  if(anyDuplicated(vapply(dimensions,`[[`,'','dimension'))) add('REPRODUCIBILITY','bundle','dimensions','Duplicate reproduction dimension')
  for(d in dimensions) {
    if(d$status %in% c('demonstrated','partial') && !length(d$evidence_refs)) add('REPRODUCIBILITY','bundle',d$dimension,'Demonstrated/partial scope needs evidence')
    if(d$dimension=='clean_clone' && d$status=='demonstrated' && any(vapply(g$reproducibility$dependencies,function(x)x$availability!='version_controlled',logical(1)))) add('REPRODUCIBILITY','bundle','clean_clone','Clean-clone claim contradicts declared local/external/unavailable dependency')
  }
  if(closing && !length(dimensions)) add('REPRODUCIBILITY','bundle','dimensions','Delivery requires an explicit bounded reproduction scope')
  # Adoption changes provenance semantics, not the record kinds or science rules.
  adoption <- g$adoption; reg <- g$registration
  if(adoption$mode=='in_place' && (is.null(adoption$cutover_at)||!engine$valid_timestamp(adoption$cutover_at)||!length(adoption$history_refs))) add('ADOPTION','bundle','cutover_at','In-place adoption requires valid cutover and preserved history')
  if(adoption$mode!='in_place' && !is.null(adoption$cutover_at)) add('ADOPTION','bundle','cutover_at','Cutover belongs only to in-place adoption')
  if(adoption$mode=='retrospective') {
    if(!is.null(reg)) add('ADOPTION','bundle','registration','Retrospective work cannot invent prospective registration')
    for(r in Filter(function(x)x$kind%in%c('question','analysis_plan'),current)) if(r$record_origin=='prospective') add('ADOPTION',engine$ref_key(r),'record_origin','Retrospective framing must be reconstructed or imported')
  }
  if(adoption$mode=='native' && is.null(reg)) add('GATE','bundle','registration','Native prospective work requires registration')
  executions <- Filter(function(x)x$kind=='execution',current)
  after_cutover <- function(r) adoption$mode=='in_place' &&
    (r$record_origin=='prospective' || (!is.null(adoption$cutover_at) &&
       !is.null(r$payload$started_at) && r$payload$started_at>=adoption$cutover_at))
  if(adoption$mode=='in_place' && is.null(reg) && any(vapply(executions,after_cutover,logical(1)))) add('GATE','bundle','registration','Post-cutover execution needs prospective registration')
  ready <- FALSE
  if(!is.null(reg)) {
    # Freeze the whole registration, not only its framing records. The snapshot
    # excludes only its own external reference to avoid a self-referential hash.
    frozen <- reg; frozen$snapshot_ref <- NULL
    if(verify(reg$snapshot_ref,'registration.snapshot_ref')) {
      snapshot <- tryCatch(engine$read_json_strict(engine$safe_file(reg$snapshot_ref$path,root)),error=function(e)NULL)
      if(!identical(engine$canonical_json(snapshot),engine$canonical_json(frozen))) add('HASH','bundle','registration.snapshot_ref','Complete registration differs from preserved snapshot')
    }
    if(reg$revision==1L && !is.null(reg$previous_ref)) add('GATE','bundle','registration.previous_ref','Initial registration cannot have a predecessor')
    if(reg$revision>1L) {
      if(is.null(reg$previous_ref)) add('GATE','bundle','registration.previous_ref','Revised registration must preserve its preceding snapshot')
      else if(verify(reg$previous_ref,'registration.previous_ref')) {
        prior <- tryCatch(engine$read_json_strict(engine$safe_file(reg$previous_ref$path,root)),error=function(e)NULL)
        snapshot_schema <- schema$properties$governance$properties$registration$oneOf[[1]]
        snapshot_schema$properties$snapshot_ref <- NULL
        snapshot_schema$required <- Filter(function(x)x!='snapshot_ref',snapshot_schema$required)
        if(length(engine$schema_errors(prior,snapshot_schema,schema))) add('GATE','bundle','registration.previous_ref','Preceding registration snapshot is incomplete')
        else if(prior$revision!=reg$revision-1L || prior$registered_at>=reg$registered_at || prior$question_ref$project_id!=reg$question_ref$project_id || prior$question_ref$artifact_id!=reg$question_ref$artifact_id) add('GATE','bundle','registration.previous_ref','Registration predecessor identity, revision or chronology differs')
      }
    }
    question <- resolve(reg$question_ref,'question'); plan <- resolve(reg$plan_ref,'analysis_plan')
    for(ref in reg$contract_refs) resolve(ref,'data_contract_ref')
    required <- c('question_defined','inputs_fixed','provenance_sufficient','semantics_documented','method_specified','failure_conditions_defined')
    gate_ids <- vapply(reg$gate_checks,`[[`,'','criterion')
    ready <- setequal(required,gate_ids)&&!anyDuplicated(gate_ids)&&all(vapply(reg$gate_checks,`[[`,logical(1),'passed'))
    if(!ready) add('GATE','bundle','gate_checks','analysis-ready criteria incomplete or blocked')
    if(!engine$valid_timestamp(reg$registered_at)) add('TIMING','bundle','registered_at','Invalid workspace registration timestamp')
    if(!length(reg$criteria)||!length(reg$input_refs)||!length(reg$contract_refs)) add('GATE','bundle','registration','Criteria, fixed inputs and authorities are required')
    if(!is.null(plan)&&!is.null(question)) {
      if(engine$ref_key(plan$payload$question_ref)!=engine$ref_key(reg$question_ref)||!setequal(vapply(plan$payload$contract_refs,engine$ref_key,''),vapply(reg$contract_refs,engine$ref_key,''))) add('GATE','bundle','plan_ref','Registration and plan authorities/question differ')
      if(adoption$mode=='native' && any(c(plan$record_origin,question$record_origin)!='prospective')) add('ADOPTION','bundle','record_origin','Native question and plan must be prospective')
    }
    fixed <- c(list(reg$question_ref,reg$plan_ref),reg$contract_refs)
    hashes <- vapply(reg$record_hashes,function(x)engine$ref_key(x$record_ref),'')
    if(!setequal(hashes,vapply(fixed,engine$ref_key,''))||anyDuplicated(hashes)) add('GATE','bundle','record_hashes','Freeze exactly the question, plan and contract revisions')
    for(h in reg$record_hashes) {
      r <- resolve(h$record_ref)
      if(!is.null(r)) {
        if(digest::digest(engine$canonical_json(r),algo='sha256',serialize=FALSE)!=h$sha256) add('HASH',engine$ref_key(r),'registration','Frozen record content changed')
        if(r$created_at>reg$registered_at) add('TIMING',engine$ref_key(r),'created_at','Record created after registration')
      }
    }
    if(adoption$mode=='in_place' && !is.null(adoption$cutover_at) && reg$registered_at<adoption$cutover_at) add('TIMING','bundle','registered_at','Registration precedes declared cutover')
    for(evidence in Filter(function(x)x$kind=='evidence' && x$record_origin=='prospective',current))
      if(evidence$created_at<reg$registered_at) add('TIMING',engine$ref_key(evidence),'created_at','Prospective evidence predates registration; preserve earlier evidence as imported')
    for(run in executions) if(adoption$mode=='native'||after_cutover(run)) {
      if(!any(vapply(run$payload$config_refs,function(x)identical(x$path,reg$snapshot_ref$path)&&identical(x$sha256,reg$snapshot_ref$sha256),logical(1)))) add('GATE',engine$ref_key(run),'config_refs','Execution must reference the complete frozen registration snapshot')
      if(run$record_origin!='prospective') add('ADOPTION',engine$ref_key(run),'record_origin','Registered execution must retain prospective origin')
      if(is.null(run$payload$started_at)||run$payload$started_at<=reg$registered_at) add('TIMING',engine$ref_key(run),'started_at','Execution must follow workspace registration')
      if(engine$ref_key(run$payload$plan_ref)!=engine$ref_key(reg$plan_ref)) add('GATE',engine$ref_key(run),'plan_ref','Execution does not use registered plan')
      input_key <- function(x)paste(x$path,x$sha256)
      if(!setequal(vapply(run$payload$input_refs,input_key,''),vapply(reg$input_refs,input_key,''))) add('GATE',engine$ref_key(run),'input_refs','Execution inputs differ from registered inputs')
    }
  }
  # Shared strict engine; only the explicit 0.2 delivery visual branch differs.
  projected <- bundle; projected$governance <- NULL; projected$schema_version <- '0.1.0'
  projected$records <- lapply(projected$records,function(r){r$schema_version<-'0.1.0';r})
  delivery_function <- validate_delivery_v02
  environment(delivery_function) <- engine
  engine$visual_decision <- v$decision
  engine$validate_delivery <- delivery_function
  legacy <- engine$validate_bundle(projected,root,old_schema)
  findings <- c(findings,legacy$findings)
  delivery_state <- if(!closing)'not_requested' else if(all(vapply(deliveries,function(x)x$status=='accepted',logical(1))))'closed'else'review_pending'
  finish(legacy$records,requirements,ready,delivery_state)
}
# Verify delivery closure, claim mapping, and required human review coverage.
validate_delivery_v02 <- function(x, key, records, graph, reviewed, add) {
  p <- x$payload
  keys <- names(records)
  review_keys <- vapply(p$review_refs, ref_key, "")
  claim_keys <- vapply(p$claim_location_map, function(z) ref_key(z$claim_ref), "")
  spec_keys <- vapply(p$spec_refs, ref_key, "")
  snapshot <- vapply(p$dependency_snapshot, ref_key, "")
  # Compute closure without snapshot edges so an extra record cannot justify itself.
  saved <- graph[[key]]
  direct <- collect_refs(p[setdiff(names(p), "dependency_snapshot")], "internal")
  graph[[key]] <- unique(c(vapply(direct, function(z) ref_key(z$value), ""), vapply(x$depends_on, ref_key, "")))
  expected <- dependency_closure(key, graph); graph[[key]] <- saved
  if (!setequal(snapshot, expected)) add("DELIVERY", key, "dependency_snapshot", "Snapshot is not the exact dependency closure")
  for (ancestor in c(key, expected)) {
    for (external in collect_refs(records[[ancestor]]$payload, "external")) {
      if (external$value$availability != "verified_local") add("UNAVAILABLE", key, "dependency_snapshot", paste("Delivery depends on unavailable evidence in", ancestor))
    }
    if (records[[ancestor]]$status %in% c("rejected", "superseded")) add("DELIVERY", key, "dependency_snapshot", paste("Delivery includes rejected/superseded record", ancestor))
  }
  spec_kinds <- vapply(records[intersect(spec_keys, keys)], `[[`, "", "kind")
  if (!("narrative_spec" %in% spec_kinds) || (visual_decision != "not_required" && !("visualization_spec" %in% spec_kinds))) add("DELIVERY", key, "spec_refs", "Delivery requires narrative and visual specifications")
  for (t in intersect(claim_keys, keys)) {
    if (records[[t]]$kind != "claim") next
    disposition <- records[[t]]$payload$disposition
    if (p$delivery_disposition == "answer" && disposition != "supported") add("CLAIM", key, "claim_location_map", "Answer requires supported claims")
    if (p$delivery_disposition == "qualified_answer" && !disposition %in% c("supported", "qualified")) add("CLAIM", key, "claim_location_map", "Qualified answer includes unsupported claim")
    if (p$delivery_disposition == "inconclusive" && disposition == "unsupported") add("CLAIM", key, "claim_location_map", "Inconclusive delivery must explain uncertainty rather than include an unsupported assertion")
    if (!reviewed(t, "scientific", review_keys)) add("REVIEW", key, "review_refs", "Delivered claim lacks human scientific review")
  }
  if (p$delivery_disposition == "inconclusive" && (is.null(p$inconclusive_reason) || !length(p$known_gaps))) add("DELIVERY", key, "inconclusive_reason", "Inconclusive delivery needs reason and known gaps")
  artifact_ids <- vapply(p$deliverable_refs, function(z) paste(z$path, z$sha256), "")
  for (location in p$claim_location_map) if (!paste(location$artifact_ref$path, location$artifact_ref$sha256) %in% artifact_ids) add("DELIVERY", key, "claim_location_map", "Claim location is outside declared deliverables")
  for (t in intersect(spec_keys, keys)) {
    spec <- records[[t]]
    required <- if (spec$kind == "visualization_spec") c("visual", "reproducibility") else c("narrative", "reproducibility")
    for (dimension in required) if (!reviewed(t, dimension, review_keys)) add("REVIEW", key, "review_refs", paste("Missing", dimension, "review for", t))
    mentioned <- vapply(spec$payload$claim_refs, ref_key, "")
    if (!all(mentioned %in% claim_keys)) add("DELIVERY", key, "claim_location_map", "Specification contains an unmapped claim")
    if (spec$kind == "narrative_spec") {
      section_claims <- unlist(lapply(spec$payload$ordered_sections, function(z) vapply(z$claim_refs, ref_key, "")), use.names = FALSE)
      if (!setequal(section_claims, mentioned)) add("DELIVERY", key, "spec_refs", "Narrative sections and declared claims differ")
      section_sources <- unlist(lapply(spec$payload$ordered_sections, function(z) vapply(z$context_source_refs, canonical_json, "")), use.names = FALSE)
      if (!all(section_sources %in% vapply(spec$payload$context_source_refs, canonical_json, ""))) add("DELIVERY", key, "spec_refs", "Narrative section context source is undeclared")
    }
  }
}

# Reject duplicate or unordered reference sets without modifying input.
