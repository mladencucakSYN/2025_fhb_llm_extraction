#' Batch Process Documents with Rate Limiting
#'
#' Processes documents in batches with delays to avoid API rate limits.
#' Includes progress tracking and error handling.
#'
#' @param docs Data frame of documents to process
#' @param extract_fn Extraction function that takes a single document
#' @param id_col Column name containing document IDs
#' @param batch_size Number of documents to process before delay (default: 10)
#' @param delay_seconds Seconds to wait between batches (default: 60)
#' @param verbose Print progress messages (default: TRUE)
#' @return Data frame of extraction results
#' @export
process_batch <- function(docs,
                          extract_fn,
                          id_col = "id",
                          batch_size = 10,
                          delay_seconds = 60,
                          verbose = TRUE) {

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("dplyr package required for batch processing")
  }

  n_docs <- nrow(docs)
  n_batches <- ceiling(n_docs / batch_size)

  if (verbose) {
    message(sprintf("\n=== Batch Processing ==="))
    message(sprintf("Total documents: %d", n_docs))
    message(sprintf("Batch size: %d", batch_size))
    message(sprintf("Number of batches: %d", n_batches))
    message(sprintf("Delay between batches: %d seconds", delay_seconds))
    message(sprintf("Estimated time: %.1f minutes\n",
                    (n_batches * delay_seconds) / 60))
  }

  results <- list()
  start_time <- Sys.time()

  for (batch_num in 1:n_batches) {
    batch_start_time <- Sys.time()

    # Calculate batch indices
    start_idx <- (batch_num - 1) * batch_size + 1
    end_idx <- min(batch_num * batch_size, n_docs)
    batch_docs <- docs[start_idx:end_idx, ]

    if (verbose) {
      message(sprintf("--- Batch %d/%d (docs %d-%d) ---",
                      batch_num, n_batches, start_idx, end_idx))
    }

    # Process each document in the batch
    for (i in 1:nrow(batch_docs)) {
      doc_idx <- start_idx + i - 1
      doc_id <- batch_docs[[id_col]][i]

      if (verbose) {
        message(sprintf("  [%d/%d] Processing doc: %s",
                        doc_idx, n_docs, doc_id))
      }

      # Extract with error handling
      result <- tryCatch({
        extract_fn(batch_docs[i, ])
      }, error = function(e) {
        message(sprintf("    ✗ Error: %s", conditionMessage(e)))
        NULL
      })

      # Store result with document ID
      if (!is.null(result)) {
        result[[id_col]] <- doc_id
        results[[length(results) + 1]] <- result
        if (verbose) {
          message("    ✓ Success")
        }
      }
    }

    # Wait between batches (except after last batch)
    if (batch_num < n_batches) {
      if (verbose) {
        message(sprintf("  ⏳ Waiting %d seconds before next batch...\n",
                        delay_seconds))
      }
      Sys.sleep(delay_seconds)
    }

    # Progress summary
    if (verbose) {
      elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))
      success_rate <- length(results) / doc_idx * 100
      message(sprintf("  Progress: %d/%d docs (%.1f%% success) | %.1f mins elapsed\n",
                      doc_idx, n_docs, success_rate, elapsed))
    }
  }

  # Combine results
  if (length(results) == 0) {
    warning("No successful extractions")
    return(data.frame())
  }

  combined <- dplyr::bind_rows(results)

  if (verbose) {
    total_time <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))
    message(sprintf("\n=== Batch Processing Complete ==="))
    message(sprintf("Successful extractions: %d/%d (%.1f%%)",
                    nrow(combined), n_docs, nrow(combined)/n_docs*100))
    message(sprintf("Total time: %.1f minutes", total_time))
  }

  combined
}


#' Process with Checkpointing
#'
#' Process documents with automatic checkpointing to allow resume from failures.
#' Combines batch processing with caching functionality.
#'
#' @param docs Data frame of documents to process
#' @param extract_fn Extraction function
#' @param id_col Column name containing document IDs
#' @param checkpoint_dir Directory to save checkpoints
#' @param checkpoint_every Save checkpoint every N documents (default: 50)
#' @param batch_size Batch size for processing (default: 10)
#' @param delay_seconds Delay between batches (default: 60)
#' @return Data frame of extraction results
#' @export
process_with_checkpoints <- function(docs,
                                     extract_fn,
                                     id_col = "id",
                                     checkpoint_dir = "data/cache",
                                     checkpoint_every = 50,
                                     batch_size = 10,
                                     delay_seconds = 60) {

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("dplyr package required")
  }

  # Create checkpoint directory
  dir.create(checkpoint_dir, showWarnings = FALSE, recursive = TRUE)
  checkpoint_file <- file.path(checkpoint_dir, "checkpoint.rds")

  # Load existing results if checkpoint exists
  if (file.exists(checkpoint_file)) {
    message("Found checkpoint, loading previous results...")
    previous_results <- readRDS(checkpoint_file)
    processed_ids <- previous_results[[id_col]]
    docs <- docs[!docs[[id_col]] %in% processed_ids, ]
    message(sprintf("Resuming: %d documents already processed, %d remaining",
                    length(processed_ids), nrow(docs)))
  } else {
    previous_results <- data.frame()
  }

  # Process remaining documents
  results <- list()
  doc_count <- 0

  for (batch_num in 1:ceiling(nrow(docs) / batch_size)) {
    start_idx <- (batch_num - 1) * batch_size + 1
    end_idx <- min(batch_num * batch_size, nrow(docs))
    batch_docs <- docs[start_idx:end_idx, ]

    # Process batch
    batch_results <- process_batch(
      batch_docs,
      extract_fn,
      id_col = id_col,
      batch_size = batch_size,
      delay_seconds = delay_seconds,
      verbose = TRUE
    )

    if (nrow(batch_results) > 0) {
      results[[length(results) + 1]] <- batch_results
    }

    doc_count <- doc_count + nrow(batch_docs)

    # Save checkpoint
    if (doc_count %% checkpoint_every == 0 || end_idx == nrow(docs)) {
      all_results <- dplyr::bind_rows(previous_results, dplyr::bind_rows(results))
      saveRDS(all_results, checkpoint_file)
      message(sprintf("✓ Checkpoint saved: %d total documents processed",
                      nrow(all_results)))
    }
  }

  # Return combined results
  all_results <- dplyr::bind_rows(previous_results, dplyr::bind_rows(results))
  all_results
}
