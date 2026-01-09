# Full-text retrieval and PDF processing functions
# Related: R/openalex_api.R, R/pubmed_api.R

library(httr)
library(jsonlite)
library(pdftools)
library(dplyr)

#' Get Open Access status for DOIs from OpenAlex
#'
#' @param dois Character vector of DOIs
#' @param email Email for OpenAlex polite pool
#' @param delay Delay between requests in seconds
#' @return Data frame with DOI, OA status, and PDF URLs
#' @seealso \code{\link{download_oa_pdfs}}, \code{\link{extract_pdf_text}}
get_oa_status <- function(dois, email = NULL, delay = 0.1) {
  results <- list()

  for (i in seq_along(dois)) {
    doi <- dois[i]

    url <- paste0("https://api.openalex.org/works/https://doi.org/", doi)
    if (!is.null(email)) {
      url <- paste0(url, "?mailto=", email)
    }

    resp <- tryCatch({
      GET(url)
    }, error = function(e) {
      message("Error fetching DOI ", doi, ": ", e$message)
      return(NULL)
    })

    if (is.null(resp) || status_code(resp) != 200) {
      results[[doi]] <- list(
        doi = doi,
        found = FALSE,
        is_oa = FALSE,
        oa_status = "not_found",
        oa_url = NA_character_
      )
    } else {
      data <- fromJSON(content(resp, "text", encoding = "UTF-8"), simplifyVector = FALSE)
      results[[doi]] <- list(
        doi = doi,
        found = TRUE,
        is_oa = isTRUE(data$open_access$is_oa),
        oa_status = ifelse(is.null(data$open_access$oa_status), "unknown", data$open_access$oa_status),
        oa_url = ifelse(is.null(data$open_access$oa_url), NA_character_, data$open_access$oa_url)
      )
    }

    if (i %% 50 == 0) message("Processed ", i, " / ", length(dois))
    Sys.sleep(delay)
  }

  bind_rows(results)
}


#' Download Open Access PDFs
#'
#' @param oa_df Data frame with doi and oa_url columns (from get_oa_status)
#' @param output_dir Directory to save PDFs
#' @param delay Delay between downloads in seconds
#' @return Data frame with download status
#' @seealso \code{\link{get_oa_status}}, \code{\link{extract_pdf_text}}
download_oa_pdfs <- function(oa_df, output_dir = "data/fulltext/pdfs", delay = 1) {

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Filter to OA articles with URLs
  to_download <- oa_df %>%
    filter(is_oa == TRUE, !is.na(oa_url))

  message("Downloading ", nrow(to_download), " PDFs...")

  results <- list()

  for (i in seq_len(nrow(to_download))) {
    row <- to_download[i, ]
    doi <- row$doi
    url <- row$oa_url

    # Create safe filename from DOI
    safe_name <- gsub("[^A-Za-z0-9]", "_", doi)
    filepath <- file.path(output_dir, paste0(safe_name, ".pdf"))

    # Skip if already downloaded
    if (file.exists(filepath)) {
      results[[doi]] <- list(
        doi = doi,
        downloaded = TRUE,
        filepath = filepath,
        status = "exists"
      )
      next
    }

    # Download PDF
    resp <- tryCatch({
      GET(url, write_disk(filepath, overwrite = TRUE), timeout(60))
    }, error = function(e) {
      message("Error downloading ", doi, ": ", e$message)
      return(NULL)
    })

    if (is.null(resp)) {
      results[[doi]] <- list(doi = doi, downloaded = FALSE, filepath = NA, status = "error")
    } else if (status_code(resp) == 200) {
      # Verify it's actually a PDF
      if (file.exists(filepath) && file.size(filepath) > 1000) {
        results[[doi]] <- list(doi = doi, downloaded = TRUE, filepath = filepath, status = "success")
      } else {
        file.remove(filepath)
        results[[doi]] <- list(doi = doi, downloaded = FALSE, filepath = NA, status = "invalid_file")
      }
    } else {
      if (file.exists(filepath)) file.remove(filepath)
      results[[doi]] <- list(doi = doi, downloaded = FALSE, filepath = NA, status = paste0("http_", status_code(resp)))
    }

    if (i %% 10 == 0) message("Downloaded ", i, " / ", nrow(to_download))
    Sys.sleep(delay)
  }

  bind_rows(results)
}


