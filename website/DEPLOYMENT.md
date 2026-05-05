# Deployment Guide for Nebula Logger Documentation

## Overview

The Nebula Logger documentation site is built with Docusaurus and deployed to GitHub Pages.

## Deployment Methods

### Method 1: Automatic Deployment (Recommended)

The site automatically deploys when you push changes to the `main` branch.

**How it works:**
1. You push changes to `main`
2. GitHub Actions workflow triggers (`.github/workflows/deploy.yml`)
3. Workflow builds the site
4. Deploys to GitHub Pages
5. Site is live at `https://jongpie.github.io/NebulaLogger/`

**To trigger:**
```bash
git add website/
git commit -m "Update documentation"
git push origin main
```

### Method 2: Manual Deployment

Deploy manually from your local machine:

```bash
cd website
npm run deploy
```

This command:
1. Builds the static site
2. Pushes to `gh-pages` branch
3. GitHub Pages serves the content

### Method 3: Local Build

Build locally to test before deploying:

```bash
cd website
npm run build
npm run serve
```

Open `http://localhost:3000` to preview.

## Initial Setup

### 1. Enable GitHub Pages

1. Go to GitHub repository **Settings**
2. Navigate to **Pages**
3. Under **Source**, select:
   - **Deploy from a branch**
   - Branch: `gh-pages`
   - Folder: `/ (root)`
4. Click **Save**

### 2. Configure GitHub Actions

The workflow is already created at `website/.github/workflows/deploy.yml`.

To enable:
1. Go to repository **Settings → Actions → General**
2. Under **Workflow permissions**, select:
   - **Read and write permissions**
3. Click **Save**

### 3. Set Repository Secrets (Optional)

For Google Analytics or other integrations:

1. Go to **Settings → Secrets and variables → Actions**
2. Add secrets:
   - `GA_TRACKING_ID` (Google Analytics)
   - `ALGOLIA_APP_ID` (Algolia Search)
   - `ALGOLIA_API_KEY` (Algolia Search)

## Configuration

### Base URL

Update `docusaurus.config.js`:

```javascript
module.exports = {
  url: 'https://jongpie.github.io',
  baseUrl: '/NebulaLogger/',
  // ...
};
```

### Custom Domain (Optional)

To use a custom domain (e.g., `docs.nebulalogger.com`):

1. Add `CNAME` file to `website/static/`:
```
docs.nebulalogger.com
```

2. Update `docusaurus.config.js`:
```javascript
module.exports = {
  url: 'https://docs.nebulalogger.com',
  baseUrl: '/',
  // ...
};
```

3. Configure DNS:
   - Add CNAME record pointing to `jongpie.github.io`

4. Enable in GitHub:
   - **Settings → Pages → Custom domain**
   - Enter your domain
   - Wait for DNS check

## Versioning

### Create New Version

When releasing a new version:

```bash
cd website
npm run version 4.19.0
```

This creates:
- `versioned_docs/version-4.19.0/` - Snapshot of current docs
- `versioned_sidebars/version-4.19.0-sidebars.json` - Sidebar config
- Updates `versions.json`

### Version Dropdown

Users can switch versions via dropdown in navbar.

Current version is always labeled "Latest" or "Next".

## Blog Posts

### Adding Release Notes

Create a new blog post for each release:

```bash
cd website/blog
touch 2024-05-01-v4-19-0-release.md
```

```markdown
---
slug: v4-19-0-release
title: Nebula Logger v4.19.0 Released
authors: [jongpie]
tags: [release, v4.19.0]
---

# v4.19.0 Release Notes

## New Features

- Feature 1
- Feature 2

## Bug Fixes

- Fix 1
- Fix 2

<!--truncate-->

## Full Changelog

...
```

## Search (Algolia)

### Apply for Algolia DocSearch

1. Go to https://docsearch.algolia.com/apply/
2. Fill out the form (free for open source)
3. Wait for approval (1-2 weeks)
4. Receive `appId` and `apiKey`

### Configure Algolia

Update `docusaurus.config.js`:

```javascript
algolia: {
  appId: 'YOUR_APP_ID',
  apiKey: 'YOUR_SEARCH_API_KEY',
  indexName: 'nebula-logger',
  contextualSearch: true,
},
```

### Crawler Configuration

Algolia will provide a crawler configuration. If needed, you can also set up your own crawler.

## Analytics

### Google Analytics

Update `docusaurus.config.js`:

```javascript
gtag: {
  trackingID: 'G-XXXXXXXXXX',
  anonymizeIP: true,
},
```

### Plausible Analytics (Privacy-Friendly)

Add script to `docusaurus.config.js`:

```javascript
scripts: [
  {
    src: 'https://plausible.io/js/script.js',
    'data-domain': 'jongpie.github.io',
    defer: true,
  },
],
```

## Monitoring

### Check Deployment Status

- **GitHub Actions**: Repository → Actions tab
- **GitHub Pages**: Settings → Pages → Status indicator

### Common Issues

**Build fails:**
```bash
cd website
npm run clear
rm -rf node_modules
npm install
npm run build
```

**Broken links:**
- Docusaurus checks for broken links during build
- Fix any errors before deploying

**404 errors:**
- Check `baseUrl` in `docusaurus.config.js`
- Ensure GitHub Pages is enabled
- Wait 5-10 minutes for deployment to complete

## Performance

### Lighthouse Scores

Docusaurus is optimized for performance:
- Performance: 90+
- Accessibility: 90+
- Best Practices: 90+
- SEO: 90+

### Bundle Size

To check bundle size:
```bash
npm run build
ls -lh build/
```

## Backup

### Backup Strategy

- **Git** - All source files in repository
- **GitHub Pages** - Automatic backup of deployed site
- **Versions** - Old versions preserved in `versioned_docs/`

### Restore Previous Version

```bash
git checkout <commit-hash> -- website/docs/
npm run deploy
```

## Maintenance

### Update Dependencies

```bash
cd website
npm outdated
npm update
```

### Major Version Upgrades

```bash
npx @docusaurus/upgrade@latest
```

## Troubleshooting

### Build Errors

1. Clear cache: `npm run clear`
2. Reinstall: `rm -rf node_modules && npm install`
3. Check Node version: `node --version` (should be 18+)

### Deployment Errors

1. Check GitHub Actions logs
2. Verify GitHub Pages is enabled
3. Check branch is `gh-pages`

### Search Not Working

1. Verify Algolia credentials
2. Wait for initial indexing (can take 24 hours)
3. Check Algolia dashboard

## Resources

- [Docusaurus Deployment Docs](https://docusaurus.io/docs/deployment)
- [GitHub Pages Docs](https://docs.github.com/en/pages)
- [Algolia DocSearch](https://docsearch.algolia.com/)

## Support

For deployment issues:
1. Check GitHub Actions logs
2. Review [Troubleshooting Guide](../docs/troubleshooting.md)
3. Open an issue on GitHub
