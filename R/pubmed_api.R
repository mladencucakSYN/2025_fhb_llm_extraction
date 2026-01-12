#' PubMed E-utilities API Functions
#'
#' Functions for searching and fetching literature from PubMed/NCBI using E-utilities API.
#' See: https://www.ncbi.nlm.nih.gov/books/NBK25501/
#'
#' Related functions: fetch_scopus_studies() in scopus_api.R
#' Related notebooks: 0090_fetch_pubmed_data.Rmd, 0095_fetch_scopus_data.Rmd

library(httr)
library(xml2)
library(dplyr)
library(purrr)

#' Search PubMed for articles matching a query
#'
#' Uses NCBI E-utilities ESearch to find PMIDs matching search criteria.
#'
#' @param query Character string. PubMed search query (e.g., "fusarium AND wheat")
#' @param retmax Integer. Maximum number of PMIDs to return (default: 1000).
#'        Set to NULL to return all results (up to API limit).
#' @param retstart Integer. Starting position for results (default: 0).
#'        Useful for pagination through large result sets.
#' @param api_key Character string. PubMed API key (increases rate limit to 10 req/sec)
#' @param db Character string. NCBI database to search (default: "pubmed")
#'
#' @return Character vector of PMIDs with attributes: count (total matches),
#'         query_key, webenv (for batch fetching)
#'
#' @export
#' @examples
#' \dontrun{
#' # Search for Fusarium articles
#' pmids <- pubmed_search("fusarium AND wheat", retmax = 100)
#' length(pmids)
#'
#' # Paginate through results
#' batch1 <- pubmed_search("fusarium", retmax = 100, retstart = 0)
#' batch2 <- pubmed_search("fusarium", retmax = 100, retstart = 100)
#' }
pubmed_search <- function(query,
                          retmax = 1000,
                          retstart = 0,
                          api_key = Sys.getenv("PUB_MED_API_KEY"),
                          db = "pubmed") {

  base_url <- "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"

  # Build query parameters
  params <- list(
    db = db,
    term = query,
    retmax = retmax,
    retstart = retstart,
    retmode = "xml",
    usehistory = "y"  # Use history server for large queries
  )

  # Add API key if provided
  if (nchar(api_key) > 0) {
    params$api_key <- api_key
  }

  # Make request
  response <- GET(base_url, query = params)

  # Check status
  if (status_code(response) != 200) {
    stop(sprintf("PubMed search failed with status %d", status_code(response)))
  }

  # Parse XML response
  content_xml <- content(response, as = "text", encoding = "UTF-8")
  doc <- read_xml(content_xml)

  # Extract PMIDs
  pmids <- xml_find_all(doc, "//IdList/Id") %>%
    xml_text()

  # Extract query key and WebEnv for large result sets
  query_key <- xml_find_first(doc, "//QueryKey") %>% xml_text()
  webenv <- xml_find_first(doc, "//WebEnv") %>% xml_text()
  count <- xml_find_first(doc, "//Count") %>% xml_text() %>% as.integer()

  message(sprintf("Found %d articles matching query: '%s'", count, query))
  message(sprintf("Returning %d PMIDs", length(pmids)))

  # Store query_key and webenv as attributes for batch fetching
  attr(pmids, "query_key") <- query_key
  attr(pmids, "webenv") <- webenv
  attr(pmids, "count") <- count

  return(pmids)
}

