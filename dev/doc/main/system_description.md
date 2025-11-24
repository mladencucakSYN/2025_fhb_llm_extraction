# System Description

## Overview
R-based system for LLM-assisted extraction of structured information from scientific literature about Fusarium head blight research under climate change conditions.

## Architecture

### Core Components
1. **Data Layer** (`data/`)
   - Fusarium research abstracts (2,663 studies)
   - Cached extraction results
   - Processing logs

2. **Processing Engine** (`R/`)
   - `gemini_extraction.R` - LLM API interface
   - `retry_logic.R` - Exponential backoff for rate limits
   - `batch_processor.R` - Rate-limited batch processing
   - `cache_manager.R` - Result persistence
   - `utils.R` - Configuration and text preprocessing
   - `evaluation.R` - Quality metrics
   - `pubmed_api.R`, `scopus_api.R` - Literature retrieval

3. **Analysis Workflow** (`notebooks/`)
   - Section 0: Setup and API testing
   - Section 1: Data loading and preprocessing
   - Section 2: Topic modeling (LDA)
   - Section 3: Extraction schema development
   - Section 4: Production batch processing
   - Section 5: Validation and research analysis

## Extraction Schema
Extracts 9 fields per study:
- Fusarium species, crops, abiotic factors
- Mycotoxins, observed effects, agronomic practices
- Study type, modeling approach, summary

## Technical Stack
- **Language**: R ≥ 4.1
- **LLM Provider**: Google Gemini (via ellmer package)
- **Topic Modeling**: topicmodels (LDA)
- **Environment**: renv for dependency management

## Key Features
- Exponential backoff retry logic
- Automatic result caching
- Progress checkpointing
- Rate limit handling
- Error logging
