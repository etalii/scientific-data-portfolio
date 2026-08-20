###############################################################
# Argentina Dengue Analysis
# Script: 18_build_season_published_count_indicators.R
# Purpose: Publish season counts, weekly rates, and geographic evidence.
###############################################################

abort_c18 <- function(message) stop(message, call. = FALSE)
read_csv_c18 <- function(path) {
  x <- readr::read_csv(path, show_col_types = FALSE)
  if (nrow(readr::problems(x))) abort_c18(paste("Invalid CSV:", path))
  x
}
publish_c18 <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(".c18_", dirname(path), ".tmp")
  on.exit(unlink(tmp), add = TRUE)
  readr::write_csv(x, tmp, na = "")
  if (!file.rename(tmp, path)) abort_c18(paste("Could not publish:", path))
}
rate_c18 <- function(count, population) 100000 * count / population
codes_c18 <- function(x) paste(sort(unique(x)), collapse = "|")

#' Build all C.18 artifacts after validating seasonal geography and denominators.
main <- function() {
  config <- yaml::read_yaml("config/project.yml"); a <- config$artifacts
  season <- read_csv_c18(a$epidemiological_season_rows)
  season_snapshot <- read_csv_c18(a$epidemiological_season_scope_snapshot)
  crosswalk <- read_csv_c18(a$source_geography_crosswalk)
  regions <- read_csv_c18(a$province_region_crosswalk)
  population <- read_csv_c18(a$population_denominators)
  if (nrow(season_snapshot) != 1L || season_snapshot$season_week_coverage_status[[1]] != "complete_expected_week_set") abort_c18("C.17 coverage is not complete.")
  joined <- dplyr::left_join(season, crosswalk[c("source_schema_family","source_province_id","source_province_name","reference_province_id","reference_province_name","mapping_status","source_geography_semantics_status")], by=c("source_schema_family","province_id"="source_province_id","province_name"="source_province_name"))
  if (any(is.na(joined$mapping_status))) abort_c18("A season geography is absent from the C.15 crosswalk.")
  mapped_status <- c("documented_exact","validated_exact")
  joined <- dplyr::mutate(
    joined,
    is_mapped = .data$mapping_status %in% mapped_status,
    is_unknown = .data$mapping_status == "unknown_source_category",
    is_ambiguous = .data$mapping_status == "ambiguous",
    is_unmapped = .data$mapping_status == "unmapped",
    is_name_based = .data$mapping_status == "name_based_unverified",
    is_nonassignable = !.data$is_mapped
  )
  mapped <- joined$is_mapped
  statuses <- c("name_based_unverified","ambiguous","unmapped","unknown_source_category")
  count_status <- function(status, field) if(field=="rows") sum(joined$mapping_status==status) else sum(joined$source_case_count[joined$mapping_status==status])
  family <- unique(joined$source_schema_family)
  semantics <- unique(joined$source_geography_semantics_status[joined$mapping_status!="unknown_source_category"])
  known_complete <- all(joined$mapping_status[joined$mapping_status!="unknown_source_category"] %in% mapped_status)
  if(length(family)!=1L || length(semantics)!=1L) abort_c18("Season geography has inconsistent family semantics.")
  reasons <- c(if(known_complete) "complete_known_geography_mapping", semantics, if(any(joined$mapping_status=="unknown_source_category")) "unknown_geography_present", if(any(joined$mapping_status=="name_based_unverified")) "name_based_mapping_present", if(any(joined$mapping_status=="ambiguous")) "ambiguous_mapping_present", if(any(joined$mapping_status=="unmapped")) "unmapped_geography_present")
  eligible <- if(family=="indec_residence_geography" && known_complete) "supported_with_caveats" else "unsupported"
  geo <- tibble::tibble(season_geographic_validation_schema_version="1.0.0",season_scope_id=season_snapshot$season_scope_id,season_label=season_snapshot$season_label,source_schema_family=family,season_total_published_row_count=nrow(joined),season_total_published_case_count=sum(joined$source_case_count),season_mapped_published_row_count=sum(mapped),season_mapped_published_case_count=sum(joined$source_case_count[mapped]),season_name_based_unverified_published_row_count=count_status("name_based_unverified","rows"),season_name_based_unverified_published_case_count=count_status("name_based_unverified","cases"),season_ambiguous_published_row_count=count_status("ambiguous","rows"),season_ambiguous_published_case_count=count_status("ambiguous","cases"),season_unmapped_published_row_count=count_status("unmapped","rows"),season_unmapped_published_case_count=count_status("unmapped","cases"),season_unknown_published_row_count=count_status("unknown_source_category","rows"),season_unknown_published_case_count=count_status("unknown_source_category","cases"),season_geographic_mapping_completeness=sum(joined$source_case_count[mapped])/sum(joined$source_case_count),source_geography_semantics_status=semantics,season_rate_geography_eligibility_status=eligible,season_rate_geography_reason_codes=codes_c18(reasons))
  nw <- joined |> dplyr::group_by(season_week_index,source_year,source_week) |> dplyr::summarise(published_row_count=dplyr::n(),published_case_count=sum(source_case_count),mapped_published_row_count=sum(is_mapped),mapped_published_case_count=sum(source_case_count[is_mapped]),unknown_published_row_count=sum(is_unknown),unknown_published_case_count=sum(source_case_count[is_unknown]),ambiguous_published_row_count=sum(is_ambiguous),ambiguous_published_case_count=sum(source_case_count[is_ambiguous]),unmapped_published_row_count=sum(is_unmapped),unmapped_published_case_count=sum(source_case_count[is_unmapped]),name_based_unverified_published_row_count=sum(is_name_based),name_based_unverified_published_case_count=sum(source_case_count[is_name_based]),nonassignable_published_row_count=sum(is_nonassignable),nonassignable_published_case_count=sum(source_case_count[is_nonassignable]),.groups="drop") |> dplyr::mutate(geographic_mapping_completeness=mapped_published_case_count/published_case_count)
  if(any(nw$published_case_count!=nw$mapped_published_case_count+nw$unknown_published_case_count+nw$ambiguous_published_case_count+nw$unmapped_published_case_count+nw$name_based_unverified_published_case_count) || any(nw$published_row_count!=nw$mapped_published_row_count+nw$unknown_published_row_count+nw$ambiguous_published_row_count+nw$unmapped_published_row_count+nw$name_based_unverified_published_row_count)) abort_c18("Weekly geography reconciliation failed.")
  ns <- tibble::tibble(season_indicator_schema_version="1.0.0",season_scope_id=season_snapshot$season_scope_id,season_label=season_snapshot$season_label,season_published_row_count=nrow(joined),season_published_case_count=sum(joined$source_case_count),season_week_count=dplyr::n_distinct(joined$season_week_index),season_geographic_mapping_completeness=geo$season_geographic_mapping_completeness,season_unknown_published_case_count=geo$season_unknown_published_case_count,season_unknown_published_case_share=geo$season_unknown_published_case_count/geo$season_total_published_case_count,cumulative_rate_status="not_published_denominator_policy_not_defined")
  if(eligible!="supported_with_caveats") abort_c18("Season is not territorially eligible.")
  pbase <- joined |> dplyr::filter(mapping_status%in%mapped_status) |> dplyr::group_by(season_week_index,source_year,source_week,reference_province_id,reference_province_name) |> dplyr::summarise(published_row_count=dplyr::n(),published_case_count=sum(source_case_count),.groups="drop")
  ps <- pbase |> dplyr::group_by(reference_province_id,reference_province_name) |> dplyr::summarise(published_row_count=sum(published_row_count),published_case_count=sum(published_case_count),.groups="drop") |> dplyr::mutate(season_indicator_schema_version="1.0.0",season_scope_id=season_snapshot$season_scope_id,season_label=season_snapshot$season_label,published_case_share_of_season_national=published_case_count/geo$season_total_published_case_count,season_geographic_mapping_completeness=geo$season_geographic_mapping_completeness,.before=1)
  rbase <- pbase |> dplyr::left_join(regions[c("reference_province_id","epidemiological_region")],by="reference_province_id")
  if(any(is.na(rbase$epidemiological_region))) abort_c18("Mapped province has no BEN region.")
  rs <- rbase |> dplyr::group_by(epidemiological_region) |> dplyr::summarise(published_row_count=sum(published_row_count),published_case_count=sum(published_case_count),.groups="drop") |> dplyr::mutate(season_indicator_schema_version="1.0.0",season_scope_id=season_snapshot$season_scope_id,season_label=season_snapshot$season_label,published_case_share_of_season_national=published_case_count/geo$season_total_published_case_count,season_geographic_mapping_completeness=geo$season_geographic_mapping_completeness,.before=1)
  years <- sort(unique(season$source_year)); scenarios <- names(config$published_count_rate$scenarios)
  policy <- tidyr::crossing(source_year=years,denominator_scenario=scenarios) |> dplyr::rowwise() |> dplyr::mutate(projection_vintage=config$published_count_rate$scenarios[[denominator_scenario]][[as.character(source_year)]]) |> dplyr::ungroup()
  if(any(is.na(policy$projection_vintage))) abort_c18("Missing scenario policy.")
  components <- regions |> dplyr::count(epidemiological_region,name="region_total_province_count")
  if(nrow(regions)!=24L || anyDuplicated(regions$reference_province_id) || nrow(components)!=5L) abort_c18("Invalid BEN reference partition.")
  lookup <- policy |> dplyr::left_join(dplyr::filter(population,geography_level=="province"),by=c("source_year"="population_year","projection_vintage")) |> dplyr::left_join(regions[c("reference_province_id","epidemiological_region")],by=c("province_reference_id"="reference_province_id")) |> dplyr::group_by(source_year,denominator_scenario,projection_vintage,epidemiological_region) |> dplyr::summarise(regional_population=sum(population),population_reference_date=dplyr::first(reference_date),component_province_count=dplyr::n(),.groups="drop") |> dplyr::left_join(components,by="epidemiological_region")
  if(nrow(lookup)!=nrow(policy)*nrow(components) || any(lookup$component_province_count!=lookup$region_total_province_count) || any(lookup$regional_population<=0)) abort_c18("Regional population lookup validation failed.")
  make_weekly <- function(scenario) {
    pol <- dplyr::filter(policy,denominator_scenario==scenario)
    nn <- nw |> dplyr::inner_join(pol,by="source_year") |> dplyr::left_join(dplyr::filter(population,geography_level=="national"),by=c("source_year"="population_year","projection_vintage"))
    if(any(is.na(nn$population)|nn$population<=0)) abort_c18("National denominator missing.")
    nout <- nn |> dplyr::transmute(season_indicator_schema_version="1.0.0",season_scope_id=season_snapshot$season_scope_id,season_label=season_snapshot$season_label,season_week_index,source_year,source_week,denominator_scenario=scenario,projection_vintage,population_reference_date=reference_date,published_row_count,published_case_count,mapped_published_case_count,unknown_published_case_count,nonassignable_published_case_count,geographic_mapping_completeness,national_population=population,published_count_rate_100k=rate_c18(published_case_count,national_population))
    pp <- pbase |> dplyr::inner_join(pol,by="source_year") |> dplyr::left_join(dplyr::filter(population,geography_level=="province"),by=c("source_year"="population_year","projection_vintage","reference_province_id"="province_reference_id"))
    pout <- pp |> dplyr::transmute(season_indicator_schema_version="1.0.0",season_scope_id=season_snapshot$season_scope_id,season_label=season_snapshot$season_label,season_week_index,source_year,source_week,denominator_scenario=scenario,projection_vintage,population_reference_date=reference_date,reference_province_id,reference_province_name,published_row_count,published_case_count,province_population=population,published_count_rate_100k=rate_c18(published_case_count,province_population))
    rb <- rbase |> dplyr::group_by(season_week_index,source_year,source_week,epidemiological_region) |> dplyr::summarise(published_row_count=sum(published_row_count),published_case_count=sum(published_case_count),region_observed_province_count=dplyr::n_distinct(reference_province_id),.groups="drop") |> dplyr::left_join(lookup |> dplyr::filter(denominator_scenario==scenario),by=c("source_year","epidemiological_region")) |> dplyr::mutate(region_observed_province_fraction=region_observed_province_count/region_total_province_count)
    rout <- rb |> dplyr::transmute(season_indicator_schema_version="1.0.0",season_scope_id=season_snapshot$season_scope_id,season_label=season_snapshot$season_label,season_week_index,source_year,source_week,denominator_scenario=scenario,projection_vintage,population_reference_date,epidemiological_region,published_row_count,published_case_count,regional_population,published_count_rate_100k=rate_c18(published_case_count,regional_population),region_total_province_count,region_observed_province_count,region_observed_province_fraction)
    list(n=nout,p=pout,r=rout)
  }
  w <- lapply(scenarios,make_weekly)
  out <- list(season_national_summary=ns,season_weekly_national=dplyr::bind_rows(lapply(w,function(x) x$n)),season_province_summary=ps,season_weekly_province=dplyr::bind_rows(lapply(w,function(x) x$p)),season_region_summary=rs,season_weekly_region=dplyr::bind_rows(lapply(w,function(x) x$r)),season_geographic_validation_snapshot=geo)
  if(sum(ps$published_case_count)!=geo$season_mapped_published_case_count || sum(rs$published_case_count)!=sum(ps$published_case_count) || any(!is.finite(out$season_weekly_region$published_count_rate_100k)) || any(out$season_weekly_region$region_observed_province_fraction<0|out$season_weekly_region$region_observed_province_fraction>1)) abort_c18("C.18 reconciliation failed.")
  paths <- c(season_national_summary=a$season_national_summary,season_weekly_national=a$season_weekly_national,season_province_summary=a$season_province_summary,season_weekly_province=a$season_weekly_province,season_region_summary=a$season_region_summary,season_weekly_region=a$season_weekly_region,season_geographic_validation_snapshot=a$season_geographic_validation_snapshot)
  for(n in names(out)) publish_c18(out[[n]],paths[[n]])
}
if(sys.nframe()==0L) main()
