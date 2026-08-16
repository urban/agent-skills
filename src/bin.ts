#!/usr/bin/env bun

import { BunRuntime, BunServices } from "@effect/platform-bun";
import { Effect } from "effect";

import { run } from "./main";

// @effect-diagnostics-next-line strictEffectProvide:off
BunRuntime.runMain(run(globalThis.process.argv.slice(2)).pipe(Effect.provide(BunServices.layer)));
