import { defineMarkdownConfig } from '@cparra/apexdocs';

// Nebula Logger docs generation config.
//
// Scope:
// - Only `global` Apex classes stored under nebula-logger/core/main/logger-engine
//   (LogBatchPurger + LogBatchPurgeScheduler are global but live under log-management;
//    those are excluded intentionally).
// - All custom objects (including CMDT, hierarchy settings, and the platform event)
//   under nebula-logger/core/main.
//
// Output lands inside the Astro Starlight content collection at
// docs/src/content/docs/reference/. Frontmatter is injected via transformDocPage so
// Starlight's sidebar and Pagefind index have what they need.
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
    const intro = [
      'Auto-generated reference for Nebula Logger.',
      '',
      'Groupings:',
      '',
      '- **logger-engine** - global Apex classes for adding entries, building payloads, and orchestrating saves.',
      '- **custom-objects** - `Log__c`, `LogEntry__c`, and every custom metadata type Nebula Logger ships.',
      '- **triggers** - platform-event and object triggers that materialize entries and drive plugins.',
      '- **lwc** - `logger` and `logEntryBuilder` client-side APIs.',
      '',
      'For narrative and code examples, see the [Logging Guide](/logging-guide/concepts/).',
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
    const description = `Nebula Logger${typeLabel} reference: ${title}.`;
    return {
      frontmatter: {
        title,
        description
      }
    };
  }
});
