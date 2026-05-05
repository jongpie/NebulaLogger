# Nebula Logger Documentation Website

This directory contains the Docusaurus-based documentation website for Nebula Logger.

## Local Development

### Prerequisites

- Node.js 18.0 or higher
- npm 7.0 or higher

### Installation

```bash
cd website
npm install
```

### Start Development Server

```bash
npm start
```

This starts a local development server and opens a browser window. Most changes are reflected live without having to restart the server.

### Build

```bash
npm run build
```

This command generates static content into the `build` directory that can be served using any static hosting service.

### Deploy to GitHub Pages

```bash
npm run deploy
```

This command builds the website and pushes to the `gh-pages` branch. The GitHub Actions workflow also automatically deploys on push to `main`.

## Project Structure

```
website/
├── blog/                   # Blog posts (release notes, updates)
├── docs/                   # Documentation markdown files
├── src/
│   ├── components/         # React components
│   ├── css/               # Custom CSS
│   └── pages/             # Custom pages (homepage, etc.)
├── static/
│   └── img/               # Static images
├── docusaurus.config.js   # Site configuration
├── sidebars.js            # Sidebar navigation
└── package.json           # Dependencies
```

## Documentation

### Adding a New Doc

1. Create a new `.md` file in `docs/`
2. Add frontmatter:
```markdown
---
sidebar_position: 5
title: My New Doc
description: Brief description
---

# My New Doc

Content here...
```

3. Add to `sidebars.js` if you want custom positioning

### Adding a Blog Post

1. Create a new `.md` file in `blog/` with format: `YYYY-MM-DD-slug.md`
2. Add frontmatter:
```markdown
---
slug: my-post
title: My Blog Post
authors: [jongpie]
tags: [release, feature]
---

Content here...
```

### Versioning

To create a new version snapshot:

```bash
npm run version 4.19.0
```

This creates a snapshot of current docs in `versioned_docs/` and adds version to `versions.json`.

## Customization

### Theme

Edit `src/css/custom.css` to customize colors, fonts, and styling.

### Homepage

Edit `src/pages/index.js` to customize the homepage.

### Navigation

Edit `docusaurus.config.js` to customize the navbar and footer.

## Algolia Search Setup

To enable Algolia DocSearch (free for open source):

1. Apply at https://docsearch.algolia.com/
2. Receive your `appId` and `apiKey`
3. Update `docusaurus.config.js`:
```javascript
algolia: {
  appId: 'YOUR_APP_ID',
  apiKey: 'YOUR_API_KEY',
  indexName: 'nebula-logger',
},
```

## Social Cards

To generate social preview cards:

1. Add images to `static/img/`
2. Update `docusaurus.config.js`:
```javascript
themeConfig: {
  image: 'img/nebula-logger-social-card.jpg',
}
```

## Deployment

### GitHub Actions (Automatic)

The site automatically deploys to GitHub Pages when you push to `main` branch. See `.github/workflows/deploy.yml`.

### Manual Deployment

```bash
npm run deploy
```

## Troubleshooting

### Build Fails

Clear the cache:
```bash
npm run clear
npm run build
```

### Broken Links

Check for broken links:
```bash
npm run build
```

Docusaurus will throw errors for broken internal links.

## Resources

- [Docusaurus Documentation](https://docusaurus.io/)
- [Markdown Guide](https://www.markdownguide.org/)
- [MDX Documentation](https://mdxjs.com/)
