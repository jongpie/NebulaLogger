import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import mdx from '@astrojs/mdx';

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
      head: [
        {
          tag: 'script',
          attrs: {
            async: true,
            src: 'https://www.googletagmanager.com/gtag/js?id=G-TD37SS03XP'
          }
        },
        {
          tag: 'script',
          content: `window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', 'G-TD37SS03XP');`
        }
      ],
      lastUpdated: true,
      pagination: true,
      sidebar: [
        {
          label: 'Introduction',
          items: [
            { label: 'What is Nebula Logger', slug: 'introduction/what-is-nebula-logger' },
            { label: 'How it works', slug: 'introduction/how-it-works' },
            { label: 'Feature tour', slug: 'introduction/feature-tour' },
            { label: 'Package options', slug: 'introduction/package-options' }
          ]
        },
        {
          label: 'Getting Started',
          items: [
            { label: 'Install the unlocked package', slug: 'getting-started/install-unlocked' },
            { label: 'Install the managed package', slug: 'getting-started/install-managed' },
            { label: 'Bundle without a dependency', slug: 'getting-started/bundle-without-dependency' },
            { label: 'Post-install setup', slug: 'getting-started/post-install-setup' }
          ]
        },
        {
          label: 'Logging Guide',
          items: [
            { label: 'Concepts', slug: 'logging-guide/concepts' },
            {
              label: 'Runtime Support',
              items: [
                { label: 'Apex', slug: 'logging-guide/apex' },
                { label: 'Lightning Web Components', slug: 'logging-guide/lwc' },
                { label: 'Aura', slug: 'logging-guide/aura' },
                { label: 'Flow', slug: 'logging-guide/flow' },
                { label: 'OmniStudio', slug: 'logging-guide/omnistudio' }
              ]
            },
            {
              label: 'Enrichment & Features',
              items: [
                { label: 'Scenarios', slug: 'logging-guide/scenarios' },
                { label: 'Tags', slug: 'logging-guide/tags' },
                { label: 'Data masking', slug: 'logging-guide/data-masking' },
                { label: 'Extending the data model', slug: 'logging-guide/extending-the-data-model' }
              ]
            },
            { label: 'Testing your instrumentation', slug: 'logging-guide/testing' }
          ]
        },
        {
          label: 'Console & Operations',
          items: [
            { label: 'Logger Console app', slug: 'console/logger-console-app' },
            { label: 'Log record page', slug: 'console/log-record-page' },
            { label: 'Related Log Entries component', slug: 'console/related-log-entries' },
            { label: 'Investigation playbooks', slug: 'console/investigation-playbooks' }
          ]
        },
        {
          label: 'Configuration',
          items: [
            { label: 'LoggerSettings__c hierarchy', slug: 'configuration/logger-settings' },
            { label: 'LoggerParameter__mdt feature flags', slug: 'configuration/logger-parameters' },
            { label: 'Logging levels', slug: 'configuration/logging-levels' },
            { label: 'Data mask rules', slug: 'configuration/data-mask-rules' },
            { label: 'Environment-aware defaults', slug: 'configuration/environment-defaults' }
          ]
        },
        {
          label: 'Retention & Purging',
          items: [
            { label: 'Retention date semantics', slug: 'retention/retention-dates' },
            { label: 'LogBatchPurger', slug: 'retention/log-batch-purger' },
            { label: 'Purge actions', slug: 'retention/purge-actions' },
            { label: 'Log Retention Rules plugin', slug: 'retention/log-retention-rules-plugin' }
          ]
        },
        {
          label: 'Plugins',
          items: [
            {
              label: 'Plugin Framework',
              items: [
                { label: 'Overview', slug: 'plugins/overview' },
                { label: 'Building your own plugin', slug: 'plugins/building-your-own' }
              ]
            },
            {
              label: 'Official Plugins',
              items: [
                { label: 'Slack', slug: 'plugins/slack' },
                { label: 'Big Object Archiving', slug: 'plugins/big-object-archiving' },
                { label: 'Log Retention Rules', slug: 'plugins/log-retention-rules' },
                { label: 'Logger Admin Dashboard', slug: 'plugins/logger-admin-dashboard' },
                { label: 'Async Failure Additions', slug: 'plugins/async-failure-additions' }
              ]
            }
          ]
        },
        {
          label: 'For Package Developers',
          items: [
            { label: 'Optional dependency via Callable', slug: 'for-package-developers/optional-dependency' },
            { label: 'Hard dependency', slug: 'for-package-developers/hard-dependency' },
            { label: 'No dependency (bundling)', slug: 'for-package-developers/no-dependency' }
          ]
        },
        {
          label: 'AI Agent Skills',
          items: [
            { label: 'Installing the skills', slug: 'ai-agent-skills/installing' },
            { label: 'Skill catalog', slug: 'ai-agent-skills/catalog' }
          ]
        },
        {
          label: 'Reference',
          autogenerate: { directory: 'reference' }
        },
        {
          label: 'Contributing',
          items: [
            { label: 'Repo layout', slug: 'contributing/repo-layout' },
            { label: 'Local development setup', slug: 'contributing/local-setup' },
            { label: 'Testing', slug: 'contributing/testing' },
            { label: 'PR conventions', slug: 'contributing/pr-conventions' }
          ]
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
