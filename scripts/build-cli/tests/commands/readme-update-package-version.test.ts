import { runReadmeUpdatePackageVersion } from '../../src/commands/readme-update-package-version';
import { createStubDeps } from '../test-doubles';

describe('runReadmeUpdatePackageVersion', () => {
  const readmePath = '/repo/README.md';

  it('rewrites all three package-install snippets in the README', () => {
    const initial = [
      '(https://test.salesforce.com/packaging/installPackage.apexp?p0=04t5Y0000000aaa)',
      '(https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5Y0000000bbb)',
      'sf package install --wait 20 --security-type AdminsOnly --package 04t5Y0000000ccc',
    ].join('\nSANDBOX: btn-install-unlocked-package-sandbox.png)]\nPROD: btn-install-unlocked-package-production.png)]\n');

    const seededReadme = [
      '[![](./images/btn-install-unlocked-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t5Y0000000aaa)',
      '[![](./images/btn-install-unlocked-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5Y0000000bbb)',
      'sf package install --wait 20 --security-type AdminsOnly --package 04t5Y0000000ccc',
    ].join('\n');
    expect(initial).toBeTruthy(); // dummy assertion to keep the constant used in future edits

    const deps = createStubDeps({ initialFiles: { [readmePath]: seededReadme } });
    runReadmeUpdatePackageVersion(deps, { readmePath, packageVersionId: '04t5Y0000015zzz' });

    const updated = deps.fileSystem.files[readmePath];
    expect(updated).toContain('installPackage.apexp?p0=04t5Y0000015zzz)');
    expect(updated).toContain('sf package install --wait 20 --security-type AdminsOnly --package 04t5Y0000015zzz');
    expect(updated).not.toContain('04t5Y0000000aaa');
    expect(updated).not.toContain('04t5Y0000000bbb');
    expect(updated).not.toContain('04t5Y0000000ccc');
  });
});
