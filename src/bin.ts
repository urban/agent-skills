#!/usr/bin/env bun

import { BunRuntime } from "@effect/platform-bun";

import { run } from "./main";

BunRuntime.runMain(run(globalThis.process.argv.slice(2)));
