import { CommandResult, CommandRunner, Deps, FileSystem, Logger } from '../src/lib/deps';

export interface StubCommandRunner extends CommandRunner {
  readonly commands: string[];
  queueResult(result: CommandResult): void;
}

export const createStubCommandRunner = (defaultResult: CommandResult = { stdout: '', stderr: '', exitCode: 0 }): StubCommandRunner => {
  const queued: CommandResult[] = [];
  const commands: string[] = [];
  return {
    commands,
    queueResult: (result) => queued.push(result),
    run: (command) => {
      commands.push(command);
      return queued.shift() ?? defaultResult;
    },
  };
};

export const createInMemoryFileSystem = (initial: Record<string, string> = {}): FileSystem & { files: Record<string, string> } => {
  const files: Record<string, string> = { ...initial };
  return {
    files,
    readTextFile: (filePath) => {
      if (!(filePath in files)) {
        throw new Error(`In-memory FS has no file at '${filePath}'`);
      }
      return files[filePath];
    },
    writeTextFile: (filePath, contents) => {
      files[filePath] = contents;
    },
    exists: (filePath) => filePath in files,
    resolve: (...segments) => segments.filter((segment) => segment.length > 0).join('/'),
  };
};

export const createRecordingLogger = (): Logger & { records: { level: string; message: string }[] } => {
  const records: { level: string; message: string }[] = [];
  return {
    records,
    info: (message) => records.push({ level: 'info', message }),
    debug: (message) => records.push({ level: 'debug', message }),
    warn: (message) => records.push({ level: 'warn', message }),
    error: (message) => records.push({ level: 'error', message }),
  };
};

export interface StubDeps extends Deps {
  sfRunner: StubCommandRunner;
  gitRunner: StubCommandRunner;
  fileSystem: FileSystem & { files: Record<string, string> };
  logger: Logger & { records: { level: string; message: string }[] };
}

export const createStubDeps = (options: { initialFiles?: Record<string, string> } = {}): StubDeps => ({
  sfRunner: createStubCommandRunner(),
  gitRunner: createStubCommandRunner(),
  fileSystem: createInMemoryFileSystem(options.initialFiles),
  cwd: '/repo',
  logger: createRecordingLogger(),
});
