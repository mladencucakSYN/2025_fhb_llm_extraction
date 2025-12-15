#' Gemini-based Text Extraction Functions
#'
#' Functions for extracting structured information from scientific text
#' using Google's Gemini API.


#' Extract Fusarium Study Information
#'
#' Extracts structured information about Fusarium species on cereal crops
#' from scientific abstracts using Gemini.
#'
#' @param abstract Character string with the abstract text
#' @param title Character string with the paper title (optional)
#' @param keywords Character string with keywords (optional)
#' @param model Gemini model to use (default: "gemini-2.5-flash-lite")
#' @param api_key Google API key (defaults to GOOGLE_API_KEY env var)
#' @return List with extracted information
#' @export
extract_fusarium_gemini <- function(abstract,
                                    title = "",
                                    keywords = "",
                                    model = "gemini-2.5-flash-lite",
                                    api_key = Sys.getenv("GOOGLE_API_KEY")) {

  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required. Install with: install.packages('ellmer')")
  }

  if (api_key == "") {
    stop("GOOGLE_API_KEY environment variable not set")
  }

  # Handle NA/NULL values
  title <- if (is.null(title) || is.na(title)) "" else as.character(title)
  keywords <- if (is.null(keywords) || is.na(keywords)) "" else as.character(keywords)
  abstract <- if (is.null(abstract) || is.na(abstract)) "" else as.character(abstract)

  # Combine text fields
  full_text <- paste(
    if (nchar(title) > 0) paste("Title:", title) else "",
    if (nchar(keywords) > 0) paste("Keywords:", keywords) else "",
    if (nchar(abstract) > 0) paste("Abstract:", abstract) else "",
    sep = "\n\n"
  )

  # Build extraction prompt
  prompt <- sprintf('
Extract structured information about Fusarium species on cereal crops under environmental conditions.

Text to analyze:
%s

Extract the following information:
- fusarium_species: List of Fusarium species mentioned (e.g., ["Fusarium graminearum", "F. culmorum"])
- crop: Cereal crop(s) studied (e.g., ["wheat", "barley"])
- abiotic_factors: Environmental factors studied (e.g., ["temperature", "moisture", "humidity"])
- observed_effects: Effects on crop/disease (e.g., ["yield loss", "toxin production", "disease severity"])
- agronomic_practices: Management strategies mentioned (e.g., ["fungicide application", "crop rotation"])
- modeling: true if the study involves modeling/prediction, false otherwise
- summary: Brief 1-2 sentence summary of the main findings

Return ONLY valid JSON in this exact format:
{
  "fusarium_species": [],
  "crop": [],
  "abiotic_factors": [],
  "observed_effects": [],
  "agronomic_practices": [],
  "modeling": false,
  "summary": ""
}

If any field has no information, return an empty array [] or appropriate empty value.
Do not include any text before or after the JSON.
', full_text)

  # Call Gemini API
  chat <- ellmer::chat_google_gemini(
    model = model,
    api_key = api_key
  )

  response <- chat$chat(prompt)

  # Clean response - remove markdown code fences if present
  clean_response <- response
  clean_response <- gsub("^```json\\s*", "", clean_response)
  clean_response <- gsub("^```\\s*", "", clean_response)
  clean_response <- gsub("\\s*```$", "", clean_response)
  clean_response <- trimws(clean_response)

  # Parse JSON response
  parsed <- tryCatch({
    jsonlite::fromJSON(clean_response, simplifyVector = FALSE)
  }, error = function(e) {
    warning(sprintf("Failed to parse JSON response: %s", conditionMessage(e)))
    warning(sprintf("Raw response: %s", substr(response, 1, 200)))
    list(
      fusarium_species = list(),
      crop = list(),
      abiotic_factors = list(),
      observed_effects = list(),
      agronomic_practices = list(),
      modeling = FALSE,
      summary = "Error parsing response",
      raw_response = response
    )
  })

  parsed
}


#' Extract Generic Scientific Information
#'
#' Generic extraction function for scientific abstracts.
#' Can be adapted for different research domains.
#'
#' @param text Character string with text to extract from
#' @param schema List defining what to extract (field names and descriptions)
#' @param model Gemini model to use (default: "gemini-2.0-flash-exp")
#' @param api_key Google API key (defaults to GOOGLE_API_KEY env var)
#' @return List with extracted information
#' @export
extract_generic_gemini <- function(text,
                                   schema,
                                   model = "gemini-2.0-flash-exp",
                                   api_key = Sys.getenv("GOOGLE_API_KEY")) {

  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package required")
  }

  if (api_key == "") {
    stop("GOOGLE_API_KEY environment variable not set")
  }

  # Build schema description from list
  schema_desc <- paste(
    sapply(names(schema), function(field) {
      sprintf("- %s: %s", field, schema[[field]])
    }),
    collapse = "\n"
  )

  # Build extraction prompt
  prompt <- sprintf('
Extract structured information from the following text.

Text:
%s

Extract:
%s

Return ONLY valid JSON. Do not include any text before or after the JSON.
', text, schema_desc)

  # Call Gemini API
  chat <- ellmer::chat_google_gemini(
    model = model,
    api_key = api_key
  )

  response <- chat$chat(prompt)

  # Parse JSON response
  parsed <- tryCatch({
    jsonlite::fromJSON(response, simplifyVector = FALSE)
  }, error = function(e) {
    warning(sprintf("Failed to parse JSON response: %s", conditionMessage(e)))
    list(raw_response = response, parse_error = conditionMessage(e))
  })

  parsed
}


#' Simple Gemini Chat
#'
#' Basic function to interact with Google Gemini API.
#' For general-purpose LLM interactions.
#'
#' @param message Character string with the message/prompt
#' @param model Gemini model to use (default: "gemini-2.0-flash-exp")
#' @param api_key Google API key (defaults to GOOGLE_API_KEY env var)
#' @return Character string with Gemini response
#' @export
simple_gemini <- function(message,
                         model = "gemini-2.0-flash-exp",
                         api_key = Sys.getenv("GOOGLE_API_KEY")) {

  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer package not found. Install with: install.packages('ellmer')")
  }

  if (api_key == "") {
    stop("Set GOOGLE_API_KEY environment variable")
  }

  chat <- ellmer::chat_google_gemini(
    model = model,
    api_key = api_key
  )

  response <- chat$chat(message)
  return(response)
}


#' Extract with Retry Logic
#'
#' Wrapper for Fusarium extraction with built-in retry logic for rate limits.
#' Requires retry_logic.R to be sourced first.
#'
#' @param ... Arguments passed to extract_fusarium_gemini
#' @param max_attempts Maximum retry attempts (default: 5)
#' @param base_delay Base delay in seconds (default: 2)
#' @return List with extracted information
#' @export
#' @examples
#' \dontrun{
#' # Source required functions first
#' source("R/retry_logic.R")
#' source("R/gemini_extraction.R")
#'
#' # Then use with retry
#' result <- extract_fusarium_with_retry(
#'   abstract = "Study text...",
#'   title = "Title"
#' )
#' }
extract_fusarium_with_retry <- function(...,
                                        max_attempts = 5,
                                        base_delay = 2) {

  # Check if retry logic is available
  if (!exists("retry_with_backoff")) {
    stop("retry_with_backoff() not found. Please source R/retry_logic.R first.")
  }

  retry_with_backoff({
    extract_fusarium_gemini(...)
  }, max_attempts = max_attempts, base_delay = base_delay)
}