#' Fetch article details from PubMed
#'
#' Uses NCBI E-utilities EFetch to retrieve full article metadata for PMIDs.
#'
#' @param pmids Character vector of PubMed IDs
#' @param api_key Character string. PubMed API key
#' @param delay Numeric. Delay between requests in seconds (default: 0.34 for 3 req/sec, 0.1 with API key)
#'
#' @return Data frame with columns: pmid, title, abstract, keywords, authors, journal,
#'         pub_year, doi, mesh_terms
#'
#' @export
#' @examples
#' \dontrun{
#' # Fetch details for specific PMIDs
#' pmids <- c("12345678", "23456789")
#' articles <- pubmed_fetch(pmids)
#' }
pubmed_fetch <- function(pmids,
                         api_key = Sys.getenv("PUB_MED_API_KEY"),
                         delay = NULL) {

  # Set default delay based on API key presence
  if (is.null(delay)) {
    delay <- if (nchar(api_key) > 0) 0.1 else 0.34  # 10 req/sec with key, 3 req/sec without
  }

  base_url <- "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"

  # Fetch in batches of 200 (EFetch limit)
  batch_size <- 200
  n_batches <- ceiling(length(pmids) / batch_size)

  message(sprintf("Fetching %d articles in %d batches...", length(pmids), n_batches))

  all_articles <- list()

  for (i in seq_len(n_batches)) {
    start_idx <- (i - 1) * batch_size + 1
    end_idx <- min(i * batch_size, length(pmids))
    batch_pmids <- pmids[start_idx:end_idx]

    message(sprintf("  Batch %d/%d: PMIDs %d-%d", i, n_batches, start_idx, end_idx))

    # Build query parameters
    params <- list(
      db = "pubmed",
      id = paste(batch_pmids, collapse = ","),
      retmode = "xml",
      rettype = "abstract"
    )

    if (nchar(api_key) > 0) {
      params$api_key <- api_key
    }

    # Make request with retry
    response <- GET(base_url, query = params)

    if (status_code(response) != 200) {
      warning(sprintf("Batch %d failed with status %d", i, status_code(response)))
      next
    }

    # Parse XML
    content_xml <- content(response, as = "text", encoding = "UTF-8")
    doc <- read_xml(content_xml)

    # Extract article data
    articles <- xml_find_all(doc, "//PubmedArticle")

    batch_results <- map_dfr(articles, function(article) {
      parse_pubmed_article(article)
    })

    all_articles[[i]] <- batch_results

    # Rate limiting
    if (i < n_batches) {
      Sys.sleep(delay)
    }
  }

  # Combine all batches
  result <- bind_rows(all_articles)
  message(sprintf("Successfully fetched %d articles", nrow(result)))

  return(result)
}

#' Parse a single PubMed article XML node
#'
#' Internal function to extract fields from PubmedArticle XML node.
#'
#' @param article xml_node. PubmedArticle XML node
#'
#' @return Named list with article metadata
#'
#' @keywords internal
parse_pubmed_article <- function(article) {

  # Helper to safely extract text
  safe_text <- function(xpath) {
    node <- xml_find_first(article, xpath)
    if (length(node) > 0 && !is.na(node)) {
      return(xml_text(node))
    }
    return(NA_character_)
  }

  # PMID
  pmid <- safe_text(".//PMID")

  # Title
  title <- safe_text(".//ArticleTitle")

  # Abstract (combine all AbstractText nodes)
  abstract_nodes <- xml_find_all(article, ".//Abstract/AbstractText")
  if (length(abstract_nodes) > 0) {
    abstract_parts <- map_chr(abstract_nodes, function(node) {
      label <- xml_attr(node, "Label")
      text <- xml_text(node)
      if (!is.na(label)) {
        return(paste0(label, ": ", text))
      }
      return(text)
    })
    abstract <- paste(abstract_parts, collapse = " ")
  } else {
    abstract <- NA_character_
  }

  # Keywords
  keyword_nodes <- xml_find_all(article, ".//KeywordList/Keyword")
  if (length(keyword_nodes) > 0) {
    keywords <- paste(xml_text(keyword_nodes), collapse = "; ")
  } else {
    keywords <- NA_character_
  }

  # Authors with affiliations
  author_nodes <- xml_find_all(article, ".//AuthorList/Author")
  if (length(author_nodes) > 0) {
    author_names <- map_chr(author_nodes, function(author) {
      last <- xml_text(xml_find_first(author, ".//LastName"))
      first <- xml_text(xml_find_first(author, ".//ForeName"))
      if (!is.na(last) && !is.na(first)) {
        return(paste(first, last))
      } else if (!is.na(last)) {
        return(last)
      }
      return(NA_character_)
    })
    authors <- paste(author_names[!is.na(author_names)], collapse = "; ")
  } else {
    authors <- NA_character_
  }

  # Affiliations (all unique)
  affil_nodes <- xml_find_all(article, ".//AffiliationInfo/Affiliation")
  if (length(affil_nodes) > 0) {
    affiliations <- paste(unique(xml_text(affil_nodes)), collapse = " | ")
  } else {
    affiliations <- NA_character_
  }

  # Extract countries from affiliations
  if (!is.na(affiliations)) {
    # Common country patterns at end of affiliation strings
    country_pattern <- paste0(
      "(USA|United States|UK|United Kingdom|China|Germany|France|Italy|",
      "Spain|Poland|Netherlands|Canada|Australia|Brazil|India|Japan|",
      "Sweden|Denmark|Norway|Finland|Belgium|Austria|Switzerland|",
      "Czech Republic|Hungary|Argentina|Mexico|South Korea|Iran|Turkey|",
      "Egypt|South Africa|New Zealand|Ireland|Portugal|Greece|Romania|",
      "Russia|Ukraine|Serbia|Croatia|Slovenia|Slovakia)\\.?$"
    )
    country_matches <- stringr::str_extract_all(
      affiliations,
      stringr::regex(country_pattern, ignore_case = TRUE)
    )[[1]]
    countries <- if (length(country_matches) > 0) {
      paste(unique(country_matches), collapse = "; ")
    } else {
      NA_character_
    }
  } else {
    countries <- NA_character_
  }

  # Journal
  journal <- safe_text(".//Journal/Title")

  # Publication year
  pub_year <- safe_text(".//PubDate/Year")
  if (is.na(pub_year)) {
    medline_date <- safe_text(".//PubDate/MedlineDate")
    if (!is.na(medline_date)) {
      pub_year <- sub("^(\\d{4}).*", "\\1", medline_date)
    }
  }

  # DOI
  doi_nodes <- xml_find_all(article, ".//ArticleIdList/ArticleId[@IdType='doi']")
  if (length(doi_nodes) > 0) {
    doi <- xml_text(doi_nodes[1])
  } else {
    doi <- NA_character_
  }

  # MeSH terms
  mesh_nodes <- xml_find_all(article, ".//MeshHeadingList/MeshHeading/DescriptorName")
  if (length(mesh_nodes) > 0) {
    mesh_terms <- paste(xml_text(mesh_nodes), collapse = "; ")
  } else {
    mesh_terms <- NA_character_
  }

  # Publication types
  pubtype_nodes <- xml_find_all(article, ".//PublicationTypeList/PublicationType")
  if (length(pubtype_nodes) > 0) {
    pub_types <- paste(xml_text(pubtype_nodes), collapse = "; ")
  } else {
    pub_types <- NA_character_
  }

  # Grant/funding info
  grant_nodes <- xml_find_all(article, ".//GrantList/Grant")
  if (length(grant_nodes) > 0) {
    grant_info <- map_chr(grant_nodes, function(g) {
      agency <- xml_text(xml_find_first(g, ".//Agency"))
      country <- xml_text(xml_find_first(g, ".//Country"))
      if (!is.na(agency)) {
        if (!is.na(country)) {
          return(paste0(agency, " (", country, ")"))
        }
        return(agency)
      }
      return(NA_character_)
    })
    grants <- paste(unique(grant_info[!is.na(grant_info)]), collapse = "; ")
  } else {
    grants <- NA_character_
  }

  # Reference count
  ref_nodes <- xml_find_all(article, ".//ReferenceList/Reference")
  ref_count <- length(ref_nodes)

  # Return as data frame row
 tibble(
    pmid = pmid,
    title = title,
    abstract = abstract,
    keywords = keywords,
    authors = authors,
    affiliations = affiliations,
    countries = countries,
    journal = journal,
    pub_year = as.integer(pub_year),
    doi = doi,
    mesh_terms = mesh_terms,
    pub_types = pub_types,
    grants = grants,
    ref_count = ref_count
  )
}

