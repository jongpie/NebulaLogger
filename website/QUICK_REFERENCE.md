# Docusaurus Quick Reference

Quick commands and tips for working with the Nebula Logger documentation site.

## Daily Commands

```bash
# Start development server
cd website && npm start

# Build for production
npm run build

# Test production build locally
npm run serve

# Deploy to GitHub Pages
npm run deploy
```

## Creating Content

### Add New Doc Page

1. Create file: `website/docs/my-new-doc.md`
2. Add frontmatter:
```markdown
---
sidebar_position: 10
title: My New Doc
description: Brief description
---

# My New Doc

Content here...
```

3. File automatically appears in sidebar (or add to `sidebars.js` for custom position)

### Add Blog Post

1. Create file: `website/blog/YYYY-MM-DD-my-post.md`
2. Add frontmatter:
```markdown
---
slug: my-post
title: My Blog Post Title
authors: [jongpie]
tags: [release, feature]
---

Summary paragraph...

<!--truncate-->

Full content here...
```

### Add Images

1. Place in `website/static/img/`
2. Reference in markdown:
```markdown
![Alt text](/img/my-image.png)
```

## Frontmatter Options

### For Docs

```markdown
---
sidebar_position: 5          # Order in sidebar
sidebar_label: Short Name    # Custom sidebar text
title: Page Title           # Browser title
description: SEO description # Meta description
---
```

### For Blog

```markdown
---
slug: url-slug              # URL slug
title: Post Title          # Browser title
authors: [jongpie]        # Author(s)
tags: [tag1, tag2]        # Tags for filtering
---
```

## Markdown Features

### Admonitions (Callouts)

```markdown
:::note
This is a note
:::

:::tip
This is a tip
:::

:::info
This is info
:::

:::caution
This is a caution
:::

:::danger
This is a danger warning
:::
```

### Code Blocks

````markdown
```apex title="Logger Example"
Logger.info('Hello, world!');
Logger.saveLog();
```
````

### Tabs

```markdown
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

<Tabs>
  <TabItem value="apex" label="Apex" default>
    ```apex
    Logger.info('Apex example');
    ```
  </TabItem>
  <TabItem value="javascript" label="JavaScript">
    ```javascript
    logger.info('JS example');
    ```
  </TabItem>
</Tabs>
```

## Sidebar Configuration

Edit `website/sidebars.js`:

```javascript
const sidebars = {
  docs: [
    'overview',  // Single doc
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: ['installation', 'quick-start'],
    },
  ],
};
```

## Versioning

### Create Version Snapshot

```bash
npm run version 4.19.0
```

This creates:
- `versioned_docs/version-4.19.0/`
- `versioned_sidebars/version-4.19.0-sidebars.json`
- Updates `versions.json`

### Edit Versioned Docs

- **Current docs**: Edit files in `docs/`
- **Version 4.18.0**: Edit files in `versioned_docs/version-4.18.0/`

## Configuration

### Update Theme Colors

Edit `website/src/css/custom.css`:

```css
:root {
  --ifm-color-primary: #2e8555;
}
```

### Update Navbar

Edit `website/docusaurus.config.js`:

```javascript
navbar: {
  items: [
    {
      to: '/docs/overview',
      label: 'Docs',
      position: 'left',
    },
  ],
},
```

### Update Footer

Edit `website/docusaurus.config.js`:

```javascript
footer: {
  links: [
    {
      title: 'Docs',
      items: [
        {label: 'Getting Started', to: '/docs/quick-start'},
      ],
    },
  ],
},
```

## Search (Algolia)

### Configuration

In `docusaurus.config.js`:

```javascript
algolia: {
  appId: 'YOUR_APP_ID',
  apiKey: 'YOUR_API_KEY',
  indexName: 'nebula-logger',
},
```

### Customize Search

```javascript
algolia: {
  contextualSearch: true,      // Search within version
  searchParameters: {
    facetFilters: ['language:en'],
  },
},
```

## Analytics

### Google Analytics

```javascript
gtag: {
  trackingID: 'G-XXXXXXXXXX',
  anonymizeIP: true,
},
```

### Custom Scripts

```javascript
scripts: [
  {
    src: 'https://example.com/script.js',
    async: true,
  },
],
```

## Common Tasks

### Update All Dependencies

```bash
npm outdated
npm update
npm test
```

### Upgrade Docusaurus

```bash
npx @docusaurus/upgrade@latest
```

### Clear Cache

```bash
npm run clear
```

### Fix Build Errors

```bash
npm run clear
rm -rf node_modules
npm install
npm run build
```

## Git Workflow

### Typical workflow:

```bash
# Make changes
vim website/docs/my-doc.md

# Test locally
npm start

# Build to verify
npm run build

# Commit
git add website/
git commit -m "Update documentation"

# Push (triggers auto-deploy)
git push origin main
```

## Troubleshooting

### Build Fails

```bash
npm run clear && npm run build
```

### Port Already in Use

```bash
npm start -- --port 3001
```

### Images Not Loading

- Use `/img/filename.png` not `../images/`
- Place in `website/static/img/`

### Search Not Working

- Wait 24 hours after Algolia setup
- Check credentials in config
- Verify site is indexed in Algolia dashboard

## File Structure

```
website/
├── blog/                  # Blog posts
│   └── 2024-04-23-*.md
├── docs/                  # Current docs
│   ├── overview.md
│   └── ...
├── versioned_docs/        # Old version snapshots
│   └── version-4.18.0/
├── src/
│   ├── components/        # React components
│   ├── css/              # Custom styles
│   └── pages/            # Custom pages
├── static/
│   └── img/              # Static images
├── docusaurus.config.js  # Main config
├── sidebars.js           # Navigation
└── package.json          # Dependencies
```

## Useful Links

- **Docusaurus Docs**: https://docusaurus.io/docs
- **MDX**: https://mdxjs.com/
- **Markdown Guide**: https://www.markdownguide.org/
- **React**: https://react.dev/

## Tips & Tricks

### Use MDX for Interactive Docs

```mdx
import MyComponent from '@site/src/components/MyComponent';

# My Doc

<MyComponent />
```

### Create Reusable Content

```markdown
<!-- partials/_installation.md -->
Install the package...

<!-- In any doc -->
import Installation from '@site/docs/partials/_installation.md';

<Installation />
```

### Hide Content from Sidebar

```markdown
---
sidebar_class_name: hidden
---
```

### Custom Edit URL per Doc

```markdown
---
custom_edit_url: https://github.com/myrepo/edit/main/docs/myfile.md
---
```

## Need Help?

1. Check Docusaurus docs
2. Search GitHub issues
3. Ask in Docusaurus Discord
4. Open issue on NebulaLogger repo
