# LLM-Based Text Extraction for Fusarium Research

This R project demonstrates LLM-assisted extraction of structured information from scientific literature, specifically focused on Fusarium head blight research under climate change conditions. The project combines educational toy examples with a real research application.

## Project Status

**Last Updated**: 2025-11-03

This project has been restructured to provide:
- **Educational progression**: Simple examples → Complex research application
- **Production-ready code**: Error handling, retry logic, batch processing, caching
- **Complete workflow**: Data loading → Topic modeling → Extraction → Analysis
- **Research focus**: Fusarium species, crops, abiotic factors, and climate interactions

## Quick Start

### 1. Prerequisites
- R ≥ 4.1 (RStudio recommended)
- Google Gemini API key (free tier available)
- Git access to this repository

### 2. First-Time Setup

```r
# 1. Clone and open project
git clone <repo-url>
cd 2025_fhb_llm_extraction

# 2. Install packages
install.packages("renv")
renv::restore()

# 3. Set up API key
# Create .env file in project root:
GOOGLE_API_KEY=your_actual_key_here

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
│   ├── retry_logic.R               # Exponential backoff & error handling
│   ├── batch_processor.R           # Rate-limited batch processing
│   ├── cache_manager.R             # Save/load extraction results
│   ├── gemini_extraction.R         # Gemini API extraction functions
│   ├── extractors.R                # Legacy extraction wrappers
│   └── evaluation.R                # Metrics and visualization
│
├── notebooks/                      # Numbered analysis notebooks
│   ├── Section 0: Setup (0000-0030)
│   │   ├── 0000_setup_environment.Rmd
│   │   ├── 0005_project_structure_and_functions.Rmd
│   │   ├── 0010_test_gemini_api.Rmd
│   │   ├── 0020_toy_example_extraction.Rmd
│   │   └── 0030_error_handling_basics.Rmd
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
├── data/                           # Data files (not in git)
│   ├── fusarium/                   # Research dataset
│   ├── cache/                      # Cached extraction results
│   └── logs/                       # Processing logs
│
├── dev/                            # Development & planning
│   ├── implementation_plan.md      # Detailed restructuring plan
│   └── archive/                    # Old notebooks (superseded)
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

### Section 1: Load Research Data (20 min)
Load and prepare the Fusarium literature dataset.
- **0100**: Load 2,663 Fusarium studies
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

### 1. Error Handling
All extraction code includes:
- Exponential backoff retry (handles HTTP 429 rate limits)
- Graceful error catching (continues on single failures)
- Error logging for debugging

### 2. Caching
- Automatic caching of extraction results
- Resume from failures without re-processing
- Saves API costs and time

### 3. Batch Processing
- Rate-limited processing (configurable delays)
- Progress tracking
- Checkpointing every N documents

### 4. Production-Ready Functions
All reusable code is in `R/` directory:
```r
# Load functions in any notebook:
source("../R/gemini_extraction.R")
source("../R/retry_logic.R")
source("../R/batch_processor.R")
source("../R/cache_manager.R")
```

## Extraction Schema

The project extracts 9 fields from each study:

1. **fusarium_species** (array): F. graminearum, F. culmorum, etc.
2. **crop** (array): wheat, barley, maize, oats
3. **abiotic_factors** (array): temperature, moisture, humidity, drought
4. **mycotoxins** (array): DON, zearalenone, nivalenol
5. **observed_effects** (array): yield loss, disease severity, toxin production
6. **agronomic_practices** (array): fungicide, rotation, resistant cultivars
7. **modeling** (boolean): whether study uses predictive models
8. **study_type** (array): field, greenhouse, laboratory, modeling
9. **summary** (string): 1-2 sentence finding summary

## API Usage & Costs

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

## For Students: What to Implement

The scaffold provides a complete working example with Gemini. Your tasks:

1. **✅ Completed**: Full Gemini extraction pipeline
2. **Optional Extensions**:
   - Add OpenAI GPT extraction (`extract_with_openai()` in `R/extractors.R`)
   - Add Anthropic Claude extraction (`extract_with_anthropic()`)
   - Compare multiple LLM providers
   - Add more sophisticated evaluation metrics
   - Implement few-shot prompting examples

3. **Research Tasks**:
   - Run manual validation (notebook 0510) on 20-50 documents
   - Calculate precision/recall metrics
   - Refine extraction prompts based on errors
   - Perform full extraction on your dataset
   - Write up findings from notebook 0530

## Project History

- **Original**: Simple scaffold with toy examples, TODOs for students
- **2025-11-03 Restructuring**:
  - Added 30+ notebooks with complete workflow
  - Integrated real Fusarium research application
  - Added production-ready error handling and batch processing
  - Implemented LDA topic modeling
  - Created comprehensive analysis pipeline
  - Added detailed documentation following best practices

See `dev/implementation_plan.md` for full restructuring documentation.

## Documentation

- **Implementation Plan**: `dev/implementation_plan.md` - Detailed restructuring notes
- **Notebook Standards**: Follow patterns in `notebooks/` (describe → execute → describe outcome)
- **Function Documentation**: Roxygen2 headers in all `R/` files
- **Archive**: `dev/archive/` - Old notebooks preserved for reference

## Getting Help

1. Check the specific notebook for inline documentation
2. Review `dev/implementation_plan.md` for design decisions
3. Look at function documentation in `R/` files
4. Check archived notebooks in `dev/archive/` for alternative approaches

## Citation

If you use this project structure or code, please cite:
```
LLM-Based Text Extraction for Fusarium Research (2025)
https://github.com/your-org/2025_fhb_llm_extraction
```

## License

[Your license here]

## Contributors

- Instructor: [Your name]
- Student: [Student name]
- Claude Code: Restructuring and documentation (2025-11-03)
