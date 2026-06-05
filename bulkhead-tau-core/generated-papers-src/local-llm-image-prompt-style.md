# Local LLM Prompt Style Divergence in Text-to-Image Pipelines

## Abstract

This paper analyzes the text-to-image prompt engineering characteristics of the local `gemma4:12b` and `gemma4:26b` models. Through three distinct evaluation briefs (a satirical corporate cartoon, a tennis racket physics infographic, and a humorous golf swing caricature), we establish a consistent, model-size-dependent stylistic divergence. While `gemma4:12b` favors narrative-driven, conversational prose with multiple format choices, `gemma4:26b` produces dense, tag-heavy engineered prompts containing explicit technical rendering directives. We detail how this behavioral contrast reflects their relative stop-token and instruction-adherence discipline, providing a blueprint for selecting local models in creative asset pipelines.

---

## 1. Introduction & Context

In structured multi-agent workflows, local models are increasingly used to generate creative assets (prompts, textures, interface sketches) for downstream diffusion models (Stable Diffusion XL via ComfyUI). A key question for pipeline design is whether local models are capable of translating abstract semantic requirements into high-fidelity image prompts, and how model size affects prompt engineering quality.

This paper builds on the findings of **Paper 1.20** (Handoff Discipline) and **Paper 1.25** (Orchestration vs. Reasoning) by extending our evaluation to prompt generation. We contrast the generation styles of `gemma4:12b` (7.6 GB footprint) and `gemma4:26b` (17.0 GB footprint) across three specific domain briefs.

---

## 2. Methodology & Test Briefs

We executed a comparison matrix using a structured system prompt directing each model to write detailed positive prompts for Stable Diffusion XL. The models were evaluated across three briefs:

1.  **Brief 1: Satirical Corporate Cartoon** — A huge corporate elephant awkwardly riding a tiny child's tricycle (representing an Applicant Tracking System).
2.  **Brief 2: Tennis Racket 'Sweet Spot' Infographic** — A technical diagram illustrating power zones on a tennis string bed.
3.  **Brief 3: Golf Swing Fatigue Caricature** — A humorous illustration of a slouching golfer on the 18th hole.

*Execution Script: `scripts/compare_prompt_styles.py`*  
*Logged Responses: `docs/domain_runs/PROMPT_STYLE_COMPARISON_002.md`*

---

## 3. Empirical Case Studies

### 3.1 Brief 1: Satirical Corporate Cartoon
*   **gemma4:12b**: Wrote a single, highly narrative paragraph. It described the scene in descriptive English sentences: *"A satirical political cartoon in the style of a classic newspaper ink drawing, featuring a massive, bloated corporate elephant... awkwardly perched atop a tiny, flimsy child's tricycle..."*
*   **gemma4:26b**: Wrote a comma-separated list of dense artistic tags: *"Editorial political cartoon, black and white ink illustration, high contrast monochrome, a massive bloated corporate elephant... sharp satirical caricature, exaggerated proportions, intricate pen and ink crosshatching..."*
*   **Visual Result**: The 26b prompt successfully guided Stable Diffusion XL to render a tricycle. The 12b model's narrative style led to key semantic bleed, resulting in a standard bicycle instead of a tricycle.

### 3.2 Brief 2: Tennis Racket Infographic
*   **gemma4:12b**: Provided three separate conversational "options" (Infographic, 3D Technical, Schematic) wrapped in helpful introductory prose and concluding tips on Stable Diffusion sampling settings.
*   **gemma4:26b**: Lean and highly engineered. It provided two options, but immediately backed them with an **Engineering Breakdown** explaining why specific phrases (e.g. *"volumetric studio lighting"*, *"subsurface scattering"*) were chosen to force realistic textures.
*   **Style Contrast**: 12b treated the task as an advisory interaction (conversing with a user); 26b treated the task as a precise engineering problem, focusing entirely on token structure.

### 3.3 Brief 3: Golf Swing Fatigue Caricature
*   **gemma4:12b**: Again provided a conversational list of three stylistic directions (Pixar 3D, Classic Comic 2D, Hyper-Realistic Photo) using full descriptive sentences.
*   **gemma4:26b**: Outputted a single, heavily optimized prompt utilizing precise anatomical keywords (*"spine curved like a question mark,"* *"knees buckling"*), followed by a professional engineering breakdown of lighting, aspect ratio, and texture parameters.

---

## 4. Behavioral Comparison & Findings

Our evaluation reveals three clear behavioral distinctions between the model sizes:

### 4.1 Narrative Prose (12b) vs. Tag-Heavy Engineering (26b)
*   The **12b model** writes prompts like a human describer, using standard English syntax. While highly readable, standard grammar introduces extra connector tokens (e.g., "in the style of a," "featuring a") that dilute the attention weights of the CLIP text encoder.
*   The **26b model** mimics professional prompt engineering practices, using comma-separated keywords and technical modifiers (e.g., *Octane Render*, *volumetric lighting*, *macro close-up*). This aligns much closer to the dataset distributions used to train text-to-image models.

### 4.2 Conversational Overhead vs. Execution Focus
*   `gemma4:12b` includes significant preamble and postamble (e.g., *"To get the best results..."*, *"Expert Tip for Success..."*). This conversational overhead is a liability in machine-to-machine pipelines where outputs must be parsed programmatically.
*   `gemma4:26b` exhibits superior stop-token discipline. Its explanations are not conversational filler; they are structured breakdowns of prompt semantics.

### 4.3 Semantic Precision and Brief Adherence
*   In Brief 1, the 26b model's tag-based prompt preserved the distinction between a tricycle and a bicycle, whereas the 12b model lost this detail in its narrative sentences. The 26b model's structured layout translates directly to higher accuracy in the generated image.

---

## 5. Design Guidelines for Image Generation Pipelines

1.  **Use 26b for Automated Pipelines**: When generating prompts programmatically to drive an automated ComfyUI asset pipeline, `gemma4:26b` is the superior choice. Its tag-heavy output requires less parsing and maps cleanly to CLIP.
2.  **Use 12b for Human-in-the-Loop Ideation**: If the goal is to provide a human designer with options to choose from, `gemma4:12b` is valuable due to its conversational diversity and multiple style suggestions.
3.  **Implement Strict Output Cleaning**: Regardless of the model chosen, pipelines must incorporate a regex parser to strip conversational preambles and code blocks before feeding prompts into ComfyUI.
