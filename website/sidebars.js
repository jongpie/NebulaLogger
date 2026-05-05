/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */

// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  // Main documentation sidebar
  docs: [
    {
      type: 'doc',
      id: 'overview',
      label: 'Overview',
    },
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: [
        'installation',
        'quick-start',
      ],
    },
    {
      type: 'category',
      label: 'Platform Guides',
      collapsed: false,
      items: [
        'apex-guide',
        'lwc-guide',
        'aura-guide',
        'flow-guide',
        'omnistudio-guide',
      ],
    },
    {
      type: 'category',
      label: 'Features',
      collapsed: false,
      items: [
        'tagging-guide',
        'scenarios-guide',
        'log-management',
        'data-masking',
        'custom-fields',
      ],
    },
    {
      type: 'category',
      label: 'Administration',
      collapsed: false,
      items: [
        'admin-guide',
        'configuration-reference',
        'security',
      ],
    },
    {
      type: 'category',
      label: 'Advanced',
      collapsed: true,
      items: [
        'architecture',
        'performance',
        'plugin-development',
        'developer-guide',
        'architect-guide',
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      collapsed: true,
      items: [
        'api-reference',
        'metadata-reference',
        'best-practices',
        'troubleshooting',
        'faq',
        'changelog',
      ],
    },
  ],
};

module.exports = sidebars;
