// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Nebula Logger',
  tagline: 'The most robust observability solution for Salesforce',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://jongpie.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  baseUrl: '/NebulaLogger/',

  // GitHub pages deployment config.
  organizationName: 'jongpie',
  projectName: 'NebulaLogger',
  trailingSlash: false,

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Link to GitHub repo for "Edit this page"
          editUrl: 'https://github.com/jongpie/NebulaLogger/tree/main/website/',
          // Show last update time and author
          showLastUpdateAuthor: true,
          showLastUpdateTime: true,
          // Versioning
          lastVersion: 'current',
          versions: {
            current: {
              label: 'v4.18.0 (Latest)',
              path: '',
            },
          },
        },
        blog: {
          showReadingTime: true,
          blogTitle: 'Nebula Logger Blog',
          blogDescription: 'Release notes, tips, and updates for Nebula Logger',
          postsPerPage: 10,
          blogSidebarTitle: 'Recent posts',
          blogSidebarCount: 'ALL',
          editUrl: 'https://github.com/jongpie/NebulaLogger/tree/main/website/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
        // Google Analytics or other analytics
        gtag: {
          trackingID: 'G-XXXXXXXXXX', // Replace with your tracking ID
          anonymizeIP: true,
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Social card for Twitter/LinkedIn previews
      image: 'img/nebula-logger-social-card.jpg',

      navbar: {
        title: 'Nebula Logger',
        logo: {
          alt: 'Nebula Logger Logo',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'docs',
            position: 'left',
            label: 'Documentation',
          },
          {
            to: '/blog',
            label: 'Blog',
            position: 'left'
          },
          {
            type: 'docsVersionDropdown',
            position: 'right',
            dropdownActiveClassDisabled: true,
          },
          {
            href: 'https://github.com/jongpie/NebulaLogger',
            label: 'GitHub',
            position: 'right',
          },
          {
            href: 'https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg70000001jUXAAY',
            label: 'Install',
            position: 'right',
            className: 'header-install-link',
          },
        ],
      },

      footer: {
        style: 'dark',
        links: [
          {
            title: 'Documentation',
            items: [
              {
                label: 'Quick Start',
                to: '/docs/quick-start',
              },
              {
                label: 'Installation',
                to: '/docs/installation',
              },
              {
                label: 'Apex Guide',
                to: '/docs/apex-guide',
              },
              {
                label: 'Best Practices',
                to: '/docs/best-practices',
              },
            ],
          },
          {
            title: 'Platform Guides',
            items: [
              {
                label: 'Lightning Web Components',
                to: '/docs/lwc-guide',
              },
              {
                label: 'Aura Components',
                to: '/docs/aura-guide',
              },
              {
                label: 'Flow Builder',
                to: '/docs/flow-guide',
              },
              {
                label: 'OmniStudio',
                to: '/docs/omnistudio-guide',
              },
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'GitHub Discussions',
                href: 'https://github.com/jongpie/NebulaLogger/discussions',
              },
              {
                label: 'Issues',
                href: 'https://github.com/jongpie/NebulaLogger/issues',
              },
              {
                label: 'Changelog',
                to: '/docs/changelog',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'Blog',
                to: '/blog',
              },
              {
                label: 'GitHub',
                href: 'https://github.com/jongpie/NebulaLogger',
              },
              {
                label: 'License',
                href: 'https://github.com/jongpie/NebulaLogger/blob/main/LICENSE',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Jonathan Gillespie. Built with Docusaurus. <a href="https://github.com/jongpie/NebulaLogger/blob/main/LICENSE" target="_blank" rel="noopener noreferrer">MIT License</a>.`,
      },

      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ['java', 'apex', 'bash', 'json', 'javascript', 'typescript', 'jsx'],
      },

      // Algolia DocSearch - FREE for open source!
      algolia: {
        // The application ID provided by Algolia
        appId: 'YOUR_APP_ID',

        // Public API key: it is safe to commit it
        apiKey: 'YOUR_SEARCH_API_KEY',

        indexName: 'nebula-logger',

        // Optional: see doc section below
        contextualSearch: true,

        // Optional: Algolia search parameters
        searchParameters: {},

        // Optional: path for search page that enabled by default (`false` to disable it)
        searchPagePath: 'search',
      },

      // Announcement bar for important updates
      announcementBar: {
        id: 'latest_release',
        content:
          '⭐️ If you like Nebula Logger, give it a star on <a target="_blank" rel="noopener noreferrer" href="https://github.com/jongpie/NebulaLogger">GitHub</a>! ⭐️',
        backgroundColor: '#fafbfc',
        textColor: '#091E42',
        isCloseable: true,
      },

      // Color mode
      colorMode: {
        defaultMode: 'light',
        disableSwitch: false,
        respectPrefersColorScheme: true,
      },
    }),

  // Plugins for enhanced functionality
  plugins: [
    [
      '@docusaurus/plugin-client-redirects',
      {
        redirects: [
          {
            to: '/docs/overview',
            from: ['/docs', '/docs/'],
          },
        ],
      },
    ],
  ],
};

module.exports = config;
