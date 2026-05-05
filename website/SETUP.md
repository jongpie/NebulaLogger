# Docusaurus Setup Guide for Nebula Logger

Complete setup instructions for the new Docusaurus documentation site.

## Step 1: Install Dependencies

```bash
cd website
npm install
```

This installs all required dependencies including Docusaurus, React, and plugins.

## Step 2: Test Locally

```bash
npm start
```

This starts a local development server at `http://localhost:3000`. The site will automatically reload when you make changes.

**Expected output:**
```
[INFO] Starting the development server...
[SUCCESS] Docusaurus website is running at http://localhost:3000/
```

Open your browser and verify the site looks correct.

## Step 3: Build the Site

```bash
npm run build
```

This creates a production build in the `build/` directory.

**Verify the build:**
```bash
npm run serve
```

Open `http://localhost:3000` to preview the production build.

## Step 4: Set Up GitHub Pages

### Enable GitHub Pages

1. Go to your GitHub repository
2. Click **Settings**
3. Scroll to **Pages** (left sidebar)
4. Under **Source**:
   - Select **Deploy from a branch**
   - Branch: `gh-pages`
   - Folder: `/ (root)`
5. Click **Save**

### Configure GitHub Actions

1. Go to **Settings → Actions → General**
2. Under **Workflow permissions**:
   - Select **Read and write permissions**
   - Check **Allow GitHub Actions to create and approve pull requests**
3. Click **Save**

## Step 5: Deploy

### Option A: Automatic Deployment (Recommended)

Simply push your changes:

```bash
git add website/
git commit -m "Add Docusaurus documentation site"
git push origin main
```

GitHub Actions will automatically build and deploy the site.

**Monitor deployment:**
- Go to **Actions** tab in GitHub
- Watch the "Deploy to GitHub Pages" workflow

### Option B: Manual Deployment

Deploy manually from your machine:

```bash
cd website
npm run deploy
```

This builds and pushes to the `gh-pages` branch.

## Step 6: Apply for Algolia DocSearch

Algolia DocSearch is **FREE** for open source projects!

### Apply

1. Go to https://docsearch.algolia.com/apply/
2. Fill out the form:
   - **Website URL**: `https://jongpie.github.io/NebulaLogger/`
   - **Email**: Your email
   - **Repository**: `https://github.com/jongpie/NebulaLogger`
   - Check boxes:
     - ✅ It is a documentation website
     - ✅ It is an open source project
     - ✅ You are the owner

3. Submit and wait for approval (1-2 weeks)

### Configure Once Approved

When Algolia emails you:

1. Open `website/docusaurus.config.js`
2. Update the Algolia section:
```javascript
algolia: {
  appId: 'YOUR_APP_ID',          // From Algolia email
  apiKey: 'YOUR_SEARCH_API_KEY', // From Algolia email  
  indexName: 'nebula-logger',    // From Algolia email
  contextualSearch: true,
},
```

3. Commit and push:
```bash
git add website/docusaurus.config.js
git commit -m "Configure Algolia search"
git push
```

The search will start working within 24 hours after Algolia indexes your site.

## Step 7: Set Up Analytics (Optional)

### Google Analytics

1. Create a Google Analytics 4 property
2. Get your Measurement ID (format: `G-XXXXXXXXXX`)
3. Update `website/docusaurus.config.js`:
```javascript
gtag: {
  trackingID: 'G-XXXXXXXXXX',
  anonymizeIP: true,
},
```

### Plausible (Privacy-Friendly Alternative)

1. Sign up at https://plausible.io/
2. Add your domain
3. Update `website/docusaurus.config.js`:
```javascript
scripts: [
  {
    src: 'https://plausible.io/js/script.js',
    'data-domain': 'jongpie.github.io',
    defer: true,
  },
],
```

## Step 8: Create Version Snapshots

When you release a new version:

```bash
cd website
npm run version 4.19.0
```

This creates a version snapshot of the current documentation.

Users can then select versions from the dropdown in the navbar.

## Step 9: Add Blog Posts for Releases

Create release notes as blog posts:

```bash
cd website/blog
```

Create file: `2024-05-01-v4-19-0-release.md`:

```markdown
---
slug: v4-19-0-release
title: Nebula Logger v4.19.0 Released
authors: [jongpie]
tags: [release, v4.19.0, new-features]
---

## What's New in v4.19.0

- New feature 1
- New feature 2
- Bug fix 1

<!--truncate-->

### Full Changelog

...
```

## Step 10: Customize Branding

### Add Logo

1. Add your logo to `website/static/img/logo.svg`
2. It will automatically appear in the navbar

### Update Colors

Edit `website/src/css/custom.css`:

```css
:root {
  --ifm-color-primary: #your-color;
  --ifm-color-primary-dark: #your-dark-color;
  /* etc */
}
```

### Create Social Card

1. Create an image: `website/static/img/nebula-logger-social-card.jpg`
   - Recommended size: 1200x630px
   - This appears when sharing on Twitter/LinkedIn

2. It's automatically configured in `docusaurus.config.js`

## Verification Checklist

After setup, verify:

- [ ] Local development works (`npm start`)
- [ ] Production build works (`npm run build`)
- [ ] GitHub Pages is enabled
- [ ] GitHub Actions workflow runs successfully
- [ ] Site is accessible at `https://jongpie.github.io/NebulaLogger/`
- [ ] All pages load correctly
- [ ] Navigation works
- [ ] Search works (after Algolia setup)
- [ ] Mobile responsive
- [ ] Dark mode works

## Troubleshooting

### Build Fails

```bash
cd website
npm run clear
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Site Not Accessible

1. Check GitHub Pages settings
2. Wait 5-10 minutes after first deployment
3. Check GitHub Actions for errors

### Search Not Working

1. Algolia needs 24 hours to index after first setup
2. Verify credentials in `docusaurus.config.js`
3. Check Algolia dashboard

### Images Not Loading

1. Place images in `website/static/img/`
2. Reference as `/img/filename.png` in markdown
3. Don't use relative paths like `../images/`

## Maintenance

### Update Dependencies

Monthly:
```bash
cd website
npm outdated
npm update
npm test
```

### Major Upgrades

When new Docusaurus versions release:
```bash
npx @docusaurus/upgrade@latest
```

## Resources

- **Docusaurus Docs**: https://docusaurus.io/docs
- **Markdown Guide**: https://www.markdownguide.org/
- **MDX Docs**: https://mdxjs.com/
- **Algolia DocSearch**: https://docsearch.algolia.com/

## Next Steps

1. ✅ Complete this setup
2. ✅ Deploy to GitHub Pages
3. ⏳ Apply for Algolia DocSearch
4. ⏳ Add Google Analytics
5. ⏳ Create custom logo
6. ⏳ Write blog post about new docs site
7. ⏳ Update main README to link to new docs

## Support

If you encounter issues:
1. Check [Troubleshooting](#troubleshooting) section
2. Review Docusaurus docs
3. Open an issue on GitHub

---

**Questions?** Feel free to reach out or open a discussion on GitHub!
