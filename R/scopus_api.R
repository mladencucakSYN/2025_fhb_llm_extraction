#' Scopus API Functions
#'
#' Functions for searching and fetching literature from Scopus/Elsevier using Scopus Search API.
#' See: https://dev.elsevier.com/documentation/ScopusSearchAPI.wadl
#'
#' Related functions: fetch_fusarium_pubmed() in pubmed_api.R
#' Related notebooks: 0090_fetch_pubmed_data.Rmd, 0095_fetch_scopus_data.Rmd

library(httr)
library(jsonlite)
library(dplyr)
library(purrr)

#' Search Scopus for articles matching a query
#'
#' Uses Scopus Search API to find articles matching search criteria.
#'
#' @param query Character string. Scopus search query (e.g., "TITLE-ABS-KEY(fusarium AND wheat)")
#' @param count Integer. Maximum number of results to return (default: 200, max: 200 per request)
#' @param api_key Character string. Scopus API key from Elsevier Developer Portal
#' @param view Character string. Response view detail level (default: "COMPLETE")
#' @param start Integer. Starting index for pagination (default: 0)
#'
#' @return List with: results (data frame), total_results (integer), query_url (character)
#'
#' @export
#' @examples
#' \dontrun{
#' # Search for Fusarium articles
#' results <- scopus_search("TITLE-ABS-KEY(fusarium AND wheat)", count = 100)
#' articles <- results$results
#' }
scopus_search <- function(query,
                          count = 200,
                          api_key = Sys.getenv("SCOPUS_API_KEY"),
                          view = "COMPLETE",
                          start = 0) {

  if (nchar(api_key) == 0) {
    stop("SCOPUS_API_KEY not found. Set it in .env file.")
  }

  base_url <- "https://api.elsevier.com/content/search/scopus"

  # Build query parameters
  params <- list(
    query = query,
    count = min(count, 200),  # Scopus max 200 per request
    start = start,
    view = view
  )

  # Make request with API key in header
  response <- GET(
    base_url,
    query = params,
    add_headers(
      "X-ELS-APIKey" = api_key,
      "Accept" = "application/json"
    )
  )

  # Check status
  if (status_code(response) == 401) {
    stop("Scopus API authentication failed. Check SCOPUS_API_KEY.")
  }

  if (status_code(response) == 429) {
    stop("Scopus API rate limit exceeded. Wait before retrying.")
  }

  if (status_code(response) != 200) {
    stop(sprintf("Scopus search failed with status %d: %s",
                 status_code(response),
                 content(response, as = "text")))
  }

  # Parse JSON response
  content_json <- content(response, as = "text", encoding = "UTF-8")
  data <- fromJSON(content_json, flatten = TRUE)

  # Extract search results
  search_results <- data$`search-results`

  # Total results
  total_results <- as.integer(search_results$`opensearch:totalResults`)

  message(sprintf("Found %d articles matching query", total_results))
  message(sprintf("Returning %d articles (start: %d)", count, start))

  # Extract entries
  entries <- search_results$entry

  if (is.null(entries) || nrow(entries) == 0) {
    message("No articles found")
    return(list(
      results = tibble(),
      total_results = 0,
      query_url = response$url
    ))
  }

  # Parse entries into clean data frame
  articles <- parse_scopus_entries(entries)

  return(list(
    results = articles,
    total_results = total_results,
    query_url = response$url
  ))
}

#' Parse Scopus API entries into data frame
#'
#' Internal function to clean and structure Scopus search results.
#'
#' @param entries Data frame. Raw entries from Scopus API response
#'
#' @return Data frame with standardized columns
#'
#' @keywords internal
parse_scopus_entries <- function(entries) {

  # Helper to safely extract field
  safe_extract <- function(field) {
    if (field %in% names(entries)) {
      return(entries[[field]])
    }
    return(NA_character_)
  }

  # Build standardized data frame
  articles <- tibble(
    scopus_id = safe_extract("dc:identifier"),
    id = safe_extract("eid"),
    doi = safe_extract("prism:doi"),
    title = safe_extract("dc:title"),
    abstract = safe_extract("dc:description"),
    authors = safe_extract("dc:creator"),
    pub_year = as.integer(safe_extract("prism:coverDate") %>%
                            substr(1, 4)),
    journal = safe_extract("prism:publicationName"),
    volume = safe_extract("prism:volume"),
    issue = safe_extract("prism:issueIdentifier"),
    pages = safe_extract("prism:pageRange"),
    cited_by = as.integer(safe_extract("citedby-count")),
    affiliation = safe_extract("affiliation.affilname"),
    keywords = safe_extract("authkeywords"),
    source_type = safe_extract("prism:aggregationType"),
    pubmed_id = safe_extract("pubmed-id")
  )

  # Clean scopus_id to remove "SCOPUS_ID:" prefix
  articles$scopus_id <- sub("SCOPUS_ID:", "", articles$scopus_id)

  return(articles)
}

