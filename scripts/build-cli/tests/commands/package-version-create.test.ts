import { runPackageVersionCreate } from '../../src/commands/package-version-create';
import { createStubDeps } from '../test-doubles';

describe('runPackageVersionCreate', () => {
  it('queries git for branch + commit, shells out to sf, returns the SubscriberPackageVersionId', () => {
    const deps = createStubDeps();
    deps.gitRunner.queueResult({ stdout: 'main\n', stderr: '', exitCode: 0 });
    deps.gitRunner.queueResult({ stdout: 'abc123\n', stderr: '', exitCode: 0 });
    deps.sfRunner.queueResult({
      stdout: JSON.stringify({ result: { SubscriberPackageVersionId: '04t5Y0000015zzz' } }),
      stderr: '',
      exitCode: 0,
    });

    const packageVersionId = runPackageVersionCreate(deps, { packageAlias: 'Nebula Logger - Core' });

    expect(packageVersionId).toBe('04t5Y0000015zzz');
    expect(deps.gitRunner.commands).toEqual(['git branch --show-current', 'git rev-parse HEAD']);
    expect(deps.sfRunner.commands).toHaveLength(1);
    expect(deps.sfRunner.commands[0]).toContain('--package "Nebula Logger - Core"');
    expect(deps.sfRunner.commands[0]).toContain('--branch "main"');
    expect(deps.sfRunner.commands[0]).toContain('--tag "abc123"');
  });

  it('throws when sf returns no SubscriberPackageVersionId', () => {
    const deps = createStubDeps();
    deps.gitRunner.queueResult({ stdout: 'main', stderr: '', exitCode: 0 });
    deps.gitRunner.queueResult({ stdout: 'abc', stderr: '', exitCode: 0 });
    deps.sfRunner.queueResult({
      stdout: JSON.stringify({ result: {} }),
      stderr: '',
      exitCode: 0,
    });
    expect(() => runPackageVersionCreate(deps, { packageAlias: 'x' })).toThrow(/no SubscriberPackageVersionId/);
  });
});
