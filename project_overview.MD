# LLM-Based Text Extraction Research Project (R)

## Overview
This R project focuses on using Large Language Models (LLMs) for text extraction tasks. Students will explore various approaches to extract structured information from unstructured text data using R and modern NLP techniques.

## Project Goals
- Implement LLM-based extraction pipelines in R
- Compare different extraction approaches
- Evaluate performance on various text types
- Build practical extraction tools using R

## Project Structure
```
├── data/                   # Input datasets and samples
│   ├── raw/               # Raw text data
│   └── samples/           # Sample datasets
├── R/                     # R source code
│   ├── extractors.R       # LLM extraction functions
│   ├── evaluation.R       # Performance evaluation tools
│   ├── utils.R           # Utility functions
│   └── gemini.R          # Google Gemini API integration
├── notebooks/            # R Markdown documents for experiments
│   └── 00_test_gemini_setup.Rmd  # Gemini API setup test
├── tests/               # Unit tests (testthat)
├── config/              # Configuration files
├── results/             # Output results and reports
├── .env                 # Environment variables (create this)
├── renv.lock            # Package dependency lock file
└── DESCRIPTION          # R package description
```

## Getting Started
1. Install R and RStudio
2. Install required R packages: `install.packages("ellmer")` and other dependencies
3. Set up Google Gemini API key in `.env` file: `GOOGLE_API_KEY=your_key_here`
4. Test setup with `notebooks/00_test_gemini_setup.Rmd`
5. Review sample datasets in `data/samples/`
6. Run baseline extraction examples in R Markdown notebooks
7. Implement your own extraction methods in R

## Key Components
- **Data Processing**: Text preprocessing and cleaning with stringr/tidytext
- **LLM Integration**: Google Gemini API via ellmer package
- **Extraction Logic**: Structured data extraction with dplyr/purrr
- **Evaluation**: Metrics and performance analysis with ggplot2

## API Setup
1. Get Google API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create `.env` file with `GOOGLE_API_KEY=your_actual_key`
3. Test connection with the setup notebook