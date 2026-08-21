import { defineMarkdownConfig } from '@cparra/apexdocs';

// Nebula Logger docs generation config.
//
// This one config file handles two distinct apexdocs runs:
//
// 1. Core run (default): documents `global` Apex classes under
//    nebula-logger/core/main/logger-engine plus every custom object,
//    custom metadata type, and trigger under nebula-logger/core/main.
//    LogBatchPurger + LogBatchPurgeScheduler are global but live under
//    log-management; those are excluded intentionally.
//
// 2. Per-plugin runs: the docs generation script invokes apexdocs once
//    per official plugin under nebula-logger/plugins/<name>. Those runs
//    override sourceDir, targetDir, scope, and referenceGuideTitle at the
//    CLI. Because they are `public` (not `global`) classes for the
//    unlocked package, the transform hooks below detect plugin runs via
//    the NEBULA_DOCS_CONTEXT environment variable set by the runner and
//    inject an "unlocked-only, public API" warning on each plugin's
//    landing page.
//
// Output lands inside the Astro Starlight content collection at
// docs/src/content/docs/reference/. Frontmatter is injected via
// transformDocPage so Starlight's sidebar and Pagefind index have what
// they need.

const PLUGIN_CONTEXT_PREFIX = 'plugin:';
const context = process.env.NEBULA_DOCS_CONTEXT ?? 'core';
const isPluginRun = context.startsWith(PLUGIN_CONTEXT_PREFIX);
const pluginName = isPluginRun ? context.slice(PLUGIN_CONTEXT_PREFIX.length) : null;
const pluginNarrativeLink = isPluginRun ? `/plugins/${pluginName}/` : null;

export default defineMarkdownConfig({
  sourceDir: 'nebula-logger/core/main',
  targetDir: 'docs/src/content/docs/reference',
  scope: ['global'],
  customObjectVisibility: ['public'],
  sortAlphabetically: true,
  linkingStrategy: 'relative',
  referenceGuideTitle: 'Reference',
  exclude: [
    // Non-logger-engine Apex classes are out of scope even when they declare `global`.
    // Custom objects under these paths are still documented because they live in
    // `**/objects/**`, not `**/classes/**`.
    '**/log-management/classes/**',
    '**/configuration/classes/**'
  ],
  transformReferenceGuide: guide => {
    if (isPluginRun) {
      const title = `${pluginName} plugin reference`;
      const intro = [
        `Auto-generated reference for the **${pluginName}** plugin.`,
        '',
        ':::caution[Unlocked package only]',
        `The ${pluginName} plugin's Apex API is exposed as \`public\` (not \`global\`) and is only available in the [unlocked package](/introduction/package-options/). \`public\` API is not covered by Nebula Logger's global compatibility guarantees - classes, methods, and fields on this page can change, be renamed, or be removed in a future release without a deprecation window. Pin plugin versions you've tested against and re-verify after upgrades.`,
        ':::',
        '',
        `For install, configuration, and usage guidance, see the [${pluginName} plugin narrative](${pluginNarrativeLink}).`,
        '',
        '---',
        '',
        guide.content
      ].join('\n');

      return {
        frontmatter: {
          title,
          description: `Auto-generated reference for the Nebula Logger ${pluginName} plugin's public Apex classes and metadata.`
        },
        content: intro
      };
    }

    const intro = [
      'Auto-generated reference for Nebula Logger.',
      '',
      'Groupings:',
      '',
      '- **logger-engine** - global Apex classes for adding entries, building payloads, and orchestrating saves.',
      '- **custom-objects** - `Log__c`, `LogEntry__c`, and every custom metadata type Nebula Logger ships.',
      '- **triggers** - platform-event and object triggers that materialize entries and drive plugins.',
      '- **lwc** - `logger` and `logEntryBuilder` client-side APIs.',
      '- **plugins** - reference for each official plugin under `nebula-logger/plugins/`. Public API, unlocked-package only.',
      '',
      'For narrative and code examples, see the [Logging Guide](/NebulaLogger/logging-guide/concepts/).',
      '',
      '---',
      '',
      guide.content
    ].join('\n');

    return {
      frontmatter: {
        title: 'Reference',
        description: 'Auto-generated reference for Nebula Logger Apex classes, custom objects, triggers, and LWCs.'
      },
      content: intro
    };
  },
  transformDocPage: doc => {
    const title = doc.source?.name ?? doc.frontmatter?.title ?? 'Reference';
    const typeLabel = doc.source?.type ? ` ${doc.source.type}` : '';
    const description = isPluginRun
      ? `Nebula Logger ${pluginName} plugin${typeLabel} (public API): ${title}.`
      : `Nebula Logger${typeLabel} reference: ${title}.`;
    return {
      frontmatter: {
        title,
        description
      }
    };
  }
});
