"use strict";

const CODE_PATTERN = /(```[\s\S]*?```|~~~[\s\S]*?~~~|`[^`\n]+`)/g;
const MATH_PATTERNS = [
  { regex: /\$\$([\s\S]+?)\$\$/g, display: true },
  { regex: /\\\[([\s\S]+?)\\\]/g, display: true },
  { regex: /\\\(([\s\S]+?)\\\)/g, display: false },
  { regex: /(?<![\\$\w])\$(?![\s$])((?:\\\$|[^$\n])+?)(?<!\s)\$(?!\w)/g, display: false },
];

function extractMath(markdown) {
  const math = [];
  const segments = markdown.split(CODE_PATTERN);
  for (let i = 0; i < segments.length; i += 2) {
    let text = segments[i];
    for (const { regex, display } of MATH_PATTERNS) {
      text = text.replace(regex, (_, tex) => {
        math.push({ tex, display });
        return `MIERACLEMATH${math.length - 1}END`;
      });
    }
    segments[i] = text.replace(/\\\$/g, "$");
  }
  return { text: segments.join(""), math };
}

function renderMath({ tex, display }) {
  return katex.renderToString(tex, { displayMode: display, throwOnError: false });
}

function render(markdown, fontSize) {
  document.documentElement.style.setProperty("--font-size", `${fontSize}px`);
  const { text, math } = extractMath(markdown);
  let html = marked.parse(text, { gfm: true, breaks: false });
  html = html.replace(/MIERACLEMATH(\d+)END/g, (_, index) => renderMath(math[Number(index)]));
  const content = document.getElementById("content");
  content.innerHTML = html;
  content.querySelectorAll("pre code").forEach((block) => hljs.highlightElement(block));
  return measure();
}

function measure() {
  return Math.ceil(document.getElementById("content").getBoundingClientRect().height);
}
