import { updateReadmePackageVersionId } from '../../src/lib/readme';

describe('updateReadmePackageVersionId', () => {
  const sampleReadme = [
    '[![Deploy Unlocked Package to a Sandbox](./images/btn-install-unlocked-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t5Y0000000aaa)',
    '[![Deploy Unlocked Package to Production](./images/btn-install-unlocked-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5Y0000000bbb)',
    'Or install via CLI:',
    '```',
    'sf package install --wait 20 --security-type AdminsOnly --package 04t5Y0000000ccc',
    '```',
  ].join('\n');

  it('rewrites the sandbox install button URL to the new package version ID', () => {
    const updated = updateReadmePackageVersionId(sampleReadme, '04t5Y0000015zzz');
    expect(updated).toContain('installPackage.apexp?p0=04t5Y0000015zzz)');
    expect(updated).not.toContain('p0=04t5Y0000000aaa');
  });

  it('rewrites the production install button URL to the new package version ID', () => {
    const updated = updateReadmePackageVersionId(sampleReadme, '04t5Y0000015zzz');
    expect(updated).toContain('login.salesforce.com/packaging/installPackage.apexp?p0=04t5Y0000015zzz');
    expect(updated).not.toContain('p0=04t5Y0000000bbb');
  });

  it('rewrites the sf CLI snippet to the new package version ID', () => {
    const updated = updateReadmePackageVersionId(sampleReadme, '04t5Y0000015zzz');
    expect(updated).toContain('sf package install --wait 20 --security-type AdminsOnly --package 04t5Y0000015zzz');
    expect(updated).not.toContain('--package 04t5Y0000000ccc');
  });

  it('leaves the rest of the README untouched', () => {
    const updated = updateReadmePackageVersionId(sampleReadme, '04t5Y0000015zzz');
    expect(updated).toContain('Or install via CLI:');
    expect(updated).toContain('```');
  });

  it('handles the actual Nebula Logger README shape (18-char alphanumeric package IDs, closing paren after)', () => {
    const realShape = [
      '[![Install Unlocked Package in a Sandbox](./images/btn-install-unlocked-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tg70000009GaDAAU)',
      '[![Install Unlocked Package in Production](./images/btn-install-unlocked-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg70000009GaDAAU)',
      '',
      '`sf package install --wait 20 --security-type AdminsOnly --package 04tg70000009GaDAAU`',
      '',
      'Or use one of the buttons above.',
    ].join('\n');

    const updated = updateReadmePackageVersionId(realShape, '04tKe0000099ABCIA5');
    expect(updated).toContain('installPackage.apexp?p0=04tKe0000099ABCIA5)');
    expect(updated).toContain('login.salesforce.com/packaging/installPackage.apexp?p0=04tKe0000099ABCIA5)');
    expect(updated).toContain('sf package install --wait 20 --security-type AdminsOnly --package 04tKe0000099ABCIA5`');
    expect(updated).not.toContain('04tg70000009GaDAAU');
    expect(updated).toContain('Or use one of the buttons above.');
  });
});
