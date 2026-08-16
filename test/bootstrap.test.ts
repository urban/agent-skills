// @effect-diagnostics-next-line nodeBuiltinImport:off
import { spawnSync } from "node:child_process";

import { Effect } from "effect";
import { describe, expect, it } from "vitest";

import { run } from "../src/main";

describe("package bootstrap", () => {
  it("exports an Effect runner", () => {
    expect(Effect.isEffect(run([]))).toBe(true);
  });

  it("starts through the Bun executable edge", () => {
    const child = spawnSync("bun", [`${import.meta.dirname}/../src/bin.ts`]);

    expect(child.status).toBe(0);
    expect(child.stdout.toString()).toBe("");
    expect(child.stderr.toString()).toBe("");
  });
});
