import { buildPackageVersionAlias, findPackageDirectory, formatVersionName, formatVersionNumber, mergePackageAlias, SfdxProjectJson } from '../../src/lib/sfdx-project';

describe('sfdx-project pure helpers', () => {
  describe('formatVersionNumber', () => {
    it('drops the build-number segment after the last dot', () => {
      expect(formatVersionNumber('4.18.3.NEXT')).toBe('4.18.3');
    });

    it('handles single-dot version numbers', () => {
      expect(formatVersionNumber('1.2')).toBe('1');
    });

    it('returns the input unchanged when there is no dot', () => {
      expect(formatVersionNumber('42')).toBe('42');
    });
  });

  describe('formatVersionName', () => {
    it('lowercases and replaces spaces with hyphens', () => {
      expect(formatVersionName("Winter '26 Release")).toBe("winter-'26-release");
    });

    it('preserves already-hyphenated names', () => {
      expect(formatVersionName('improved-testability')).toBe('improved-testability');
    });
  });

  describe('buildPackageVersionAlias', () => {
    it('produces the alias in <package>@<version-number>-<version-name> format', () => {
      const alias = buildPackageVersionAlias('Nebula Logger - Core', '4.18.3.NEXT', 'PrismJS Loading Improvements & Error Handling');
      expect(alias).toBe('Nebula Logger - Core@4.18.3-prismjs-loading-improvements-&-error-handling');
    });
  });

  describe('findPackageDirectory', () => {
    const project: SfdxProjectJson = {
      packageDirectories: [
        { package: 'Nebula Logger - Core', path: './nebula-logger/core', versionName: 'V', versionNumber: '4.18.3.NEXT' },
        { package: 'Plugin Alpha', path: './plugins/alpha' },
      ],
    };

    it('returns the entry with the matching package field', () => {
      const found = findPackageDirectory(project, 'Plugin Alpha');
      expect(found.path).toBe('./plugins/alpha');
    });

    it('throws when no entry matches', () => {
      expect(() => findPackageDirectory(project, 'Unknown')).toThrow(/not found/);
    });
  });

  describe('mergePackageAlias', () => {
    it('inserts the new alias and returns a sorted packageAliases map', () => {
      const project: SfdxProjectJson = {
        packageDirectories: [],
        packageAliases: {
          'Nebula Logger - Core': '0Ho5Y000000TNKASA4',
          'Nebula Logger - Core@4.17.5-something': '04t5Y0000015aaa',
        },
      };
      const merged = mergePackageAlias(project, 'Nebula Logger - Core@4.18.3-prismjs', '04t5Y0000015zzz');
      const keys = Object.keys(merged.packageAliases ?? {});
      expect(keys).toEqual(['Nebula Logger - Core', 'Nebula Logger - Core@4.17.5-something', 'Nebula Logger - Core@4.18.3-prismjs']);
      expect(merged.packageAliases?.['Nebula Logger - Core@4.18.3-prismjs']).toBe('04t5Y0000015zzz');
    });

    it('leaves other top-level project fields untouched', () => {
      const project: SfdxProjectJson = {
        packageDirectories: [{ path: './some/path' }],
        namespace: 'Nebula',
      } as unknown as SfdxProjectJson;
      const merged = mergePackageAlias(project, 'alias', 'id');
      expect((merged as unknown as { namespace: string }).namespace).toBe('Nebula');
      expect(merged.packageDirectories).toBe(project.packageDirectories);
    });

    it('creates packageAliases when none existed', () => {
      const project: SfdxProjectJson = { packageDirectories: [] };
      const merged = mergePackageAlias(project, 'alias', 'id');
      expect(merged.packageAliases).toEqual({ alias: 'id' });
    });
  });
});
