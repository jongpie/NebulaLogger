# Installation Guide

This guide covers how to install Nebula Logger in your Salesforce org.

## Package Options

Nebula Logger is available as both an **unlocked package** and a **managed package**.

### Unlocked Package (Recommended)

**Version**: v4.16.4  
**Namespace**: None

#### Installation Commands

```bash
sf package install --wait 20 --security-type AdminsOnly --package 04tKe0000011MyWIAU
```

#### Installation Links

- [Install in Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tKe0000011MyWIAU)
- [Install in Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKe0000011MyWIAU)

### Managed Package

**Version**: v4.16.0  
**Namespace**: `Nebula`

#### Installation Commands

```bash
sf package install --wait 30 --security-type AdminsOnly --package 04t5Y0000015pGtQAI
```

## Post-Installation Setup

1. **Assign Permission Sets** to users
2. **Configure Settings** in LoggerSettings__c
3. **Set up Data Masking** (optional)
4. **Configure Tagging Rules** (optional)

## Next Steps

- [Quick Start Guide](quick-start.md)
- [Configuration](configuration.md)
