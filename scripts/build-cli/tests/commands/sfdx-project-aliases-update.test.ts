import { runSfdxProjectAliasesUpdate } from '../../src/commands/sfdx-project-aliases-update';
import { createStubDeps } from '../test-doubles';

const buildSfdxProjectFixture = (): string =>
  JSON.stringify(
    {
      packageDirectories: [
        {
          package: 'Nebula Logger - Core',
          path: './nebula-logger/core',
          versionName: 'PrismJS Loading Improvements & Error Handling',
          versionNumber: '4.18.3.NEXT',
        },
      ],
      packageAliases: {
        'Nebula Logger - Core': '0Ho5Y000000TNKASA4',
        'Nebula Logger - Core@4.17.5-something': '04t5Y0000015aaa',
      },
    },
    null,
    2
  );

describe('runSfdxProjectAliasesUpdate', () => {
  const sfdxProjectPath = '/repo/sfdx-project.json';

  it('adds the newly-created version alias and writes back a sorted packageAliases block', () => {
    const deps = createStubDeps({ initialFiles: { [sfdxProjectPath]: buildSfdxProjectFixture() } });

    const versionAlias = runSfdxProjectAliasesUpdate(deps, {
      packageAlias: 'Nebula Logger - Core',
      packageVersionId: '04t5Y0000015zzz',
      sfdxProjectPath,
    });

    expect(versionAlias).toBe('Nebula Logger - Core@4.18.3-prismjs-loading-improvements-&-error-handling');
    const written = JSON.parse(deps.fileSystem.files[sfdxProjectPath]) as { packageAliases: Record<string, string> };
    expect(Object.keys(written.packageAliases)).toEqual([
      'Nebula Logger - Core',
      'Nebula Logger - Core@4.17.5-something',
      'Nebula Logger - Core@4.18.3-prismjs-loading-improvements-&-error-handling',
    ]);
    expect(written.packageAliases['Nebula Logger - Core@4.18.3-prismjs-loading-improvements-&-error-handling']).toBe('04t5Y0000015zzz');
  });

  it('prefers the caller-supplied original contents over the disk copy (to defend against sf CLI having mutated the file)', () => {
    const deps = createStubDeps({
      initialFiles: { [sfdxProjectPath]: '{ "packageDirectories": [], "packageAliases": {} }' },
    });

    runSfdxProjectAliasesUpdate(deps, {
      packageAlias: 'Nebula Logger - Core',
      packageVersionId: '04t5Y0000015zzz',
      sfdxProjectPath,
      originalSfdxProjectContents: buildSfdxProjectFixture(),
    });

    const written = JSON.parse(deps.fileSystem.files[sfdxProjectPath]) as { packageAliases: Record<string, string> };
    expect(Object.keys(written.packageAliases)).toContain('Nebula Logger - Core@4.18.3-prismjs-loading-improvements-&-error-handling');
  });

  it('throws when the package alias is not in packageDirectories', () => {
    const deps = createStubDeps({ initialFiles: { [sfdxProjectPath]: buildSfdxProjectFixture() } });
    expect(() =>
      runSfdxProjectAliasesUpdate(deps, {
        packageAlias: 'Unknown',
        packageVersionId: '04t',
        sfdxProjectPath,
      })
    ).toThrow(/not found/);
  });
});
