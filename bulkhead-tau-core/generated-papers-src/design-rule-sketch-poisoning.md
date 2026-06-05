# Design Rule: Image-to-Image Sketch Poisoning

## Status
Frozen / Published (Paper 1.36)

## Context
When utilizing local LLMs or vision-language models to generate image prompts from conceptual sketches, a specific failure mode arises when the source sketch contains abstract text labels (e.g., "COMPANIES", "ATS", "USERS").

## Mechanism: The "Sketch Poisoning" Effect
In image-to-image (img2img) generation pipelines (like Stable Diffusion architectures), the model interprets the visual structures of the input image alongside the text prompt. 

When a sketch contains literal text labels intended for human comprehension, the img2img model attempts to physically render these geometric shapes (the letters) into the final output. Because the model is optimizing for the text prompt's aesthetic (e.g., "photorealistic office", "clean vector art") but is constrained by the hard geometry of the sketched letters, it produces garbled, hallucinated artifacts where the text used to be. The text acts as "visual noise" or "poison" to the generation process.

## Design Rule
**When preparing reference sketches for img2img generation, strip all semantic text labels.**

1.  **Use pure geometry:** Represent concepts using shapes, containers, and structural lines.
2.  **Move semantics to the prompt:** The textual description of what the shapes represent must be handled entirely by the text prompt provided to the model, not embedded in the pixels of the reference image.
3.  **Clean the input:** If using a human-drawn whiteboard or diagram, actively erase or mask text labels before feeding the image into the generation pipeline.

## Provenance
This rule was derived from comparative testing between `gemma4:12b` and `gemma4:26b` during image prompt generation tasks, where the inclusion of diagrammatic text consistently degraded the visual coherence of the final generated assets.