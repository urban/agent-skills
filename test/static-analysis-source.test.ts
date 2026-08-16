import { describe, expect, it } from "vitest";

import { findSourceViolations } from "../scripts/static-analysis-source-core";

const tsIgnore = ["@", "ts-ignore"].join("");
const oxlintDisable = ["oxlint", "-disable"].join("");

describe("static-analysis source guard", () => {
  it("rejects TypeScript and OxLint directives in comments", () => {
    const violations = findSourceViolations([
      { content: `// ${tsIgnore}\nexport const value = true;`, path: "src/example.ts" },
      { content: `/*\n${oxlintDisable}\n*/`, path: "test/example.test.ts" },
    ]);

    expect(violations.map(({ message }) => message)).toEqual([
      `Static-analysis directive ${JSON.stringify(tsIgnore)} is forbidden.`,
      `Static-analysis directive ${JSON.stringify(oxlintDisable)} is forbidden.`,
    ]);
  });

  it("ignores directive-like text inside string literals", () => {
    const content = `const example = ${JSON.stringify(`// ${tsIgnore}`)};`;

    expect(findSourceViolations([{ content, path: "src/example.ts" }])).toEqual([]);
  });

  it("finds directives after regex literals and inside template expressions", () => {
    const afterRegex = `const pattern = /"/;\n// ${tsIgnore}`;
    const insideTemplate = ["const value = `", "${1 /* ", oxlintDisable, " */}", "`;"].join("");

    expect(
      findSourceViolations([
        { content: afterRegex, path: "src/regex.ts" },
        { content: insideTemplate, path: "src/template.ts" },
      ]),
    ).toHaveLength(2);
  });

  it("rejects TypeScript extensions outside the audited include globs", () => {
    expect(findSourceViolations([{ content: "export {};", path: "src/example.tsx" }])).toEqual([
      {
        location: "src/example.tsx",
        message: "Authored TypeScript is not covered by a configured TypeScript project.",
      },
    ]);
  });

  it("rejects TypeScript outside the audited project paths", () => {
    expect(findSourceViolations([{ content: "export {};", path: "other/example.ts" }])).toEqual([
      {
        location: "other/example.ts",
        message: "Authored TypeScript is not covered by a configured TypeScript project.",
      },
    ]);
  });
});