#' Fetch multiple pages of Scopus results
#'
#' Handles pagination to fetch more than 200 results from Scopus.
#'
#' @param query Character string. Scopus search query
#' @param max_results Integer. Maximum total results to fetch (default: 1000)
#' @param api_key Character string. Scopus API key
#' @param delay Numeric. Delay between requests in seconds (default: 1)
#'
#' @return Data frame with all fetched articles
#'
#' @export
#' @examples
#' \dontrun{
#' # Fetch up to 500 Fusarium articles
#' articles <- scopus_search_all(
#'   "TITLE-ABS-KEY(fusarium AND wheat)",
#'   max_results = 500
#' )
#' }
scopus_search_all <- function(query,
                              max_results = 1000,
                              api_key = Sys.getenv("SCOPUS_API_KEY"),
                              delay = 1) {

  all_articles <- list()
  current_start <- 0
  count_per_request <- 25  # Scopus maximum

  # Calculate number of requests needed
  n_requests <- ceiling(max_results / count_per_request)

  message(sprintf("Fetching up to %d articles in %d requests...", max_results, n_requests))

  for (i in seq_len(n_requests)) {
    message(sprintf("  Request %d/%d (start: %d)", i, n_requests, current_start))

    # Make request
    result <- scopus_search(
      query = query,
      count = count_per_request,
      api_key = api_key,
      start = current_start
    )

    # Store results
    if (nrow(result$results) > 0) {
      all_articles[[i]] <- result$results
    }

    # Check if we've fetched all available results
    if (current_start + nrow(result$results) >= result$total_results) {
      message("Fetched all available results")
      break
    }

    # Update start for next request
    current_start <- current_start + count_per_request

    # Rate limiting
    if (i < n_requests) {
      Sys.sleep(delay)
    }
  }

  # Combine all results
  combined <- bind_rows(all_articles)
  message(sprintf("Successfully fetched %d articles", nrow(combined)))

  return(combined)
}

#' Fetch Scopus studies for Fusarium research
#'
#' Convenience function to search Scopus for Fusarium-related articles.
#' Constructs appropriate Scopus query syntax and handles pagination.
#'
#' @param query Character string. Search terms (default: Fusarium ecophysiology terms)
#' @param max_results Integer. Maximum articles to fetch (default: 1000)
#' @param api_key Character string. Scopus API key
#'
#' @return Data frame with article metadata
#'
#' @export
#' @examples
#' \dontrun{
#' # Fetch Fusarium ecophysiology articles
#' fusarium_articles <- fetch_fusarium_scopus(max_results = 500)
#'
#' # Custom query
#' mycotoxin_articles <- fetch_fusarium_scopus(
#'   query = "fusarium AND mycotoxin AND wheat",
#'   max_results = 200
#' )
#' }
fetch_fusarium_scopus <- function(query = NULL,
                                  max_results = 1000,
                                  api_key = Sys.getenv("SCOPUS_API_KEY")) {

  # Default Fusarium ecophysiology query
  if (is.null(query)) {
    query_terms <- paste(
      "(fusarium OR \"fusarium graminearum\" OR \"fusarium head blight\")",
      "AND",
      "(wheat OR barley OR maize OR cereal)",
      "AND",
      "(temperature OR water OR moisture OR humidity OR climate OR environment OR abiotic)"
    )
    # Wrap in Scopus TITLE-ABS-KEY syntax
    query <- paste0("TITLE-ABS-KEY(", query_terms, ")")
  } else {
    # If query doesn't have Scopus syntax, add it
    if (!grepl("^(TITLE|ABS|KEY|AUTH|AFFIL|ALL)", query)) {
      query <- paste0("TITLE-ABS-KEY(", query, ")")
    }
  }

  message("=== Scopus Fusarium Search ===")
  message(sprintf("Query: %s", query))
  message(sprintf("Max results: %d", max_results))
  message("")

  # Search with pagination
  articles <- scopus_search_all(
    query = query,
    max_results = max_results,
    api_key = api_key
  )

  if (nrow(articles) == 0) {
    message("No articles found")
    return(tibble())
  }

  # Add source column
  articles$source <- "Scopus"

  # Add unique ID (use scopus_id or eid)
  articles <- articles %>%
    mutate(id = coalesce(scopus_id, eid))

  return(articles)
}

#' Get abstract text from Scopus Abstract Retrieval API
#'
#' Fetches full abstract text for articles where it's truncated in search results.
#' Note: Requires additional API quota.
#'
#' @param scopus_id Character string or vector. Scopus ID(s)
#' @param api_key Character string. Scopus API key
#' @param delay Numeric. Delay between requests in seconds (default: 1)
#'
#' @return Data frame with scopus_id and full_abstract columns
#'
#' @export
#' @examples
#' \dontrun{
#' # Get full abstracts
#' abstracts <- scopus_get_abstracts(c("85012345678", "85012345679"))
#' }
scopus_get_abstracts <- function(scopus_id,
                                 api_key = Sys.getenv("SCOPUS_API_KEY"),
                                 delay = 1) {

  if (nchar(api_key) == 0) {
    stop("SCOPUS_API_KEY not found. Set it in .env file.")
  }

  message(sprintf("Fetching full abstracts for %d articles...", length(scopus_id)))

  # Fetch each abstract
  results <- map_dfr(scopus_id, function(id) {
    # Remove SCOPUS_ID: prefix if present
    clean_id <- sub("SCOPUS_ID:", "", id)

    url <- sprintf("https://api.elsevier.com/content/abstract/scopus_id/%s", clean_id)

    response <- GET(
      url,
      add_headers(
        "X-ELS-APIKey" = api_key,
        "Accept" = "application/json"
      )
    )

    if (status_code(response) != 200) {
      warning(sprintf("Failed to fetch abstract for %s", id))
      return(tibble(scopus_id = id, full_abstract = NA_character_))
    }

    # Parse response
    content_json <- content(response, as = "text", encoding = "UTF-8")
    data <- fromJSON(content_json, flatten = TRUE)

    # Extract abstract
    abstract <- data$`abstracts-retrieval-response`$coredata$`dc:description`

    Sys.sleep(delay)

    return(tibble(
      scopus_id = id,
      full_abstract = abstract
    ))
  })

  message(sprintf("Successfully fetched %d abstracts", sum(!is.na(results$full_abstract))))

  return(results)
}
