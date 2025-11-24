# Technical Overview

## File Map

### Entry Points
- `README.md` - Start here
- `docs/research_framework.md` - Student writes research thinking here

### Code
- `R/*.R` - Production functions (source from notebooks)
- `notebooks/` - Numbered workflow (0000 → 0530)

### Documentation
- `dev/doc/main/system_description.md` - Architecture
- `dev/doc/main/implementation_plan.md` - Status, phases
- `dev/doc/main/technical_overview.md` - This file

### Planning
- `dev/doc/plans/` - Development plans
- `dev/doc/issues/` - Issues, bugs
- `dev/doc/archive_solutions/` - Implemented solutions

### Archives
- `dev/archive/` - Old notebooks (historical reference only)
- `dev/implementation_plan.md` - Personal notes (do not modify)

## Connections

### Workflow Path
```
notebooks/0000_setup → R/utils.R, R/gemini_extraction.R
notebooks/0200-0230 → Topic modeling → ecophysiology subset
notebooks/0300-0310 → Schema + prompts → R/gemini_extraction.R
notebooks/0400-0430 → Batch processing → data/cache/
notebooks/0500-0530 → Validation → results/
```

### Function Dependencies
```
R/gemini_extraction.R ← R/retry_logic.R
R/batch_processor.R ← R/gemini_extraction.R + R/cache_manager.R
R/evaluation.R ← extraction results
```

### Data Flow
```
data/fusarium/*.csv → preprocessing → topic modeling → subset
subset → LLM extraction → data/cache/*.rds
cached results → validation → results/
```

## How to Proceed

1. **Setup**: Run notebooks 0000, 0005, 0010
2. **Understand data**: Run notebooks 0100-0120
3. **Topic model**: Run notebooks 0200-0230
4. **Test extraction**: Run notebooks 0300-0330 (small samples)
5. **Production**: Run notebooks 0400-0430 (full dataset, costs apply)
6. **Validate**: Run notebooks 0500-0530
7. **Document research**: Fill in `docs/research_framework.md` as you go

## Key Files

| File | Purpose |
|------|---------|
| `R/gemini_extraction.R` | Core LLM extraction functions |
| `R/retry_logic.R` | Rate limit handling |
| `R/batch_processor.R` | Batch processing with checkpoints |
| `R/cache_manager.R` | Save/load results |
| `notebooks/0300_design_extraction_schema.Rmd` | Schema definition |
| `notebooks/0310_develop_prompts.Rmd` | Prompt engineering |
| `notebooks/0420_run_full_extraction.Rmd` | Production run |
| `notebooks/0530_fusarium_analysis.Rmd` | Final analysis |

## Environment

- `.env` - API keys (never commit)
- `renv.lock` - Package versions
- `renv/` - Project library (use this, not global library)

## Configuration

- API keys: `.env` or global R environment
- Processing params: Set in notebooks (delay, batch size)
- Extraction schema: `notebooks/0300`
- Prompts: `notebooks/0310`
