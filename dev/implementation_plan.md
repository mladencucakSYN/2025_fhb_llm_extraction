# Notebook Restructuring Implementation Plan

## Date
2025-11-03

## Overview
Restructuring the LLM extraction project to combine original educational vision with student's real Fusarium head blight research. Creating a complete, reproducible notebook sequence that teaches concepts while solving the student's research problem.

## Context

### Original Vision
- Educational R project teaching LLM text extraction basics
- Simple toy examples (name/email extraction)
- Comparison of rule-based vs. LLM extraction methods
- Three planned LLM integrations: Gemini (working), OpenAI (TODO), Anthropic (TODO)
- Emphasis on reproducibility and evaluation metrics

### Student's Work
The student attempted a complex real research project:
- **Dataset**: 2,663 Fusarium head blight studies (after deduplication from 3,805)
- **LDA Topic Modeling**:
  - First pass: 20 topics from abstracts/keywords
  - Grouped into 5 macro-themes
  - Focused on "Ecophysiology & Abiotic Responses" theme
  - Second pass: Subset to topics 2,5,8,10,11,12,13,19
- **Extraction Goal**: Complex scientific data
  - Fusarium species
  - Crop hosts
  - Abiotic factors (temperature, moisture, etc.)
  - Observed effects
  - Agronomic practices
  - Modeling approaches
- **Challenge**: HTTP 429 rate limit errors on all test cases
- **Status**: Blocked - no successful extractions achieved

### Restructuring Goals
1. **Hybrid Approach**: Start with simple educational examples, build to Fusarium complexity
2. **Integrate LDA**: Make topic modeling part of the standard workflow for large datasets
3. **Focus on Gemini**: Implement robust error handling (retry logic, batching, caching)
4. **Priority**: Help student complete their research
5. **Pedagogy**: Notebooks must be informative for beginner R students

## Notebook Structure

### Section 0: Setup & Educational Foundation (0000-0030)
**Purpose**: Verify environment, teach basic concepts with simple examples

| Notebook | Description | Status |
|----------|-------------|--------|
| `0000_setup_environment.Rmd` | Install packages, verify API keys, check R environment | To create |
| `0010_test_gemini_api.Rmd` | Verify Gemini API connectivity (adapt existing) | To adapt |
| `0020_toy_example_extraction.Rmd` | Simple email/name extraction teaching concepts | To create |
| `0030_error_handling_basics.Rmd` | Introduce retry logic with toy examples | To create |

**Learning Outcomes**: Student understands API basics, simple extraction, error handling concepts

### Section 1: Research Data Preparation (0100-0120)
**Purpose**: Load and explore the real Fusarium dataset

| Notebook | Description | Status |
|----------|-------------|--------|
| `0100_load_fusarium_data.Rmd` | Load 2,663 studies, explore structure | To create |
| `0110_preprocess_abstracts.Rmd` | Clean text, combine title+abstract+keywords | To create |
| `0120_exploratory_analysis.Rmd` | Basic stats, text characteristics | To create |

**Learning Outcomes**: Student can load and prepare real research data

### Section 2: Topic Modeling for Data Reduction (0200-0230)
**Purpose**: Use LDA to filter large dataset to manageable, relevant subset

| Notebook | Description | Status |
|----------|-------------|--------|
| `0200_lda_first_pass.Rmd` | 20-topic LDA on full corpus | To create |
| `0210_topic_interpretation.Rmd` | Manual labeling, macro-theme grouping | To create |
| `0220_subset_ecophysiology.Rmd` | Filter to topics 2,5,8,10,11,12,13,19 | To create |
| `0230_create_test_sample.Rmd` | Sample 50-100 studies for testing | To create |

**Learning Outcomes**: Student understands how to reduce large datasets, identify relevant subsets

### Section 3: LLM Extraction Development (0300-0330)
**Purpose**: Develop and test extraction prompts and single-document processing

| Notebook | Description | Status |
|----------|-------------|--------|
| `0300_design_extraction_schema.Rmd` | Define fields to extract, data structure | To create |
| `0310_develop_prompts.Rmd` | Build Fusarium-specific prompts, test on 5 examples | To create |
| `0320_single_extraction_test.Rmd` | Extract from 1 study, validate JSON parsing | To create |
| `0330_handle_errors.Rmd` | Implement exponential backoff, error logging | To create |

**Learning Outcomes**: Student can design extraction schemas, engineer prompts, handle API errors

### Section 4: Production-Scale Processing (0400-0430)
**Purpose**: Scale from single document to entire dataset with robust error handling

