#' Load Environment Variables
#' 
#' Load API keys and configuration from .env file
#' 
#' @return Named list of environment variables
load_config <- function() {
  if (file.exists(".env")) {
    readRenviron(".env")
  }
  
  list(
    openai_api_key = Sys.getenv("OPENAI_API_KEY"),
    anthropic_api_key = Sys.getenv("ANTHROPIC_API_KEY")
  )
}

#' Clean Text
#' 
#' Basic text preprocessing for extraction tasks
#' 
#' @param text Character vector of text to clean
#' @return Cleaned text
clean_text <- function(text) {
  
  text %>%
    stringr::str_trim() %>%
    stringr::str_squish() %>%
    stringr::str_replace_all("[\\r\\n]+")
}

#' Save Results
#' 
#' Save extraction results to file
#' 
#' @param results Data frame of results
#' @param filename Output filename
#' @param format File format ("csv", "json", "rds")
save_results <- function(results, filename, format = "csv") {
  dir.create("results", showWarnings = FALSE, recursive = TRUE)
  
  filepath <- file.path("results", filename)
  
  switch(format,
    "csv" = readr::write_csv(results, filepath),
    "json" = jsonlite::write_json(results, filepath),
    "rds" = saveRDS(results, filepath)
  )
  
  message("Results saved to: ", filepath)
}