#' Fetch PubMed studies for Fusarium research
#'
#' Convenience function to search and fetch Fusarium-related articles.
#' Combines pubmed_search() and pubmed_fetch() with sensible defaults.
#'
#' @param query Character string. Search query (default: Fusarium ecophysiology query)
#' @param retmax Integer. Maximum articles to fetch (default: 1000)
#' @param api_key Character string. PubMed API key
#'
#' @return Data frame with article metadata
#'
#' @export
#' @examples
#' \dontrun{
#' # Fetch Fusarium ecophysiology articles
#' fusarium_articles <- fetch_fusarium_pubmed(retmax = 100)
#'
#' # Custom query
#' mycotoxin_articles <- fetch_fusarium_pubmed(
#'   query = "fusarium AND mycotoxin AND wheat",
#'   retmax = 500
#' )
#' }
fetch_fusarium_pubmed <- function(query = NULL,
                                   retmax = 1000,
                                   retstart = 0,
                                   api_key = Sys.getenv("PUB_MED_API_KEY")) {

  # Default Fusarium ecophysiology query
  if (is.null(query)) {
    query <- paste(
      "(fusarium OR fusarium graminearum OR fusarium head blight)",
      "AND",
      "(wheat OR barley OR maize OR cereal)",
      "AND",
      "(temperature OR water OR moisture OR humidity OR climate OR environment OR abiotic)"
    )
  }

  message("=== PubMed Fusarium Search ===")
  message(sprintf("Query: %s", query))
  message(sprintf("Max results: %d", retmax))
  message("")

  # Search
  pmids <- pubmed_search(query, retmax = retmax, retstart = retstart, api_key = api_key)

  if (length(pmids) == 0) {
    message("No articles found")
    return(tibble())
  }

  # Fetch
  articles <- pubmed_fetch(pmids, api_key = api_key)

  # Add source column
  articles$source <- "PubMed"

  # Add unique ID
  articles <- articles %>%
    mutate(id = paste0("PM_", pmid))

  return(articles)
}
