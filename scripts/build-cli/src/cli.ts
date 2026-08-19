#!/usr/bin/env node
import { buildCli } from './build-cli';

const runCli = async (): Promise<void> => {
  const program = buildCli();
  try {
    await program.parseAsync(process.argv);
  } catch (error) {
    if (error instanceof Error && 'exitCode' in error && typeof (error as { exitCode?: number }).exitCode === 'number') {
      process.exit((error as { exitCode: number }).exitCode);
    }
    process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
    process.exit(1);
  }
};

void runCli();
