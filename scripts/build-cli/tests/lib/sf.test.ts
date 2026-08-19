import { createPackageVersion, installPackage, isPackageInstallSecurityType } from '../../src/lib/sf';
import { createStubCommandRunner } from '../test-doubles';

describe('sf.ts sf-CLI wrappers', () => {
  describe('createPackageVersion', () => {
    it('shells out to `npx sf package version create` with the expected flags', () => {
      const runner = createStubCommandRunner();
      runner.queueResult({
        stdout: JSON.stringify({ result: { SubscriberPackageVersionId: '04t5Y0000015zzz' } }),
        stderr: '',
        exitCode: 0,
      });

      const created = createPackageVersion(runner, {
        packageAlias: 'Nebula Logger - Core',
        gitBranch: 'feature/my-branch',
        gitCommit: 'abc123',
      });

      expect(runner.commands).toHaveLength(1);
      const command = runner.commands[0];
      expect(command).toContain('npx sf package version create');
      expect(command).toContain('--json');
      expect(command).toContain('--skip-ancestor-check');
      expect(command).toContain('--code-coverage');
      expect(command).toContain('--installation-key-bypass');
      expect(command).toContain('--package "Nebula Logger - Core"');
      expect(command).toContain('--branch "feature/my-branch"');
      expect(command).toContain('--tag "abc123"');
      expect(created.SubscriberPackageVersionId).toBe('04t5Y0000015zzz');
    });

    it('throws when the sf CLI exits non-zero', () => {
      const runner = createStubCommandRunner();
      runner.queueResult({ stdout: '', stderr: 'oh no', exitCode: 1 });
      expect(() =>
        createPackageVersion(runner, {
          packageAlias: 'x',
          gitBranch: 'b',
          gitCommit: 'c',
        })
      ).toThrow(/sf package version create failed/);
    });

    it('throws when the sf CLI output is not JSON', () => {
      const runner = createStubCommandRunner();
      runner.queueResult({ stdout: 'not json', stderr: '', exitCode: 0 });
      expect(() =>
        createPackageVersion(runner, {
          packageAlias: 'x',
          gitBranch: 'b',
          gitCommit: 'c',
        })
      ).toThrow(/Could not parse/);
    });
  });

  describe('installPackage', () => {
    it('omits --security-type when not provided', () => {
      const runner = createStubCommandRunner();
      installPackage(runner, {
        packageVersionId: '04t5Y0000015zzz',
        targetUsername: 'scratch-alias',
      });
      const command = runner.commands[0];
      expect(command).toContain('npx sf package install');
      expect(command).toContain('--no-prompt');
      expect(command).toContain('--target-org "scratch-alias"');
      expect(command).toContain('--wait 20');
      expect(command).toContain('--publish-wait 5');
      expect(command).toContain('--package 04t5Y0000015zzz');
      expect(command).not.toContain('--security-type');
    });

    it('appends --security-type when provided', () => {
      const runner = createStubCommandRunner();
      installPackage(runner, {
        packageVersionId: '04t5Y0000015zzz',
        targetUsername: 'scratch-alias',
        securityType: 'AllUsers',
      });
      expect(runner.commands[0]).toContain('--security-type AllUsers');
    });

    it('honors --wait and --publish-wait overrides', () => {
      const runner = createStubCommandRunner();
      installPackage(runner, {
        packageVersionId: '04t5Y0000015zzz',
        targetUsername: 'scratch-alias',
        waitMinutes: 45,
        publishWaitMinutes: 10,
      });
      const command = runner.commands[0];
      expect(command).toContain('--wait 45');
      expect(command).toContain('--publish-wait 10');
    });

    it('throws when the sf CLI exits non-zero', () => {
      const runner = createStubCommandRunner();
      runner.queueResult({ stdout: '', stderr: 'install refused', exitCode: 1 });
      expect(() =>
        installPackage(runner, {
          packageVersionId: '04t5Y0000015zzz',
          targetUsername: 'scratch-alias',
        })
      ).toThrow(/sf package install failed/);
    });
  });

  describe('isPackageInstallSecurityType', () => {
    it('accepts the three valid values', () => {
      expect(isPackageInstallSecurityType('AllUsers')).toBe(true);
      expect(isPackageInstallSecurityType('AdminsOnly')).toBe(true);
      expect(isPackageInstallSecurityType('Custom')).toBe(true);
    });

    it('rejects unknown values', () => {
      expect(isPackageInstallSecurityType('SomeoneElse')).toBe(false);
      expect(isPackageInstallSecurityType('alluser')).toBe(false);
      expect(isPackageInstallSecurityType('')).toBe(false);
    });
  });
});
