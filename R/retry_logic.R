#' Retry Function with Exponential Backoff
#'
#' Executes an expression with exponential backoff retry logic.
#' Useful for handling API rate limits (HTTP 429 errors).
#'
#' @param expr Expression to evaluate
#' @param max_attempts Maximum number of retry attempts (default: 5)
#' @param base_delay Base delay in seconds (default: 1)
#' @param max_delay Maximum delay in seconds (default: 60)
#' @param on_retry Optional callback function called before each retry
#' @return Result of the expression if successful
#' @export
#' @examples
#' \dontrun{
#' # Retry an API call
#' result <- retry_with_backoff({
#'   api_call_that_might_fail()
#' })
#' }
retry_with_backoff <- function(expr,
                               max_attempts = 5,
                               base_delay = 1,
                               max_delay = 60,
                               on_retry = NULL) {

  for (attempt in 1:max_attempts) {
    result <- tryCatch({
      # Try to execute the expression
      eval(expr, envir = parent.frame())
    }, error = function(e) {
      # Return error object instead of stopping
      e
    })

    # If successful, return result
    if (!inherits(result, "error")) {
      if (attempt > 1) {
        message(sprintf("  ✓ Succeeded on attempt %d", attempt))
      }
      return(result)
    }

    # If this was the last attempt, throw the error
    if (attempt == max_attempts) {
      stop(sprintf("Failed after %d attempts. Last error: %s",
                   max_attempts, conditionMessage(result)))
    }

    # Calculate delay with exponential backoff
    delay <- min(base_delay * (2 ^ (attempt - 1)), max_delay)

    # Check if error is rate limit related
    error_msg <- conditionMessage(result)
    is_rate_limit <- grepl("429|rate limit|quota", error_msg, ignore.case = TRUE)

    # Log the retry
    message(sprintf("  ⚠ Attempt %d/%d failed: %s",
                    attempt, max_attempts,
                    substr(error_msg, 1, 100)))
    message(sprintf("  ⏳ Waiting %.1f seconds before retry...", delay))

    # Call optional callback
    if (!is.null(on_retry)) {
      on_retry(attempt, error_msg)
    }

    # Wait before retrying
    Sys.sleep(delay)
  }
}


#' Retry Wrapper for API Calls
#'
#' Wrapper specifically designed for API calls that might hit rate limits.
#' Provides sensible defaults for API retry logic.
#'
#' @param api_function Function to call
#' @param ... Arguments to pass to api_function
#' @param max_attempts Maximum retry attempts (default: 5)
#' @param base_delay Base delay in seconds (default: 2)
#' @return Result of the API function
#' @export
retry_api_call <- function(api_function, ..., max_attempts = 5, base_delay = 2) {
  retry_with_backoff({
    api_function(...)
  }, max_attempts = max_attempts, base_delay = base_delay)
}


#' Safe Extraction with Error Handling
#'
#' Wraps an extraction function with error handling and logging.
#' Returns NULL on error instead of stopping execution.
#'
#' @param extract_fn Extraction function to call
#' @param doc_id Document identifier for logging
#' @param ... Arguments to pass to extract_fn
#' @param verbose Print error messages (default: TRUE)
#' @return Extraction result or NULL on error
#' @export
safe_extract <- function(extract_fn, doc_id, ..., verbose = TRUE) {
  result <- tryCatch({
    extract_fn(...)
  }, error = function(e) {
    if (verbose) {
      message(sprintf("  ✗ Error extracting doc %s: %s",
                      doc_id, conditionMessage(e)))
    }
    NULL
  })

  result
}
