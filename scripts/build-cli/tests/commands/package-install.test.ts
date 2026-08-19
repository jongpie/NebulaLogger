import { runPackageInstall } from '../../src/commands/package-install';
import { createStubDeps } from '../test-doubles';

describe('runPackageInstall', () => {
  it('shells out to sf without --security-type when none is supplied', () => {
    const deps = createStubDeps();
    runPackageInstall(deps, {
      packageVersionId: '04t5Y0000015zzz',
      targetUsername: 'scratch-alias',
    });
    expect(deps.sfRunner.commands).toHaveLength(1);
    expect(deps.sfRunner.commands[0]).toContain('npx sf package install');
    expect(deps.sfRunner.commands[0]).not.toContain('--security-type');
  });

  it('appends --security-type AllUsers when securityType is AllUsers', () => {
    const deps = createStubDeps();
    runPackageInstall(deps, {
      packageVersionId: '04t5Y0000015zzz',
      targetUsername: 'scratch-alias',
      securityType: 'AllUsers',
    });
    expect(deps.sfRunner.commands[0]).toContain('--security-type AllUsers');
  });

  it('trims whitespace from the package version ID before shelling out', () => {
    const deps = createStubDeps();
    runPackageInstall(deps, {
      packageVersionId: '  04t5Y0000015zzz\n',
      targetUsername: 'scratch-alias',
    });
    expect(deps.sfRunner.commands[0]).toContain('--package 04t5Y0000015zzz');
    expect(deps.sfRunner.commands[0]).not.toContain('--package   04t5Y0000015zzz');
  });

  it('throws with a helpful message when --security-type is an unknown value', () => {
    const deps = createStubDeps();
    expect(() =>
      runPackageInstall(deps, {
        packageVersionId: '04t',
        targetUsername: 'x',
        securityType: 'AllPeople',
      })
    ).toThrow(/Invalid --security-type/);
  });
});