| Notebook | Description | Status |
|----------|-------------|--------|
| `0400_batch_processing.Rmd` | Process in chunks with rate limit delays | To create |
| `0410_caching_strategy.Rmd` | Save/resume from partial results | To create |
| `0420_run_full_extraction.Rmd` | Process all studies with progress tracking | To create |
| `0430_extraction_diagnostics.Rmd` | Analyze failures, retry failed cases | To create |

**Learning Outcomes**: Student can handle production-scale extraction with thousands of documents

### Section 5: Validation & Research Analysis (0500-0530)
**Purpose**: Evaluate extraction quality and analyze research findings

| Notebook | Description | Status |
|----------|-------------|--------|
| `0500_quality_assessment.Rmd` | Review extraction quality, error patterns | To create |
| `0510_manual_validation.Rmd` | Compare with gold standard sample (20-50 studies) | To create |
| `0520_aggregate_results.Rmd` | Combine all extractions into analysis dataset | To create |
| `0530_fusarium_analysis.Rmd` | Analyze species×crop patterns, abiotic factors | To create |

**Learning Outcomes**: Student can evaluate extraction quality and perform research analysis

## New R Functions

### R/retry_logic.R
**Purpose**: Exponential backoff for API rate limits

```r
retry_with_backoff <- function(expr, max_attempts = 5, base_delay = 1) {
  # Exponential backoff: 1s, 2s, 4s, 8s, 16s
  # Handles HTTP 429 errors
  # Returns result or throws error after max attempts
}
```

### R/batch_processor.R
**Purpose**: Rate-limited batch processing

```r
process_batch <- function(docs, extract_fn, batch_size = 10, delay_seconds = 60) {
  # Process N documents
  # Wait delay_seconds
  # Repeat until all processed
  # Progress tracking
}
```

### R/cache_manager.R
**Purpose**: Save/load extraction results

```r
cache_extraction <- function(doc_id, result, cache_dir = "data/cache") {
  # Save individual extraction result
}

load_cached_extractions <- function(cache_dir = "data/cache") {
  # Load all cached results
  # Return data frame
}

get_uncached_docs <- function(all_docs, cache_dir = "data/cache") {
  # Identify which documents need processing
}
```

### R/gemini_extraction.R
**Purpose**: Fusarium-specific Gemini extraction

```r
extract_fusarium_gemini <- function(abstract, title = "", keywords = "") {
  # Build Fusarium-specific prompt
  # Call Gemini API
  # Parse JSON response
  # Return structured data
}
```

## Directory Structure

### New Directories
```
data/
├── cache/          # Cached extraction results
│   └── .gitignore  # Ignore cache files
├── logs/           # Extraction logs
│   └── .gitignore  # Ignore log files
└── fusarium/       # Student's research data
    └── .gitignore  # Ignore data files (large)
```

### Updated .gitignore
Add:
```
data/cache/*
data/logs/*
data/fusarium/*.csv
data/fusarium/*.rds
```

## Files to Preserve/Adapt

### Keep (may need minor edits)
- `R/evaluation.R` - Working metrics and visualization functions
- `R/utils.R` - Config loading and file I/O helpers
- `test_gemini.R` - Working Gemini test script (reference)

### Adapt
- `notebooks/00_test_gemini_setup.Rmd` → `notebooks/0010_test_gemini_api.Rmd`
  - Better documentation following notebook-developer.md standards
  - Add more comprehensive error troubleshooting

### Redistribute Content
- `notebooks/01_getting_started.Rmd`:
  - Toy example content → `0020_toy_example_extraction.Rmd`
  - Rule-based extraction → Reference in multiple notebooks
  - Evaluation examples → `0500_quality_assessment.Rmd`

### Archive (don't delete, move to dev/)
- `notebooks/01_getting_started.Rmd` → `dev/archive/01_getting_started.Rmd`
- Document why archived in `dev/archive/README.md`

## Student's Extraction Prompt

From Meta Protocol.docx, the student developed this sophisticated prompt:

```
Extract structured information about Fusarium species on cereal crops under environmental conditions.

Extract:
- fusarium_species: List of Fusarium species mentioned
- crop: Cereal crop(s) studied
- abiotic_factors: Environmental factors (temperature, moisture, humidity, etc.)
- observed_effects: Effects on crop/disease (yield loss, toxin production, etc.)
- agronomic_practices: Management strategies mentioned
- modeling: true/false - Does the study involve modeling/prediction?
- summary: Brief 1-2 sentence summary

Return valid JSON format.
```

This will be refined in notebook 0310.

## Implementation Order

### Phase 1: Infrastructure (Days 1-2)
1. ✅ Create dev/implementation_plan.md (this document)
2. Create directory structure (cache, logs)
3. Create new R functions (retry_logic.R, batch_processor.R, cache_manager.R)
4. Update .gitignore

