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
  transformReferenceGuide: guide => ({
    frontmatter: {
      title: 'Reference',
      description: 'Nebula Logger reference for Apex classes, Lightning Web Components, and custom objects.'
    }
  }),
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
