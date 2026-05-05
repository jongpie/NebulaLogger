# Documentation Migration Plan

Complete plan for migrating Nebula Logger documentation to the new Docusaurus site.

## Current State

Documentation is currently spread across three locations:
1. **README.md** - Main repository README
2. **docs/** folder - GitHub Pages with Jekyll
3. **GitHub Wiki** - Separate wiki pages

## Target State

Consolidate all documentation in one place:
- **docs2/** - Source markdown files
- **website/** - Docusaurus site (deployed to GitHub Pages)
- **README2.md** - New streamlined README

## Migration Steps

### Phase 1: Setup Docusaurus ✅ COMPLETE

**Status:** Done! All files created.

**Created:**
- ✅ `website/` directory structure
- ✅ `docusaurus.config.js` - Complete configuration
- ✅ `sidebars.js` - Navigation structure
- ✅ `package.json` - Dependencies
- ✅ Custom CSS and components
- ✅ Homepage with features
- ✅ GitHub Actions workflow
- ✅ Blog setup with first post
- ✅ All documentation from docs2/ copied to website/docs/

### Phase 2: Deploy to GitHub Pages ⏳ NEXT

**Actions Required:**

1. **Install dependencies:**
   ```bash
   cd website
   npm install
   ```

2. **Test locally:**
   ```bash
   npm start
   ```
   Verify everything looks good at `http://localhost:3000`

3. **Enable GitHub Pages:**
   - Go to GitHub → Settings → Pages
   - Source: Deploy from a branch
   - Branch: `gh-pages`, folder: `/ (root)`
   - Save

4. **Enable GitHub Actions:**
   - Go to Settings → Actions → General
   - Workflow permissions: Read and write
   - Save

5. **Push to GitHub:**
   ```bash
   git add website/ DOCUMENTATION_MIGRATION_PLAN.md
   git commit -m "Add Docusaurus documentation site"
   git push origin main
   ```

6. **Verify deployment:**
   - Check Actions tab for workflow status
   - Visit `https://jongpie.github.io/NebulaLogger/`
   - Test navigation, search, mobile view

**Expected Timeline:** 30 minutes

### Phase 3: Apply for Algolia Search ⏳ WAITING

**Actions Required:**

1. **Apply for Algolia DocSearch:**
   - Visit: https://docsearch.algolia.com/apply/
   - Fill form:
     - URL: `https://jongpie.github.io/NebulaLogger/`
     - Email: Your email
     - Repo: `https://github.com/jongpie/NebulaLogger`
     - Check all boxes (documentation, open source, owner)
   - Submit

2. **Wait for approval:**
   - Typically 1-2 weeks
   - Algolia team reviews and approves

3. **Configure when approved:**
   - Update `website/docusaurus.config.js` with credentials
   - Push changes
   - Search will work within 24 hours

**Expected Timeline:** 1-2 weeks for approval

### Phase 4: Set Up Analytics ⏳ OPTIONAL

**Google Analytics:**

1. Create GA4 property
2. Get Measurement ID
3. Update `website/docusaurus.config.js`:
   ```javascript
   gtag: {
     trackingID: 'G-XXXXXXXXXX',
     anonymizeIP: true,
   },
   ```
4. Push changes

**OR Plausible (Privacy-Friendly):**

1. Sign up at plausible.io
2. Add domain
3. Update config with script
4. Push changes

**Expected Timeline:** 15 minutes

### Phase 5: Create Versioning ⏳ AFTER NEXT RELEASE

**When to do:** After v4.19.0 release

**Actions:**

1. **Create version snapshot:**
   ```bash
   cd website
   npm run version 4.19.0
   ```

2. **Verify:**
   - Check `versions.json`
   - Test version dropdown
   - Verify old docs preserved

3. **Document versioning process:**
   - Add to DEPLOYMENT.md
   - Train team on process

**Expected Timeline:** 10 minutes per release

### Phase 6: Add Blog Posts ⏳ ONGOING

**For each release:**

1. **Create blog post:**
   ```bash
   cd website/blog
   touch YYYY-MM-DD-vX-XX-X-release.md
   ```

2. **Write release notes:**
   - What's new
   - Breaking changes
   - Bug fixes
   - Migration guide

3. **Publish:**
   ```bash
   git add website/blog/
   git commit -m "Add vX.XX.X release notes"
   git push
   ```

**Expected Timeline:** 30 minutes per release

### Phase 7: Update Main README ⏳ AFTER DEPLOYMENT

**Actions:**

1. **Replace README.md with README2.md:**
   ```bash
   mv README.md README-old.md
   mv README2.md README.md
   ```

2. **Update links to point to new docs:**
   - Change wiki links to docs2 links
   - Update installation instructions
   - Add link to new docs site

3. **Add banner to old docs:**
   In `docs/` folder, add banner:
   ```markdown
   > ⚠️ **Documentation has moved!** 
   > Visit our new docs site: https://jongpie.github.io/NebulaLogger/
   ```

**Expected Timeline:** 15 minutes

### Phase 8: Archive Old Documentation ⏳ AFTER 30 DAYS

**After new docs are stable (30+ days):**

1. **Archive old docs folder:**
   ```bash
   mv docs docs-archived
   ```

2. **Archive wiki:**
   - Export wiki pages
   - Add to `/archived-wiki/` folder
   - Make wiki read-only with redirect

3. **Update .gitignore:**
   ```
   docs-archived/
   ```

4. **Clean up:**
   - Remove old Jekyll config
   - Remove old GitHub Pages setup

**Expected Timeline:** 20 minutes

## Testing Checklist

Before marking as complete, test:

### Desktop
- [ ] Homepage loads
- [ ] All doc pages load
- [ ] Navigation works
- [ ] Search works (after Algolia)
- [ ] Code blocks have copy button
- [ ] Links work (internal and external)
- [ ] Images load
- [ ] Dark mode works
- [ ] Version dropdown works (after versioning)

### Mobile
- [ ] Responsive layout
- [ ] Navigation menu works
- [ ] Search works
- [ ] Readable on small screens
- [ ] Touch interactions work

### Performance
- [ ] Lighthouse score > 90
- [ ] Fast page loads
- [ ] No console errors
- [ ] No broken links

## Rollback Plan

If something goes wrong:

1. **Revert deployment:**
   ```bash
   git revert <commit-hash>
   git push
   ```

2. **Disable GitHub Pages:**
   - Settings → Pages → Disable

3. **Restore old docs:**
   - Keep old docs/ folder until migration is stable
   - Can restore quickly if needed

## Communication Plan

### Internal Team

- [ ] Notify team of new docs site
- [ ] Share migration timeline
- [ ] Request feedback on new site
- [ ] Update team docs/wiki

### External Users

- [ ] Blog post announcing new docs
- [ ] Update README with link
- [ ] Social media announcement
- [ ] Update package description

### Timeline

- [ ] Day 1: Deploy new site
- [ ] Day 7: Apply for Algolia
- [ ] Day 14: Announce new site
- [ ] Day 30: Archive old docs

## Success Metrics

Track these metrics:

### Adoption
- [ ] Page views on new site
- [ ] Search usage
- [ ] Time on page
- [ ] Bounce rate

### Quality
- [ ] User feedback
- [ ] GitHub issues about docs
- [ ] Search success rate
- [ ] Mobile usage

### Maintenance
- [ ] Time to update docs
- [ ] Deployment frequency
- [ ] Build time
- [ ] Number of broken links

## Resources

### Documentation
- [Docusaurus Setup Guide](website/SETUP.md)
- [Deployment Guide](website/DEPLOYMENT.md)
- [Website README](website/README.md)

### Tools
- **Docusaurus**: https://docusaurus.io/
- **Algolia**: https://docsearch.algolia.com/
- **GitHub Pages**: https://pages.github.com/

### Support
- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and ideas
- **Docusaurus Discord**: For Docusaurus-specific help

## Questions & Answers

### Why Docusaurus?

- Used by React, Jest, Facebook, Babel, and many major projects
- Excellent documentation-focused features
- Built-in versioning
- Great search (Algolia)
- Modern React-based
- Active community

### Why not just Jekyll?

- Jekyll is older, less maintained
- Docusaurus has better search
- Better versioning support
- More modern features (dark mode, etc.)
- Better developer experience

### What about the Wiki?

- Wiki will be archived
- All content moved to new docs
- Wiki made read-only with redirect
- Preserves history but consolidates docs

### When will search work?

- Search requires Algolia approval (1-2 weeks)
- Free for open source projects
- Once approved, works within 24 hours
- Meanwhile, users can use browser Ctrl+F

### Can we use a custom domain?

Yes! To use docs.nebulalogger.com:
1. Add CNAME to website/static/
2. Update docusaurus.config.js
3. Configure DNS
4. Enable in GitHub Pages settings

## Next Actions

**Immediate (Today):**
1. ✅ Review this plan
2. ⏳ Install dependencies
3. ⏳ Test locally
4. ⏳ Deploy to GitHub Pages

**This Week:**
1. ⏳ Apply for Algolia
2. ⏳ Set up analytics
3. ⏳ Update main README
4. ⏳ Announce new docs

**This Month:**
1. ⏳ Create first version snapshot
2. ⏳ Write blog posts
3. ⏳ Get user feedback
4. ⏳ Archive old docs

---

## Status Tracking

- [x] Phase 1: Setup Docusaurus
- [ ] Phase 2: Deploy to GitHub Pages
- [ ] Phase 3: Apply for Algolia
- [ ] Phase 4: Set up Analytics
- [ ] Phase 5: Create Versioning
- [ ] Phase 6: Add Blog Posts
- [ ] Phase 7: Update Main README
- [ ] Phase 8: Archive Old Docs

**Current Status:** Ready for Phase 2 (Deployment)

**Next Action:** Install dependencies and test locally

**Owner:** Jonathan Gillespie

**Last Updated:** 2024-04-23
