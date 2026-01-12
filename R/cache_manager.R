#' Cache Manager for Extraction Results
#'
#' Functions to save, load, and manage cached extraction results.
#' Allows resuming from failures and avoiding re-processing documents.


#' Save Extraction Result to Cache
#'
#' Saves a single extraction result to the cache directory.
#'
#' @param doc_id Document identifier
#' @param result Extraction result (list or data frame)
#' @param cache_dir Cache directory path (default: "data/cache")
#' @export
cache_extraction <- function(doc_id, result, cache_dir = "data/cache") {
  id <- as.character(doc_id)
  # Create cache directory if it doesn't exist
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Collapse list fields into strings
  result_df <- tibble::tibble(
    id = id,
    fusarium_species       = safe_text(result$fusarium_species),
    crop                   = safe_text(result$crop),
    abiotic_factors        = safe_text(result$abiotic_factors),
    observed_effects       = safe_text(result$observed_effects),
    agronomic_practices    = safe_text(result$agronomic_practices),
    modeling               = as.logical(result$modeling),
    summary                = as.character(result$summary)
  )
  
  # Create safe filename from document ID
  safe_id <- gsub("[^a-zA-Z0-9_-]", "_", as.character(doc_id))
  cache_file <- file.path(cache_dir, paste0(safe_id, ".rds"))

  # Save result
  saveRDS(result_df, cache_file)

  invisible(cache_file)
}


#' Load All Cached Extractions
#'
#' Loads all cached extraction results from the cache directory.
#'
#' @param cache_dir Cache directory path (default: "data/cache")
#' @param verbose Print progress messages (default: TRUE)
#' @return Data frame of all cached results
#' @export
load_cached_extractions <- function(cache_dir = "data/cache", verbose = TRUE) {
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("dplyr package required")
  }

  # Check if cache directory exists
  if (!dir.exists(cache_dir)) {
    if (verbose) {
      message("No cache directory found")
    }
    return(data.frame())
  }

  # Find all .rds files
  cache_files <- list.files(cache_dir,
                           pattern = "\\.rds$",
                           full.names = TRUE)

  if (length(cache_files) == 0) {
    if (verbose) {
      message("No cached results found")
    }
    return(data.frame())
  }

  if (verbose) {
    message(sprintf("Loading %d cached results...", length(cache_files)))
  }

  # Load all cached results
  results <- lapply(cache_files, function(file) {
    tryCatch({
      readRDS(file)
    }, error = function(e) {
      warning(sprintf("Failed to load %s: %s", file, conditionMessage(e)))
      NULL
    })
  })

  # Remove NULLs from failed loads
  results <- results[!sapply(results, is.null)]

  if (length(results) == 0) {
    return(data.frame())
  }

  # Combine into data frame
  combined <- dplyr::bind_rows(results)

  if (verbose) {
    message(sprintf("Loaded %d cached results", nrow(combined)))
  }

  combined
}


#' Get Uncached Documents
#'
#' Identifies which documents still need to be processed by checking
#' what's already in the cache.
#'
#' @param all_docs Data frame of all documents
#' @param id_col Column name containing document IDs
#' @param cache_dir Cache directory path (default: "data/cache")
#' @return Data frame of documents not yet cached
#' @export
get_uncached_docs <- function(all_docs,
                              id_col = "id",
                              cache_dir = "data/cache") {

  # Get list of cached IDs
  if (!dir.exists(cache_dir)) {
    return(all_docs)
  }

  cache_files <- list.files(cache_dir, pattern = "\\.rds$")

  if (length(cache_files) == 0) {
    return(all_docs)
  }

  # Extract IDs from filenames (remove .rds extension)
  cached_ids <- sub("\\.rds$", "", cache_files)

  # Convert back from safe filenames
  # This is a simple approach - may need adjustment if IDs are complex
  all_ids <- as.character(all_docs[[id_col]])
  safe_all_ids <- gsub("[^a-zA-Z0-9_-]", "_", all_ids)

  # Find uncached documents
  uncached_mask <- !safe_all_ids %in% cached_ids
  uncached_docs <- all_docs[uncached_mask, ]

  message(sprintf("Found %d uncached documents (out of %d total)",
                  nrow(uncached_docs), nrow(all_docs)))

  uncached_docs
}


#' Clear Cache
#'
#' Removes all cached extraction results.
#' Use with caution!
#'
#' @param cache_dir Cache directory path (default: "data/cache")
#' @param confirm Require confirmation (default: TRUE)
#' @export
clear_cache <- function(cache_dir = "data/cache", confirm = TRUE) {
  if (!dir.exists(cache_dir)) {
    message("No cache directory found")
    return(invisible(FALSE))
  }

  cache_files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)

  if (length(cache_files) == 0) {
    message("Cache is already empty")
    return(invisible(FALSE))
  }

  if (confirm) {
    message(sprintf("About to delete %d cached files from %s",
                    length(cache_files), cache_dir))
    response <- readline("Type 'yes' to confirm: ")
    if (tolower(response) != "yes") {
      message("Cache clearing cancelled")
      return(invisible(FALSE))
    }
  }

  # Delete cache files
  deleted <- file.remove(cache_files)
  message(sprintf("Deleted %d cache files", sum(deleted)))

  invisible(TRUE)
}


#' Get Cache Statistics
#'
#' Returns information about the current cache state.
#'
#' @param cache_dir Cache directory path (default: "data/cache")
#' @return List with cache statistics
#' @export
cache_stats <- function(cache_dir = "data/cache") {
  if (!dir.exists(cache_dir)) {
    return(list(
      exists = FALSE,
      n_files = 0,
      size_mb = 0
    ))
  }

  cache_files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)

  if (length(cache_files) == 0) {
    return(list(
      exists = TRUE,
      n_files = 0,
      size_mb = 0
    ))
  }

  # Calculate total size
  file_sizes <- file.info(cache_files)$size
  total_size_mb <- sum(file_sizes, na.rm = TRUE) / (1024^2)

  list(
    exists = TRUE,
    n_files = length(cache_files),
    size_mb = round(total_size_mb, 2),
    files = basename(cache_files)
  )
}
