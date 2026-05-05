---
sidebar_position: 21
title: Changelog
description: Version history and release notes for Nebula Logger
keywords: [changelog, releases, versions, history]
---

# Changelog

Version history and release notes for Nebula Logger.

## Version 4.18.0 (Current) - Winter '26

**Release Date:** 2024-04

### New Features
- Enhanced log entry field tracking
- Improved data masking capabilities
- Updated LWC components with latest code standards
- Performance optimizations for high-volume logging

### Bug Fixes
- Fixed Apex test failure in system-generated messages
- Resolved LWC Jest test issues
- Updated code analyzer compliance

### Technical Updates
- Salesforce API Version: v65.0
- Node.js requirement: >= 20.16.0
- Updated npm dependencies

---

## Version 4.17.0

**Release Date:** 2024-03

### New Features
- Additional logging context fields
- Enhanced scenario tracking
- Improved plugin framework

### Bug Fixes
- Various stability improvements
- Performance optimizations

---

## Version 4.16.0

### New Features
- Enhanced tagging system
- Improved data masking rules
- Additional custom metadata types

---

## Version 4.15.0

### New Features
- Platform event enhancements
- Improved async processing
- Enhanced error handling

---

## Version 4.14.10

### New Features
- **CallableLogger** - Dynamic invocation for ISVs
- Optional dependency support for packages
- Enhanced ISV integration options

### Breaking Changes
None

---

## Version 4.x Series Highlights

### Major Capabilities Added
- ✅ Multi-platform support (Apex, LWC, Aura, Flow, OmniStudio)
- ✅ Event-driven architecture
- ✅ Tag and scenario systems
- ✅ Data masking framework
- ✅ Plugin framework
- ✅ Hierarchy custom settings
- ✅ Big Object archiving
- ✅ Slack integration plugin

---

## Version 3.x → 4.x Migration

### Breaking Changes
- Platform event field structure updated
- Custom metadata configuration changes
- Some field name standardizations

### Migration Path
See [Migration Guide](migrations/migrate-from-v3-to-v4.md) for detailed instructions.

---

## Upgrade Instructions

### Unlocked Package

```bash
# Get latest version ID from GitHub releases
sf package install --wait 20 --security-type AdminsOnly --package [VERSION_ID]
```

### Managed Package

Automatic updates via AppExchange or manual install from GitHub releases.

---

## Release Cadence

### Unlocked Package
- **Patch versions** (v4.x.x): Released as needed for bug fixes and minor enhancements
- Typically 1-2 releases per month
- Announced via GitHub Releases

### Managed Package
- **Minor versions** (v4.x): Released after stabilization period
- Typically 1-2 releases per quarter
- Announced via AppExchange and GitHub

---

## Deprecation Policy

### Deprecation Notice Period
- **Public APIs**: Minimum 2 major versions notice
- **Custom Metadata**: Minimum 1 major version notice
- **Settings**: Minimum 1 minor version notice

### Currently Deprecated
None

---

## Future Roadmap

### Planned for v4.19.0
- Enhanced performance metrics
- Additional LWC components
- Improved documentation
- More plugin examples

### Under Consideration
- GraphQL API support
- Advanced analytics dashboards
- AI-powered log analysis
- Enhanced mobile experience

See [GitHub Milestones](https://github.com/jongpie/NebulaLogger/milestones) for detailed roadmap.

---

## Version Support

### Supported Versions
- **v4.18.x**: Full support
- **v4.17.x**: Security fixes only
- **v4.16.x**: Security fixes only
- **v4.15.x and older**: End of life

### Support Policy
- Latest version: Full support (bug fixes, enhancements, security)
- N-1 version: Bug fixes and security only
- N-2 version: Security fixes only
- Older versions: Not supported (upgrade recommended)

---

## Breaking Changes History

### v4.18.0
- None

### v4.17.0
- None

### v4.0.0
- Platform event structure changed
- Custom metadata configuration reorganized
- Some field names standardized
- Migration guide provided

---

## Security Updates

### CVE Tracking
No known security vulnerabilities.

### Security Policy
- Security issues handled privately
- Report via GitHub Security Advisories
- Patches released ASAP for supported versions

---

## How to Stay Updated

### GitHub Releases
- ⭐ Star the repository
- 👀 Watch for releases
- 📧 Enable release notifications

### GitHub Discussions
- Follow announcements category
- Join community discussions

### Social Media
- Follow project updates
- Announce major releases

---

## Release Notes Archive

Detailed release notes for each version available at:
- [GitHub Releases](https://github.com/jongpie/NebulaLogger/releases)
- [Managed Package Milestones](https://github.com/jongpie/NebulaLogger/milestones?state=closed)

---

## Contributing to Releases

### Feature Requests
- Open GitHub Discussion
- Explain use case
- Propose solution

### Bug Reports
- Open GitHub Issue
- Provide reproduction steps
- Include version information

### Pull Requests
See [Developer Guide](developer-guide.md) for contribution guidelines.

---

**Current Version:** v4.18.0  
**Latest Release:** [View on GitHub](https://github.com/jongpie/NebulaLogger/releases/latest)  
**Next Release:** v4.19.0 (estimated 2024-05)
