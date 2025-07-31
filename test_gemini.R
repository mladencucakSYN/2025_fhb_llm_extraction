# Test Gemini API integration

# Load environment variables
if (file.exists(".env")) {
  readRenviron(".env")
}

# Check if API key is set
api_key_set <- nchar(Sys.getenv("GOOGLE_API_KEY")) > 0
cat("Google API key is", ifelse(api_key_set, "SET", "NOT SET"), "\n")

if (api_key_set) {
  # Install ellmer if needed
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    install.packages("ellmer", repos = "https://cran.rstudio.com")
  }
  
  # Load ellmer
  library(ellmer)
  
  # Test simple Gemini function
  simple_gemini <- function(message, api_key = Sys.getenv("GOOGLE_API_KEY")) {
    if (!requireNamespace("ellmer", quietly = TRUE)) {
      stop("ellmer package not found")
    }
    
    if (api_key == "") {
      stop("Set GOOGLE_API_KEY environment variable")
    }
    
    chat <- ellmer::chat_google_gemini(
      model = "gemini-2.0-flash-exp",
      api_key = api_key
    )
    
    response <- chat$chat(message)
    return(response)
  }
  
  # Test with simple question
  cat("Testing Gemini API...\n")
  response <- simple_gemini("What is 2+2? Give a brief answer.")
  cat("Response:", response, "\n")
  
} else {
  cat("Cannot test - GOOGLE_API_KEY not set\n")
}