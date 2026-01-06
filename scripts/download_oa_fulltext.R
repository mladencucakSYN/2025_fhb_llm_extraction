#!/usr/bin/env Rscript
# Download Open Access full-text PDFs
# Usage: Rscript scripts/download_oa_fulltext.R [--sample N] [--all]
#
# Related: R/fulltext_api.R, notebooks/0098_fetch_fulltext.Rmd

library(dplyr)
source("R/fulltext_api.R")

# Configuration
DATA_DIR <- "data/fusarium"
PDF_DIR <- "data/fulltext/pdfs"
OA_STATUS_FILE <- file.path(DATA_DIR, "our_articles_oa_status.rds")
DOWNLOAD_LOG_FILE <- file.path("data/fulltext", "download_log.rds")

# Parse command line args
args <- commandArgs(trailingOnly = TRUE)
sample_size <- NULL
download_all <- FALSE

if ("--all" %in% args) {
  download_all <- TRUE
} else if ("--sample" %in% args) {
  idx <- which(args == "--sample")
  if (length(args) > idx) {
    sample_size <- as.integer(args[idx + 1])
  }
}

# Default to sample of 5 if no args
if (is.null(sample_size) && !download_all) {
  sample_size <- 5
}

cat("=== Open Access PDF Downloader ===\n\n")

# Load OA status
if (!file.exists(OA_STATUS_FILE)) {
  stop("OA status file not found. Run notebook 0098_fetch_fulltext.Rmd first.")
}

oa_status <- readRDS(OA_STATUS_FILE)
cat("Loaded OA status for", nrow(oa_status), "articles\n")

# Filter to OA with URLs
oa_available <- oa_status %>%
  filter(is_oa == TRUE, !is.na(oa_url))

cat("Open Access with PDF URLs:", nrow(oa_available), "\n\n")

# Select articles to download
if (download_all) {
  to_download <- oa_available
  cat("Mode: Download ALL\n")
} else {
  to_download <- oa_available %>% head(sample_size)
  cat("Mode: Sample of", sample_size, "\n")
}

cat("Articles to download:", nrow(to_download), "\n\n")

# Check already downloaded
existing <- list.files(PDF_DIR, pattern = "\\.pdf$")
cat("Already downloaded:", length(existing), "PDFs\n\n")

# Download
cat("Starting downloads...\n")
cat(rep("-", 50), "\n", sep = "")

results <- download_oa_pdfs(
  oa_df = to_download,
  output_dir = PDF_DIR,
  delay = 1.5  # Be polite to publishers
)

cat(rep("-", 50), "\n", sep = "")

# Summary
cat("\n=== Download Summary ===\n")
cat("Total attempted:", nrow(results), "\n")
cat("Successful:", sum(results$status == "success"), "\n")
cat("Already existed:", sum(results$status == "exists"), "\n")
cat("Failed:", sum(!results$status %in% c("success", "exists")), "\n")

# Show failures if any
failures <- results %>% filter(!status %in% c("success", "exists"))
if (nrow(failures) > 0) {
  cat("\nFailed downloads:\n")
  for (i in seq_len(nrow(failures))) {
    cat("  ", failures$doi[i], " - ", failures$status[i], "\n")
  }
}

# Save log
if (file.exists(DOWNLOAD_LOG_FILE)) {
  old_log <- readRDS(DOWNLOAD_LOG_FILE)
  results <- bind_rows(old_log, results) %>%
    group_by(doi) %>%
    slice_tail(n = 1) %>%
    ungroup()
}
saveRDS(results, DOWNLOAD_LOG_FILE)
cat("\nLog saved to:", DOWNLOAD_LOG_FILE, "\n")

# Final stats
pdf_files <- list.files(PDF_DIR, pattern = "\\.pdf$", full.names = TRUE)
total_size_mb <- sum(file.size(pdf_files)) / 1024 / 1024
cat("\nTotal PDFs in directory:", length(pdf_files), "\n")
cat("Total size:", round(total_size_mb, 1), "MB\n")
