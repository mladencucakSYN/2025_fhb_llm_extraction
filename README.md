# LLM-Based Text Extraction for Fusarium Research

This R project implements LLM-assisted extraction of structured experimental data from Fusarium head blight (FHB) literature. The goal is to systematically extract temperature/moisture regimes, experimental settings (field vs lab vs growth chamber), pathogen species/chemotypes, crop varieties, and outcomes to enable meta-analysis of lab-to-field translation and environment × crop × pathogen interactions.

## Project Status

**Last Updated**: 2026-01-06

**Current capabilities**:
- **Multi-source literature search**: PubMed, Scopus, and OpenAlex APIs with pagination and deduplication
- **Full-text retrieval**: Open Access PDF download pipeline with validation
- **LLM extraction**: Gemini-powered structured data extraction with retry logic and caching
- **Topic modeling**: LDA-based filtering to ecophysiology-relevant studies
- **Documentation**: Quarto website with research framework and technical guides

## Quick Start

### 1. Prerequisites
- R ≥ 4.1 (RStudio recommended)
- **Google Gemini API key** (free tier available) - required for LLM extraction
- **PubMed API key** (free, optional) - increases rate limit for PubMed fetching
- **Scopus API key** (institutional access required) - for Scopus data fetching
- Git access to this repository

### 2. First-Time Setup

```r
# 1. Clone and open project
git clone <repo-url>
cd 2025_fhb_llm_extraction

# 2. Install packages
install.packages("renv")
renv::restore()

# 3. Set up API keys
# Create .env file in project root:
GOOGLE_API_KEY=your_google_key_here
PUB_MED_API_KEY=your_pubmed_key_here     # Optional but recommended
SCOPUS_API_KEY=your_scopus_key_here      # Required for Scopus fetching

# 4. Run setup notebook
# Open notebooks/0000_setup_environment.Rmd in RStudio and run
```

### 3. Quick Test

```r
# Test API connectivity
# Run: notebooks/0010_test_gemini_api.Rmd
```

## Repository Structure

```
2025_fhb_llm_extraction/
├── R/                              # Production R functions
│   ├── utils.R                     # Config, file I/O, text cleaning
│   ├── pubmed_api.R                # PubMed E-utilities API (search, fetch, pagination)
│   ├── scopus_api.R                # Scopus Search API functions
│   ├── openalex_api.R              # OpenAlex API (abstracts, OA status, metadata)
│   ├── fulltext_api.R              # PDF download and text extraction pipeline
│   ├── retry_logic.R               # Exponential backoff & error handling
│   ├── batch_processor.R           # Rate-limited batch processing
│   ├── cache_manager.R             # Save/load extraction results
│   ├── gemini_extraction.R         # Gemini API extraction functions
│   ├── extractors.R                # Legacy extraction wrappers
│   └── evaluation.R                # Metrics and visualization
│
├── scripts/                        # Standalone utility scripts
│   └── download_oa_fulltext.R      # Bulk Open Access PDF downloader
│
├── notebooks/                      # Numbered analysis notebooks
│   ├── Section 0: Setup (0000-0030)
│   │   ├── 0000_setup_environment.Rmd
│   │   ├── 0005_project_structure_and_functions.Rmd
│   │   ├── 0010_test_gemini_api.Rmd
│   │   ├── 0020_toy_example_extraction.Rmd
│   │   └── 0030_error_handling_basics.Rmd
│   │
│   ├── Data Fetching (0090-0098)
│   │   ├── 0090_fetch_pubmed_data.Rmd
│   │   ├── 0092_working_with_lists.Rmd    # List tutorial
│   │   ├── 0095_fetch_scopus_data.Rmd
│   │   ├── 0097_fetch_openalex_data.Rmd   # OpenAlex metadata & abstracts
│   │   └── 0098_fetch_fulltext.Rmd        # Full-text PDF retrieval
│   │
│   ├── Section 1: Data Loading (0100-0120)
│   │   ├── 0100_load_fusarium_data.Rmd
│   │   ├── 0110_preprocess_abstracts.Rmd
│   │   └── 0120_exploratory_analysis.Rmd
│   │
│   ├── Section 2: Topic Modeling (0200-0230)
│   │   ├── 0200_lda_first_pass.Rmd
│   │   ├── 0210_topic_interpretation.Rmd
│   │   ├── 0220_subset_ecophysiology.Rmd
│   │   └── 0230_create_test_sample.Rmd
│   │
│   ├── Section 3: Extraction Development (0300-0330)
│   │   ├── 0300_design_extraction_schema.Rmd
│   │   ├── 0310_develop_prompts.Rmd
│   │   ├── 0320_single_extraction_test.Rmd
│   │   └── 0330_handle_errors.Rmd
│   │
│   ├── Section 4: Production Processing (0400-0430)
│   │   ├── 0400_batch_processing.Rmd
│   │   ├── 0410_caching_strategy.Rmd
│   │   ├── 0420_run_full_extraction.Rmd
│   │   └── 0430_extraction_diagnostics.Rmd
│   │
│   └── Section 5: Validation & Analysis (0500-0530)
│       ├── 0500_quality_assessment.Rmd
│       ├── 0510_manual_validation.Rmd
│       ├── 0520_aggregate_results.Rmd
│       └── 0530_fusarium_analysis.Rmd
│
├── docs/                           # Documentation (Quarto site)
│   └── site/                       # Generated documentation website
│
├── data/                           # Data files (not in git)
│   ├── fusarium/                   # Research dataset
│   ├── fulltext/                   # Downloaded PDFs and extraction logs
│   ├── cache/                      # Cached extraction results
│   └── logs/                       # Processing logs
│
├── dev/                            # Development & planning
│   └── doc/main/                   # System documentation
│
├── results/                        # Output files
├── tests/                          # Unit tests (testthat)
├── .env                            # API keys (DO NOT COMMIT)
├── renv.lock                       # Package dependencies
└── README.md                       # This file
```

