import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import mdx from '@astrojs/mdx';

// Sidebar is intentionally minimal during scaffolding. Sections and pages
// from the target information architecture will be added as their content
// files are written. Target IA lives in the docs/ AGENTS.md notes (TBD).
export default defineConfig({
  site: 'https://nebulalogger.com',
  integrations: [
    starlight({
      title: 'Nebula Logger',
      description: 'The most robust observability solution for Salesforce experts.',
      social: {
        github: 'https://github.com/jongpie/NebulaLogger'
      },
      editLink: {
        baseUrl: 'https://github.com/jongpie/NebulaLogger/edit/main/docs/'
      },
      customCss: ['./src/styles/custom.css'],
      lastUpdated: true,
      pagination: true,
      sidebar: [
        {
          label: 'Getting Started',
          items: [{ label: 'Install the unlocked package', slug: 'getting-started/install-unlocked' }]
        },
        {
          label: 'Release Notes',
          link: 'https://github.com/jongpie/NebulaLogger/releases',
          attrs: { target: '_blank', rel: 'noopener noreferrer' }
        }
      ]
    }),
    mdx()
  ]
});
