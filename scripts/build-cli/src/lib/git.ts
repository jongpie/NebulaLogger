import { CommandRunner } from './deps';

export const getCurrentBranch = (gitRunner: CommandRunner): string => {
  const result = gitRunner.run('git branch --show-current');
  if (result.exitCode !== 0) {
    throw new Error(`git branch --show-current failed (exit ${result.exitCode}): ${result.stderr}`);
  }
  return result.stdout.trim();
};

export const getCurrentCommitSha = (gitRunner: CommandRunner): string => {
  const result = gitRunner.run('git rev-parse HEAD');
  if (result.exitCode !== 0) {
    throw new Error(`git rev-parse HEAD failed (exit ${result.exitCode}): ${result.stderr}`);
  }
  return result.stdout.trim();
};
