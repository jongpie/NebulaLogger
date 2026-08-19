import { getCurrentBranch, getCurrentCommitSha } from '../../src/lib/git';
import { createStubCommandRunner } from '../test-doubles';

describe('git.ts wrappers', () => {
  it('returns the current branch, trimming trailing newline', () => {
    const runner = createStubCommandRunner();
    runner.queueResult({ stdout: 'feature/my-branch\n', stderr: '', exitCode: 0 });
    expect(getCurrentBranch(runner)).toBe('feature/my-branch');
    expect(runner.commands[0]).toBe('git branch --show-current');
  });

  it('throws when git branch --show-current fails', () => {
    const runner = createStubCommandRunner();
    runner.queueResult({ stdout: '', stderr: 'not a git repo', exitCode: 128 });
    expect(() => getCurrentBranch(runner)).toThrow(/git branch --show-current failed/);
  });

  it('returns the current commit SHA, trimming trailing newline', () => {
    const runner = createStubCommandRunner();
    runner.queueResult({ stdout: 'abc1234deadbeef\n', stderr: '', exitCode: 0 });
    expect(getCurrentCommitSha(runner)).toBe('abc1234deadbeef');
    expect(runner.commands[0]).toBe('git rev-parse HEAD');
  });

  it('throws when git rev-parse HEAD fails', () => {
    const runner = createStubCommandRunner();
    runner.queueResult({ stdout: '', stderr: 'no HEAD', exitCode: 128 });
    expect(() => getCurrentCommitSha(runner)).toThrow(/git rev-parse HEAD failed/);
  });
});