#' Extract text from PDF files
#'
#' @param pdf_paths Character vector of PDF file paths
#' @param max_pages Maximum pages to extract (NULL for all)
#' @return Data frame with filepath and extracted text
#' @seealso \code{\link{download_oa_pdfs}}, \code{\link{get_oa_status}}
extract_pdf_text <- function(pdf_paths, max_pages = NULL) {

  results <- list()

  for (i in seq_along(pdf_paths)) {
    filepath <- pdf_paths[i]

    if (!file.exists(filepath)) {
      results[[i]] <- list(
        filepath = filepath,
        success = FALSE,
        text = NA_character_,
        pages = 0,
        error = "file_not_found"
      )
      next
    }

    text <- tryCatch({
      pages <- pdf_text(filepath)
      if (!is.null(max_pages) && length(pages) > max_pages) {
        pages <- pages[1:max_pages]
      }
      paste(pages, collapse = "\n\n")
    }, error = function(e) {
      NA_character_
    })

    if (is.na(text)) {
      results[[i]] <- list(
        filepath = filepath,
        success = FALSE,
        text = NA_character_,
        pages = 0,
        error = "extraction_failed"
      )
    } else {
      results[[i]] <- list(
        filepath = filepath,
        success = TRUE,
        text = text,
        pages = length(pdf_text(filepath)),
        error = NA_character_
      )
    }

    if (i %% 10 == 0) message("Extracted ", i, " / ", length(pdf_paths))
  }

  bind_rows(results)
}


#' Clean extracted PDF text
#'
#' @param text Character string of PDF text
#' @return Cleaned text
#' @seealso \code{\link{extract_pdf_text}}
clean_pdf_text <- function(text) {
  if (is.na(text) || is.null(text)) return(NA_character_)

  # Remove excessive whitespace
  text <- gsub("[ \\t]+", " ", text)

  # Normalize line breaks
  text <- gsub("\\r\\n", "\n", text)
  text <- gsub("\\n{3,}", "\n\n", text)

  # Remove page numbers (common patterns)
  text <- gsub("\\n\\s*\\d+\\s*\\n", "\n", text)

  # Remove headers/footers that repeat
  # (Simple heuristic - can be improved)


  trimws(text)
}


#' Get full text for articles (complete pipeline)
#'
#' @param dois Character vector of DOIs
#' @param output_dir Directory for PDFs
#' @param email Email for OpenAlex
#' @return Data frame with DOI and full text
#' @seealso \code{\link{get_oa_status}}, \code{\link{download_oa_pdfs}}, \code{\link{extract_pdf_text}}
get_fulltext <- function(dois, output_dir = "data/fulltext/pdfs", email = NULL) {

  message("Step 1: Checking OA status...")
  oa_status <- get_oa_status(dois, email = email)

  oa_available <- oa_status %>% filter(is_oa == TRUE, !is.na(oa_url))
  message("Found ", nrow(oa_available), " OA articles with PDF URLs")

  message("\nStep 2: Downloading PDFs...")
  downloads <- download_oa_pdfs(oa_status, output_dir = output_dir)

  successful <- downloads %>% filter(downloaded == TRUE)
  message("Downloaded ", nrow(successful), " PDFs")

  message("\nStep 3: Extracting text...")
  extractions <- extract_pdf_text(successful$filepath)

  # Combine results
  result <- downloads %>%
    left_join(extractions, by = "filepath") %>%
    mutate(
      text_clean = sapply(text, clean_pdf_text)
    ) %>%
    select(doi, downloaded, filepath, success, pages, text = text_clean)

  message("\nComplete: ", sum(result$success, na.rm = TRUE), " full texts extracted")

  result
}
