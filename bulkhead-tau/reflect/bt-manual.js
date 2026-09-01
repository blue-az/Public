/* Render the mermaid diagrams in Reflect owner's manuals.
 *
 * Reflect emits diagrams as <pre class="mermaid"><code>flowchart TD ...</code></pre>
 * and never loads mermaid, so every manual has been publishing its diagram
 * source as preformatted text instead of a picture. 129 blocks across the
 * seven manuals as of 2026-08-31.
 *
 * Mermaid reads an element's textContent, and the nested <code> would leave the
 * markup in place after rendering, so each block is flattened first. If this
 * script fails to load the page degrades to exactly what it showed before:
 * readable source.
 */
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";

const palette = {
  background: "#112240",
  primaryColor: "#112240",
  primaryTextColor: "#ccd6f6",
  primaryBorderColor: "#64ffda",
  secondaryColor: "#0a192f",
  secondaryTextColor: "#ccd6f6",
  secondaryBorderColor: "#233554",
  tertiaryColor: "#0a192f",
  tertiaryTextColor: "#ccd6f6",
  tertiaryBorderColor: "#233554",
  lineColor: "#8892b0",
  textColor: "#ccd6f6",
  mainBkg: "#112240",
  nodeBorder: "#64ffda",
  clusterBkg: "#0a192f",
  clusterBorder: "#233554",
  edgeLabelBackground: "#0a192f",
  // nested subgraphs alternate to altBackground; without this the inner
  // clusters fall back to mermaid's default #ffffde and render cream on navy
  altBackground: "#0a192f",
  fontFamily: "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
  fontSize: "14px",
};

mermaid.initialize({
  startOnLoad: false,
  theme: "base",
  themeVariables: palette,
  securityLevel: "strict",
  flowchart: { htmlLabels: true, curve: "basis" },
});

const blocks = document.querySelectorAll("pre.mermaid");
for (const pre of blocks) {
  const code = pre.querySelector("code");
  if (code) pre.textContent = code.textContent;
}

try {
  await mermaid.run({ nodes: blocks });
} catch (err) {
  // Leave the source visible rather than an empty box.
  console.error("[bt-manual] mermaid render failed:", err);
}
