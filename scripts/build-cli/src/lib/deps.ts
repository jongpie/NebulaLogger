import { spawnSync, SpawnSyncOptions } from 'node:child_process';
import * as nodeFs from 'node:fs';
import * as nodePath from 'node:path';

export interface CommandResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

export interface CommandRunner {
  run(command: string, options?: SpawnSyncOptions): CommandResult;
}

export interface FileSystem {
  readTextFile(filePath: string): string;
  writeTextFile(filePath: string, contents: string): void;
  exists(filePath: string): boolean;
  resolve(...segments: string[]): string;
}

export interface Deps {
  sfRunner: CommandRunner;
  gitRunner: CommandRunner;
  fileSystem: FileSystem;
  cwd: string;
  logger: Logger;
}

export interface Logger {
  info(message: string): void;
  debug(message: string): void;
  warn(message: string): void;
  error(message: string): void;
}

export const consoleLogger: Logger = {
  info: (message) => process.stdout.write(`${message}\n`),
  debug: (message) => process.stdout.write(`[debug] ${message}\n`),
  warn: (message) => process.stderr.write(`[warn] ${message}\n`),
  error: (message) => process.stderr.write(`[error] ${message}\n`),
};

const createShellRunner = (): CommandRunner => ({
  run(command, options = {}) {
    const spawnOptions: SpawnSyncOptions = {
      shell: true,
      env: { ...process.env, NO_COLOR: '1', FORCE_COLOR: '0' },
      ...options,
      encoding: 'utf8',
    };
    const result = spawnSync(command, spawnOptions);
    const stdout = typeof result.stdout === 'string' ? result.stdout : result.stdout?.toString('utf8') ?? '';
    const stderr = typeof result.stderr === 'string' ? result.stderr : result.stderr?.toString('utf8') ?? '';
    return {
      stdout,
      stderr,
      exitCode: result.status ?? -1,
    };
  },
});

export const createFileSystem = (): FileSystem => ({
  readTextFile: (filePath) => nodeFs.readFileSync(filePath, 'utf8'),
  writeTextFile: (filePath, contents) => nodeFs.writeFileSync(filePath, contents, 'utf8'),
  exists: (filePath) => nodeFs.existsSync(filePath),
  resolve: (...segments) => nodePath.resolve(...segments),
});

export const createDefaultDeps = (): Deps => ({
  sfRunner: createShellRunner(),
  gitRunner: createShellRunner(),
  fileSystem: createFileSystem(),
  cwd: process.cwd(),
  logger: consoleLogger,
});
