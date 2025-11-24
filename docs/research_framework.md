# Research Framework: From Analysis to Paper

This document guides you to think about your notebook work as scientific research. As you fill it in, focus on why you are doing each step, how it helps you understand the existing evidence base, and what a critical reviewer would need to trust your conclusions.

---

## 1. Introduction

**Purpose**: Why does this research matter?

### Research Context
- What real-world problems does Fusarium head blight create (yield loss, mycotoxins, climate risks)?
- What is the problem with existing Fusarium literature (e.g., fragmented, inconsistent reporting, hard to compare studies)?
- Why is manual extraction insufficient (time, bias, difficulty tracking field vs lab, environment, strain, cultivar)?
- Why do we need to know “what data is out there” before planning new experiments or syntheses?
- How could an LLM-assisted extraction pipeline change how we study Fusarium (e.g., faster mapping of species × crop × environment combinations)?

### Research Question
- What are you trying to extract and why (e.g., temperature/moisture regimes, experimental setting, host, pathogen species/chemotype, outcomes)?
- How can a structured dataset help compare field and lab studies, different environments, and different pathogen species/subspecies/chemotypes across crops?
- Which combinations of environment × crop × pathogen are you most interested in (e.g., wheat × F. graminearum × cool–wet field conditions)?
- What specific research hypotheses can this data test (e.g., “lab studies underestimate temperature sensitivity compared to field trials”)?
- How might others reuse this dataset (meta-analysis, modeling, risk assessment, experimental design)?

**Related notebooks**: 0100-0120 (data exploration)

---

## 2. Methods

### 2.1 Data Collection
- How many studies? From which sources?
- What inclusion/exclusion criteria?
- Time range? Geographic scope?
- How will you distinguish and tag field, greenhouse, and growth-chamber experiments?
- Will you include both inoculation trials and observational surveys? How will you record this?
- How will you handle multiple experiments within a single paper (e.g., several environments, cultivars, or pathogen strains)?

**Related notebooks**: 0090, 0095, 0100

### 2.2 Topic Modeling
- Why use LDA? What alternatives exist?
- How did you select K topics?
- What are your ecophysiology criteria?
- How does topic modeling help you identify ecophysiology-relevant studies and filter out clearly irrelevant topics?

**Related notebooks**: 0200-0230

**Questions to answer**:
- How many studies in final subset?
- What topics were excluded and why?

### 2.3 Extraction Schema Design
- What fields are extracted and why these specifically?
- How does schema relate to research questions?
- What decisions did you make about field types (array vs boolean vs string)?
- Which fields are necessary to study lab–field translation and environment × crop × pathogen interactions (e.g., experiment_setting, location, temperature/moisture regime, cultivar, pathogen genotype/chemotype)?

**Related notebooks**: 0300

### 2.4 Prompt Engineering
- How did you design extraction prompts?
- What examples or constraints did you include?
- How did you handle ambiguous cases?
- How do your prompts help the model identify experimental context (field vs lab), environment, crop, and pathogen variant even when not stated explicitly?

**Related notebooks**: 0310, 0320

### 2.5 LLM Processing
- Which model(s)? Why?
- What parameters (temperature, etc.)?
- How did you handle rate limits and errors?
- Describe retry logic and caching strategy
- How will you detect and log situations where the model is uncertain or likely to misinterpret experimental context (e.g., setting or pathogen/crop identity)?

**Related notebooks**: 0400-0430

---

## 3. Validation

### Quality Assessment
- How did you validate extraction accuracy?
- What sample size for manual validation?
- What were your validation criteria?
- How will you specifically check the correctness of key contextual fields (field/lab setting, environment, species/chemotype, crop)?

**Related notebooks**: 0500-0510

### Error Analysis
- What types of errors occurred?
- Which fields were most problematic?
- How did you quantify quality (precision, recall, F1)?

**Questions to document**:
- Inter-rater reliability (if multiple coders)
- Common failure modes
- Model limitations observed

---

## 4. Results

### 4.1 Extraction Statistics
- How many studies successfully processed?
- Processing time and API costs?
- Error rates by field?
- How many studies fall into key combinations of experiment type (field/greenhouse/growth-chamber), crop, and Fusarium species/chemotype?

**Related notebooks**: 0430, 0520

### 4.2 Research Findings
- What patterns emerged in:
  - Fusarium species distribution
  - Crop-pathogen relationships
  - Climate factors and effects
  - Differences between field, greenhouse, and growth-chamber studies
  - Geographic/temporal trends

**Related notebooks**: 0530

### 4.3 Visualizations
Document key figures:
- Species frequency distributions
- Crop × species matrices
- Temporal trends
- Factor co-occurrence networks
- Comparisons of field vs lab findings (e.g., effect sizes or response curves by experimental setting)

---

## 5. Discussion

### Interpretation
- What do the extraction results tell us about Fusarium research?
- How do findings relate to climate change contexts?
- What gaps exist in the literature?
- What do your results suggest about when lab findings generalize (or fail to generalize) to field conditions?
- What combinations of environment × crop × pathogen appear well-studied vs under-studied?

### Method Evaluation
- Strengths of LLM extraction vs manual?
- Limitations encountered?
- Cost-benefit analysis (time, money, accuracy)?
- Did LLM-based extraction capture enough experimental context (field/lab, environment, crop, pathogen variant) to support your planned analyses?
- Where did the automated pipeline struggle compared to what an expert human could do?

### LLM-Specific Insights
- Which types of information were well-extracted?
- Which required domain expertise that the LLM lacked?
- How did prompt engineering affect quality?

---

## 6. Conclusions

- Key findings summary
- Implications for Fusarium research synthesis
- Recommendations for future LLM-assisted extraction
- What did you learn specifically about lab–field translation and environment × crop × pathogen interactions?

---

## Documentation Guidelines

As you work through notebooks:

1. **Record decisions**: Why did you choose parameter X over Y?
2. **Note surprises**: What unexpected patterns or errors?
3. **Track iterations**: How did you refine prompts/schema?
4. **Quantify everything**: Don't just say "good" - give numbers
5. **Save examples**: Keep examples of good/bad extractions
6. **Think critically**: What would a reviewer challenge?

---

## Active Questions to Answer

*Fill these in as you work:*

- [ ] What is the main research contribution?
- [ ] How does extraction quality compare to manual coding?
- [ ] What would make this publishable?
- [ ] What additional analyses are needed?
- [ ] What are the methodological limitations?
- [ ] How generalizable is this approach?
- [ ] What did you learn about how well lab results translate to field conditions across crops and Fusarium variants?

---

## Notes Section

Use this space for ongoing observations, ideas, and questions that arise during analysis.