## Notebook Workflow

The notebooks are designed to be run sequentially:

### Section 0: Setup & Education (30 min)
Learn basic concepts with toy examples before tackling real research data.
- **0000**: Verify R environment and packages
- **0005**: Understand project structure and function loading
- **0010**: Test Gemini API connectivity
- **0020**: Compare rule-based vs. LLM extraction on simple examples
- **0030**: Implement retry logic for rate limits

### Data Fetching: Literature Search (0090-0098)

Programmatically fetch scientific literature from multiple databases:

- **0090**: Fetch from PubMed (NCBI E-utilities API)
  - Search Fusarium articles with pagination support (`retstart` parameter)
  - Free API (key optional, increases rate limit from 3 to 10 req/sec)
  - Fetch metadata: title, abstract, keywords, MeSH terms

- **0092**: Working with Lists and API Responses
  - Learn list access patterns (`$`, `[[]]`, `[]`)
  - Understand API response structures

- **0095**: Fetch from Scopus (Elsevier API)
  - Broader disciplinary coverage, conference proceedings
  - Citation counts and affiliation data
  - Requires institutional API key

- **0097**: Fetch from OpenAlex (free, open alternative)
  - No API key required (email for polite pool recommended)
  - Reconstructs abstracts from inverted index format
  - Provides Open Access status and PDF URLs
  - Useful for enriching PubMed/Scopus data with missing abstracts

- **0098**: Full-text PDF Retrieval
  - Query OpenAlex for OA status of article DOIs
  - Download Open Access PDFs with validation
  - Extract text from PDFs using `pdftools`
  - Track download status and failures

**Workflow**:
1. Run 0090 to fetch PubMed data
2. Run 0095 to fetch Scopus data (requires API key)
3. Merge and deduplicate by DOI
4. Run 0097 to enrich with OpenAlex metadata (abstracts, OA status)
5. Run 0098 to download available full-text PDFs

### Section 1: Load Research Data (20 min)
Load and prepare the Fusarium literature dataset.
- **0100**: Load literature data (from CSV or fetched data)
- **0110**: Clean and preprocess abstracts
- **0120**: Exploratory analysis of dataset

### Section 2: Topic Modeling (1-2 hours)
Use LDA to identify research themes and filter to relevant studies.
- **0200**: Run 20-topic LDA on full corpus
- **0210**: Manually label and group topics
- **0220**: Filter to ecophysiology subset
- **0230**: Create test samples (10, 50, 100 studies)

### Section 3: Develop Extraction (1-2 hours)
Design and test extraction schema and prompts.
- **0300**: Define 9-field extraction schema
- **0310**: Engineer Fusarium-specific prompts
- **0320**: Test on single document
- **0330**: Add comprehensive error handling

### Section 4: Production Processing (Several hours)
Run full-scale extraction with caching and checkpointing.
- **0400**: Batch process with rate limiting
- **0410**: Implement result caching
- **0420**: Extract from full dataset ⚠️ **(API costs!)**
- **0430**: Analyze extraction diagnostics

### Section 5: Validate & Analyze (1-2 hours)
Assess quality and perform research analysis.
- **0500**: Quality assessment framework
- **0510**: Manual validation of sample
- **0520**: Aggregate all results
- **0530**: Final research analysis and visualization

## Key Features

### 1. Multi-Source Literature Search
```r
source("R/pubmed_api.R")
source("R/scopus_api.R")
source("R/openalex_api.R")

# Search PubMed with pagination
results <- pubmed_search("fusarium AND wheat", retmax = 1000, retstart = 0)

# Fetch metadata for DOIs from OpenAlex
abstracts <- openalex_get_abstracts(dois, email = "your@email.edu")
```

### 2. Full-Text Retrieval Pipeline
```r
source("R/fulltext_api.R")

# Check Open Access status via OpenAlex
oa_status <- get_oa_status(dois, email = "your@email.edu")

# Download available PDFs (with validation)
downloads <- download_oa_pdfs(oa_status, output_dir = "data/fulltext/pdfs")

# Extract text from PDFs
texts <- extract_pdf_text(pdf_paths)
```