### Phase 2: Educational Foundation (Day 2-3)
5. Create Section 0 notebooks (0000-0030)
6. Test toy examples work
7. Verify error handling basics

### Phase 3: Data Preparation (Day 3-4)
8. Create Section 1 notebooks (0100-0120)
9. Student provides Fusarium dataset or we create sample
10. Test data loading and preprocessing

### Phase 4: Topic Modeling (Day 4-5)
11. Create Section 2 notebooks (0200-0230)
12. Extract LDA details from Meta Protocol.docx
13. Test topic modeling workflow

### Phase 5: Extraction Development (Day 5-7)
14. Create Section 3 notebooks (0300-0330)
15. Implement gemini_extraction.R
16. Test single document extraction
17. Validate error handling

### Phase 6: Production Processing (Day 7-9)
18. Create Section 4 notebooks (0400-0430)
19. Test batch processing on small sample (10-50 docs)
20. Verify caching and resume works
21. Run on full dataset (if student provides data)

### Phase 7: Analysis (Day 9-10)
22. Create Section 5 notebooks (0500-0530)
23. Validate extractions
24. Create research analysis visualizations
25. Test full workflow end-to-end

### Phase 8: Documentation & Cleanup (Day 10)
26. Update README.md with new structure
27. Archive old notebooks with explanation
28. Final testing of complete workflow
29. Document lessons learned

## Success Criteria

### Technical
- ✅ All notebooks follow notebook-developer.md standards
- ✅ Each notebook runs without errors
- ✅ Gemini API calls succeed with retry logic
- ✅ Batch processing handles rate limits
- ✅ Caching allows resume from failures
- ✅ Full workflow processes hundreds of documents

### Educational
- ✅ Beginner can follow notebooks 0000→0599 sequentially
- ✅ Concepts build incrementally (simple → complex)
- ✅ Each notebook explains WHAT, WHY, and OUTCOME
- ✅ Code is well-documented and tested
- ✅ Student learns both toy examples and real research

### Research
- ✅ Student can process 2,663 Fusarium studies
- ✅ Extractions capture complex scientific information
- ✅ Topic modeling reduces dataset to relevant subset
- ✅ Analysis reveals research patterns/trends
- ✅ Student has working dataset for publication

## Known Challenges

### Challenge 1: Rate Limits
**Problem**: Gemini API has rate limits that blocked student
**Solution**: Implement exponential backoff + batch processing with delays
**Notebooks**: 0030, 0330, 0400

### Challenge 2: Complex Extraction Schema
**Problem**: Fusarium data more complex than toy examples
**Solution**: Gradual complexity build-up, JSON schema validation
**Notebooks**: 0300, 0310, 0320

### Challenge 3: Dataset Size
**Problem**: 2,663 documents is large for testing
**Solution**: Create test samples (10, 50, 100, 500), then scale
**Notebooks**: 0230, 0400, 0420

### Challenge 4: Missing Data
**Problem**: We don't have student's actual CSV file yet
**Solution**: Create sample data structure in early notebooks, student adds real data later
**Notebooks**: 0100

### Challenge 5: LDA Topic Modeling Complexity
**Problem**: LDA is advanced topic for beginners
**Solution**: Focus on practical application, provide pre-trained model, explain intuitively
**Notebooks**: 0200-0230

## Notes for Future Development

### Not Implementing (Yet)
- OpenAI GPT integration (focus on Gemini first)
- Anthropic Claude integration (focus on Gemini first)
- Advanced prompt engineering techniques (few-shot, chain-of-thought)
- Cost estimation and tracking (can add later)
- Parallel processing (start with sequential, add if needed)

### Could Add Later
- Interactive Shiny dashboard for exploring extractions
- Automated evaluation with GPT-4 as judge
- Comparison of multiple extraction schemas
- Active learning for improving prompts
- Integration with reference management software

### Student Feedback Loop
- After each section, check if student can run notebooks
- Adjust complexity based on student feedback
- Add more examples if needed
- Simplify if too advanced

## References

### Internal Docs
- `/Users/Mladen.Cucak/Projects/11_research/2025_fhb_llm_extraction/project_overview.MD`
- `/Users/Mladen.Cucak/Projects/11_research/2025_fhb_llm_extraction/dev/Meta Protocol.docx`
- `/Users/Mladen.Cucak/Projects/00_random/agents/notebook-developer.md`
- `/Users/Mladen.Cucak/CLAUDE.md`

### Notebook Development Standards
- Professional technical tone
- Describe → Execute → Describe outcome pattern
- Extract configurables at top
- No emojis unless requested
- Markdown cells for descriptions, not print statements
- Numbered notebooks with clear naming

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-03 | 1.0 | Initial implementation plan created |
