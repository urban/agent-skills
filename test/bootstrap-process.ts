const child = Bun.spawnSync(["bun", `${import.meta.dirname}/../src/bin.ts`]);
const failures = [
  child.exitCode === 0 ? undefined : `Expected exit code 0, received ${child.exitCode}.`,
  child.stdout.length === 0
    ? undefined
    : `Expected empty stdout, received ${child.stdout.toString()}.`,
  child.stderr.length === 0
    ? undefined
    : `Expected empty stderr, received ${child.stderr.toString()}.`,
].filter((failure): failure is string => failure !== undefined);

if (failures.length > 0) {
  await Bun.write(Bun.stderr, `Bun process smoke test failed:\n${failures.join("\n")}\n`);
  globalThis.process.exitCode = 1;
}