**Limitations**: Publisher restrictions limit programmatic PDF access. Testing shows ~20-30% success rate:
- Nature/Springer: Generally accessible
- Elsevier: Returns HTML redirects (blocked)
- MDPI: Returns 403 Forbidden
- Many publishers require institutional proxy or manual download

For comprehensive full-text, consider: (1) institutional repository access, (2) Unpaywall browser extension, (3) contacting authors directly.

### 3. Error Handling & Retry Logic
- Exponential backoff retry (handles HTTP 429 rate limits)
- Graceful error catching (continues on single failures)
- Error logging for debugging

### 4. Caching
- Automatic caching of extraction results
- Resume from failures without re-processing
- Saves API costs and time

### 5. Batch Processing
- Rate-limited processing (configurable delays)
- Progress tracking
- Checkpointing every N documents

### 6. Production-Ready Functions
All reusable code is in `R/` directory:
```r
source("R/pubmed_api.R")        # PubMed E-utilities
source("R/scopus_api.R")        # Scopus Search API
source("R/openalex_api.R")      # OpenAlex (abstracts, OA status)
source("R/fulltext_api.R")      # PDF download & text extraction
source("R/gemini_extraction.R") # LLM extraction
source("R/retry_logic.R")       # Error handling
source("R/batch_processor.R")   # Rate-limited processing
source("R/cache_manager.R")     # Result caching
```

## Research Goals

The project aims to extract experimental data enabling:
- **Lab-to-field translation analysis**: Compare effect sizes between growth chamber, greenhouse, and field studies
- **Environment × crop × pathogen interactions**: Map which combinations are well-studied vs under-studied
- **Climate risk assessment**: Identify temperature/moisture thresholds for disease development

Full-text extraction is important because detailed experimental parameters (temperature regimes, inoculation methods, cultivar names, chemotype identification) are typically in Methods sections, not abstracts.

## Extraction Schema

The project extracts 9 fields from each study:

| Field | Type | Purpose |
|-------|------|---------|
| **fusarium_species** | array | F. graminearum, F. culmorum, chemotypes (3ADON, 15ADON, NIV) |
| **crop** | array | wheat, barley, maize, oats, specific cultivars |
| **abiotic_factors** | array | temperature, moisture, humidity regimes |
| **mycotoxins** | array | DON, zearalenone, nivalenol production |
| **observed_effects** | array | yield loss, disease severity, toxin accumulation |
| **agronomic_practices** | array | fungicide, rotation, resistant cultivars |
| **modeling** | boolean | whether study uses predictive models |
| **study_type** | array | field, greenhouse, growth chamber, modeling |
| **summary** | string | 1-2 sentence finding summary |

## API Usage & Costs

### Literature APIs

| API | Key Required | Rate Limit | Notes |
|-----|--------------|------------|-------|
| **PubMed** | Optional | 3/sec (10 with key) | Free NCBI E-utilities |
| **Scopus** | Yes (institutional) | 2/sec | Elsevier institutional access |
| **OpenAlex** | No | 10/sec (polite pool) | Free, open. Provide email for faster limits |

### Gemini API (Free Tier)
- **Rate limit**: ~60 requests/min
- **Daily limit**: ~1,500 requests/day
- **Cost**: Free for moderate use
- **Recommended**: Start with 10-study samples, scale gradually

### Processing Time Estimates
- 10 studies: ~2 minutes
- 50 studies: ~10 minutes
- 100 studies: ~20 minutes
- 500 studies: ~2 hours
- 2,663 studies: ~10 hours (with conservative rate limiting)

**Tip**: Use notebooks 0400-0430 which implement proper rate limiting and caching!

## Troubleshooting

### API Key Errors
```r
# Check if key is set
Sys.getenv("GOOGLE_API_KEY")

# Reload .env file
readRenviron(".env")

# Restart R session
```

### Rate Limit Errors (HTTP 429)
- The retry logic should handle these automatically
- If persistent, increase `delay_seconds` in batch processing
- Consider reducing `batch_size`

### Package Installation Issues
```r
# Reinstall specific package
install.packages("ellmer")

# Or restore all packages
renv::restore()
```

### Notebook Errors
- Make sure to run notebooks in sequence (0000 → 0010 → 0020 → ...)
- Check that data files exist before running extraction notebooks
- Source required functions at notebook start

## Next Steps

Current research tasks:
1. **Manual validation**: Validate extraction on 20-50 documents (notebook 0510)
2. **Expand full-text**: Explore institutional access or manual download for key papers
3. **Refine prompts**: Improve extraction of specific experimental parameters
4. **Run full extraction**: Process complete dataset with caching
5. **Analysis**: Compare field vs lab studies, identify knowledge gaps

## Documentation

- **Research Framework**: `docs/research_framework.md` - Research questions and methodology guide
- **Technical Overview**: `dev/doc/main/technical_overview.md` - Architecture and file connections
- **Quarto Site**: Run `quarto preview docs/` to view documentation website
- **Function Documentation**: Roxygen2 headers in all `R/` files
