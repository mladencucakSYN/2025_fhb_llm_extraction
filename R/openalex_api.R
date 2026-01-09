#' OpenAlex API Functions
#'
#' Functions for fetching literature data from OpenAlex (free, open alternative to Scopus).
#' See: https://docs.openalex.org/
#'
#' Related functions: pubmed_api.R, scopus_api.R

library(httr)
library(jsonlite)
library(dplyr)
library(purrr)

#' Reconstruct abstract from OpenAlex inverted index
#'
#' OpenAlex stores abstracts as inverted indices for efficiency.
#' This function reconstructs the full text.
#'
#' @param inverted_index List with word-position mappings
#' @return Character string with reconstructed abstract
#' @keywords internal
reconstruct_abstract <- function(inverted_index) {
  if (is.null(inverted_index) || length(inverted_index) == 0) {
    return(NA_character_)
  }

  tryCatch({
    words <- names(inverted_index)
    all_positions <- unlist(inverted_index)
    if (length(all_positions) == 0) return(NA_character_)

    max_pos <- max(all_positions)
    abstract_vec <- character(max_pos + 1)

    for (i in seq_along(words)) {
      for (pos in inverted_index[[i]]) {
        abstract_vec[pos + 1] <- words[i]
      }
    }
    paste(abstract_vec, collapse = " ")
  }, error = function(e) {
    NA_character_
  })
}

#' Fetch article from OpenAlex by DOI
#'
#' @param doi Character string. DOI of the article
#' @param email Character string. Email for polite pool (faster rate limits)
#' @return List with article metadata or NULL if not found
#' @export
openalex_fetch_doi <- function(doi, email = "research@university.edu") {

  url <- paste0("https://api.openalex.org/works/doi:", doi)

  response <- GET(
    url,
    add_headers("User-Agent" = paste0("mailto:", email))
  )

  if (status_code(response) != 200) {
    return(NULL)
  }

  data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

  list(
    openalex_id = data$id,
    doi = doi,
    title = data$title,
    abstract = reconstruct_abstract(data$abstract_inverted_index),
    pub_year = data$publication_year,
    journal = data$primary_location$source$display_name,
    cited_by = data$cited_by_count,
    is_open_access = data$open_access$is_oa,
    authors = paste(sapply(data$authorships, function(x) x$author$display_name), collapse = "; "),
    institutions = paste(unique(unlist(sapply(data$authorships, function(x) {
      sapply(x$institutions, function(i) i$display_name)
    }))), collapse = "; "),
    countries = paste(unique(unlist(sapply(data$authorships, function(x) {
      sapply(x$institutions, function(i) i$country_code)
    }))), collapse = "; ")
  )
}

#' Search OpenAlex for articles
#'
#' @param query Character string. Search query
#' @param max_results Integer. Maximum results to return (default: 200)
#' @param email Character string. Email for polite pool
#' @return Data frame with search results
#' @export
openalex_search <- function(query,
                            max_results = 200,
                            email = "research@university.edu") {

  base_url <- "https://api.openalex.org/works"

  all_results <- list()
  cursor <- "*"
  per_page <- min(max_results, 200)
  fetched <- 0

  message(sprintf("Searching OpenAlex for: %s", query))

  while (fetched < max_results && !is.null(cursor)) {
    params <- list(
      search = query,
      per_page = per_page,
      cursor = cursor
    )

    response <- GET(
      base_url,
      query = params,
      add_headers("User-Agent" = paste0("mailto:", email))
    )

    if (status_code(response) != 200) {
      warning(sprintf("OpenAlex search failed with status %d", status_code(response)))
      break
    }

    data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

    if (length(data$results) == 0) break

    # Parse results
    batch <- map_dfr(data$results, function(work) {
      
      if (!is.list(work)) return(NULL)
      
      tibble(
        openalex_id = if (!is.null(work$id)) work$id else NA_character_,
        doi = if (!is.null(work$doi)) as.character(work$doi) else NA_character_,
        title = if (!is.null(work$title)) work$title else NA_character_,
        abstract = if (!is.null(work$abstract_inverted_index))
          reconstruct_abstract(work$abstract_inverted_index)
        else NA_character_,
        pub_year = if (!is.null(work$publication_year)) work$publication_year else NA_integer_,
        journal = if (!is.null(work$primary_location$source$display_name))
          work$primary_location$source$display_name
        else NA_character_,
        cited_by = if (!is.null(work$cited_by_count)) work$cited_by_count else NA_integer_,
        is_open_access = if (!is.null(work$open_access$is_oa))
          work$open_access$is_oa
        else NA
      )
    })

    all_results[[length(all_results) + 1]] <- batch
    fetched <- fetched + nrow(batch)

    # Get next cursor
    cursor <- data$meta$next_cursor

    message(sprintf("  Fetched %d articles...", fetched))
    Sys.sleep(0.1)  # Rate limiting
  }

  combined <- bind_rows(all_results)
  message(sprintf("Total: %d articles", nrow(combined)))

  return(combined)
}

#' Fetch Fusarium articles from OpenAlex
#'
#' @param max_results Integer. Maximum results (default: 500)
#' @param email Character string. Email for polite pool
#' @return Data frame with Fusarium research articles
#' @export
fetch_fusarium_openalex <- function(max_results = 500,
                                    email = "research@university.edu") {

  query <- "fusarium head blight wheat temperature climate"

  message("=== OpenAlex Fusarium Search ===")

  articles <- openalex_search(query, max_results = max_results, email = email)

  if (nrow(articles) > 0) {
    articles$source <- "openalex"
    articles$id <- paste0("OA_", gsub("https://openalex.org/", "", articles$openalex_id))
  }

  return(articles)
}

#' Fetch abstracts for DOIs from OpenAlex
#'
#' @param dois Character vector of DOIs
#' @param email Character string. Email for polite pool
#' @param delay Numeric. Delay between requests (default: 0.1)
#' @return Data frame with DOI and abstract
#' @export
openalex_get_abstracts <- function(dois,
                                   email = "research@university.edu",
                                   delay = 0.1) {

  message(sprintf("Fetching abstracts for %d DOIs from OpenAlex...", length(dois)))

  results <- list()

  for (i in seq_along(dois)) {
    result <- openalex_fetch_doi(dois[i], email = email)

    if (!is.null(result)) {
      results[[length(results) + 1]] <- tibble(
        doi = dois[i],
        abstract = result$abstract,
        title = result$title,
        pub_year = result$pub_year
      )
    }

    if (i %% 25 == 0) {
      message(sprintf("  Processed %d / %d", i, length(dois)))
    }

    Sys.sleep(delay)
  }

  combined <- bind_rows(results)
  message(sprintf("Found abstracts for %d / %d DOIs", sum(!is.na(combined$abstract)), length(dois)))

  return(combined)
}
