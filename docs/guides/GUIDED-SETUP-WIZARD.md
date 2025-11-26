# Guided Setup Wizard - Quick Start

**5-Minute Setup for Kelteks API Integration**

The Guided Setup Wizard automates the configuration of both BC17 and BC27 environments, making multi-application setup fast and error-free.

## Overview

The wizard provides:
- ✅ **Automated environment detection** (On-Premise vs SaaS)
- ✅ **Pre-filled configuration** with sensible defaults
- ✅ **Step-by-step guidance** through all setup stages
- ✅ **Authentication method recommendations** based on deployment type
- ✅ **Input validation** at each step
- ✅ **Configuration review** before final save

**Time Required**: 5-10 minutes per environment

## Accessing the Wizard

### In BC17
1. Open Business Central v17
2. Search for "**KLT Guided Setup Wizard**" or "**Kelteks API Setup Wizard**"
3. Click to launch the wizard

### In BC27
1. Open Business Central v27
2. Search for "**KLT Guided Setup Wizard**" or "**Kelteks API Setup Wizard**"
3. Click to launch the wizard

## Wizard Steps

### Step 1: Choose Deployment Type

The wizard auto-detects your environment and pre-selects:
- **On-Premise** - For local server installations
- **SaaS** - For cloud-hosted Business Central
- **Hybrid** - For mixed environments

**Authentication Method** is automatically recommended:
- On-Premise → Basic Authentication (simplest)
- SaaS → OAuth 2.0 (required)
- Hybrid → OAuth 2.0 (recommended)

**What to do:**
- Verify the auto-detected deployment type
- Optionally change authentication method if needed
- Click **Next**

### Step 2: Configure Target Connection

The wizard pre-fills the target URL based on your deployment type.

**For BC17 (connecting to BC27):**
- Default: `https://bc27-server:7048/BC270/ODataV4/`
- Optionally enter server name/IP to auto-generate URL
- Enter BC27 Company ID (find in Company Information)

**For BC27 (connecting to BC17):**
- Default: `https://bc17-server:7048/BC170/ODataV4/`
- Optionally enter server name/IP to auto-generate URL
- Enter BC17 Company ID (find in Company Information)

**What to do:**
- Update the URL if your server uses different name/port
- Enter the target Company ID (GUID)
- Click **Next**

### Step 3: Configure Authentication

Fields shown depend on selected authentication method.

**Basic Authentication (On-Premise):**
- Username: Service account (e.g., `DOMAIN\ServiceAccount`)
- Password: Service account password

**OAuth 2.0 (SaaS/Hybrid):**
- Azure AD Tenant ID
- Azure AD Client ID
- Client Secret

**Windows Authentication:**
- Username: Domain account
- Domain: Windows domain name

**Certificate Authentication:**
- Certificate Name
- Certificate Thumbprint

**What to do:**
- Fill in the required credentials
- Click **Next**

### Step 4: Review and Test

Review all configuration settings before saving.

**Configuration Summary:**
- Deployment Type
- Authentication Method
- Target Base URL
- Target Company ID

**What to do:**
- Review all settings
- Optionally click **Test Connection** to validate
- Click **Next** if everything looks correct

### Step 5: Completion

Setup is complete! The wizard saves your configuration to the API Configuration table.

**Options:**
- ✓ Enable Sync Immediately
- ✓ Configure Job Queue (15-minute interval)

**What to do:**
- Optionally check the boxes for automatic setup
- Click **Finish** to complete

## After Setup

Once the wizard completes:

1. **Verify Configuration** (optional)
   - Search for "**KLT API Configuration**"
   - Review saved settings
   - Test connection if not done in wizard

2. **Enable Synchronization**
   - Open KLT API Configuration
   - Check "Enable Sync"
   - Save

3. **Configure Job Queue**
   - Set up job queue entry for automatic sync
   - Recommended: 15-minute interval
   - Or use manual sync via actions

4. **Monitor Sync**
   - Search for "**KLT Document Sync Log**"
   - View sync history and status
   - Check for any errors

## Typical Setup Times

| Scenario | Time Required |
|----------|---------------|
| **On-Premise with Basic Auth** | 5 minutes |
| **SaaS with OAuth 2.0** | 10 minutes |
| **Both BC17 + BC27** | 10-15 minutes total |
| **Manual Configuration (no wizard)** | 20-30 minutes |

## Supported Scenarios

### ✅ Automated Setup
- On-Premise to On-Premise
- SaaS to SaaS
- On-Premise to SaaS (Hybrid)
- SaaS to On-Premise (Hybrid)

### ✅ Authentication Methods
- Basic Authentication (recommended for on-premise)
- OAuth 2.0 (required for SaaS)
- Windows Authentication
- Certificate Authentication (advanced)

### ✅ Environments
- BC v17 connecting to BC v27
- BC v27 connecting to BC v17
- Any supported Business Central version with API v2.0

## Troubleshooting

**Wizard doesn't appear in search:**
- Ensure the extension is installed and published
- Check user permissions
- Try refreshing the page

**Auto-detection shows wrong deployment type:**
- Manually select the correct deployment type
- The wizard will adjust recommendations accordingly

**URL format incorrect:**
- Use the examples provided in Step 2
- On-Premise: `https://server:port/instance/ODataV4/`
- SaaS: `https://api.businesscentral.dynamics.com/v2.0/{environment}/api/v2.0/`

**Can't find Company ID:**
- In Business Central, search for "Company Information"
- The Id field contains your Company ID (GUID format)
- This is NOT the SystemId field

**Connection test fails:**
- Verify URL is accessible from current environment
- Check credentials are correct
- Ensure target environment has API enabled
- Verify firewall/network allows connection

## Advanced Users

The wizard is designed for quick setup with defaults. Advanced users can:

- **Skip the wizard** and configure manually via KLT API Configuration
- **Use the wizard** for initial setup, then customize settings
- **Re-run the wizard** anytime to reconfigure (previous settings are overwritten)
- **Configure advanced options** in KLTAPI Configuration after wizard completes:
  - Batch Size
  - Sync Interval
  - Retry Attempts
  - Timeout Settings
  - Email Alerts

## Benefits Over Manual Configuration

| Feature | Wizard | Manual |
|---------|--------|--------|
| **Time Required** | 5-10 min | 20-30 min |
| **Environment Detection** | Automatic | Manual |
| **URL Generation** | Auto-filled | Manual entry |
| **Auth Method Selection** | Recommended | Must research |
| **Input Validation** | Real-time | After save |
| **Error Prevention** | Built-in | User responsibility |
| **Learning Curve** | Minimal | Steep |

## Next Steps

After completing the wizard setup:

1. **Review Advanced Configuration**
   - [Complete Configuration Guide](../KelteksAPIIntegrationBC17/SETUP-BASIC.md)
   - [OAuth Setup Guide](../KelteksAPIIntegrationBC17/SETUP-OAUTH.md)

2. **Understand the Integration**
   - [Architecture Overview](technical/ARCHITECTURE.md)
   - [Implementation Status](technical/IMPLEMENTATION-STATUS.md)

3. **Monitor and Maintain**
   - [Deployment Checklist](guides/FINAL-REVIEW-CHECKLIST.md)
   - [Project Analysis](analysis/PROJECT-ANALYSIS-2025-11-26.md)

## Support

For issues or questions:
- Review the relevant setup guide for your authentication method
- Check the [Documentation Index](../DOCUMENTATION-INDEX.md)
- Contact: Ana Šetka (Consultant)

---

**Version**: 1.0  
**Last Updated**: 2025-11-26  
**Applies To**: BC17 v1.0, BC27 v2.0
