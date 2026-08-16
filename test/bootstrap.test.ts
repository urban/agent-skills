import { Effect } from "effect";
import { describe, expect, it } from "vitest";

import { run } from "../src/main";

describe("package bootstrap", () => {
  it("exports an Effect runner", () => {
    expect(Effect.isEffect(run([]))).toBe(true);
  });
});
