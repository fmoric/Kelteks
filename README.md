# Kelteks API Integration - Fiskalizacija 2.0

**Business Central API Integration for Electronic Invoice Exchange (eRačun)**

[![BC Best Practices](https://img.shields.io/badge/BC%20Best%20Practices-10%2F10-brightgreen)]()
[![Code Quality](https://img.shields.io/badge/Code%20Quality-9.2%2F10-brightgreen)]()
[![Status](https://img.shields.io/badge/Status-Production%20Ready-success)]()

## Overview

This solution enables **bidirectional document synchronization** between Business Central v17 and v27 environments to support Fiskalizacija 2.0 compliance for electronic invoicing (eRačun) in Croatia.

### Architecture

The project consists of **two separate Business Central extensions**:
- **KelteksAPIIntegrationBC17** (v1.0) - Installed on BC v17 (Platform 17.0)
- **KelteksAPIIntegrationBC27** (v2.0) - Installed on BC v27 (Platform 27.0)

### Document Flow

```
BC17 (v17)                          BC27 (v27)
┌──────────────────┐               ┌──────────────────┐
│  Sales Invoices  │──────────────>│  Sales Invoices  │
│  Sales Cr. Memos │──────────────>│  Sales Cr. Memos │──> eRačun
│                  │               │                  │
│  Purch. Invoices │<──────────────│  Purch. Invoices │<── eRačun
│  Purch. Cr. Memos│<──────────────│  Purch. Cr. Memos│
└──────────────────┘               └──────────────────┘
```

## Quick Start

⚡ **Fastest Setup (15-20 minutes)**: [On-Premise Quick Start Guide](QUICKSTART-ONPREMISE.md)

For detailed documentation:
- 📖 [Complete Project Summary](SUMMARY.md)
- 🏗️ [Architecture Details](SPLIT-ARCHITECTURE.md)
- 📋 [Implementation Status](IMPLEMENTATION-STATUS.md)
- 🔧 [Setup Guides](KelteksAPIIntegrationBC17/README.md) (BC17) and [BC27](KelteksAPIIntegrationBC27/README.md)

## Key Features

✅ **4 Authentication Methods**
- OAuth 2.0 (Azure AD) - For cloud/SaaS
- Basic Authentication - Recommended for on-premise
- Windows Authentication - NTLM/Kerberos
- Certificate Authentication - High security mTLS

✅ **Automated Synchronization**
- Scheduled batch processing (every 15 minutes)
- Manual sync on demand
- Retry logic with exponential backoff
- Duplicate detection

✅ **Comprehensive Error Handling**
- 5 error categories with detailed logging
- Integration with BC Error Message table
- Email notifications for critical failures
- Performance monitoring

✅ **Production Ready**
- 100% feature complete
- 10/10 BC best practices compliance
- Full localization support (50+ labels)
- ~7,660 lines of production-ready AL code

## Technical Specifications

| Specification | Value |
|--------------|-------|
| **Sync Interval** | 15 minutes (configurable) |
| **Batch Size** | 100 documents per cycle |
| **Performance** | < 5 seconds per document |
| **API Version** | Business Central v2.0 API |
| **Security** | TLS 1.2+, masked credentials |
| **Expected Volume** | 50-200 sales invoices/day, 30-100 purchase invoices/day |

## Project Information

- **Client**: Kelteks
- **JIRA**: ZGBCSKELTE-54
- **Consultant**: Ana Šetka
- **Requestor**: Miroslav Gjurinski
- **Status**: ✅ Production Ready (Implementation Complete: 2025-11-26)

## Getting Started

### 1. Prerequisites
- Business Central v17 and v27 environments
- Master data synchronized between systems
- Network connectivity between environments
- Authentication credentials (per chosen method)

### 2. Installation

**For BC17:**
```powershell
Install-NAVApp -ServerInstance BC17 -Name "Kelteks API Integration" -Version 1.0.0.0
```

**For BC27:**
```powershell
Install-NAVApp -ServerInstance BC27 -Name "Kelteks API Integration" -Version 2.0.0.0
```

### 3. Configuration

1. Open **KLT API Configuration** page in both environments
2. Choose authentication method
3. Enter target system details (URL, credentials, company ID)
4. Test connection
5. Enable sync
6. Configure job queue (15-minute interval)

See [detailed setup guides](KelteksAPIIntegrationBC17/README.md) for step-by-step instructions.

## Documentation

### User Documentation
- [Quick Start Guide (On-Premise)](QUICKSTART-ONPREMISE.md) - 15-20 minute setup
- [BC17 Setup Guides](KelteksAPIIntegrationBC17/) - OAuth, Basic, Windows, Certificate auth
- [BC27 Setup Guides](KelteksAPIIntegrationBC27/) - OAuth, Basic, Windows, Certificate auth
- [Architecture Overview](SPLIT-ARCHITECTURE.md)
- [Upgrade Guide](UPGRADE-GUIDE.md) - BC17 to BC27 upgrade path

### Developer Documentation
- [Complete Project Summary](SUMMARY.md) - Full technical specification
- [Implementation Status](IMPLEMENTATION-STATUS.md) - Current state and features
- [Code Quality Report](BC-BEST-PRACTICES-COMPLIANCE.md) - Best practices compliance
- [Copilot Guide](COPILOT-GUIDE.md) - Developer reference

### Deployment
- [Deployment Checklist](FINAL-REVIEW-CHECKLIST.md) - Pre-deployment validation
- [Project Analysis](PROJECT-ANALYSIS-2025-11-26.md) - Comprehensive assessment

## Support

For issues or questions:
1. Review [setup guides](KelteksAPIIntegrationBC17/README.md) for configuration help
2. Check [Final Review Checklist](FINAL-REVIEW-CHECKLIST.md) for known issues
3. See [Code Analysis](CODE_ANALYSIS.md) for technical details
4. Contact: Ana Šetka (Consultant)

## License & Compliance

- **Fiskalizacija 2.0**: Full compliance for Croatian eRačun requirements
- **BC Best Practices**: 10/10 compliance score
- **Security**: TLS 1.2+, no hardcoded credentials, secure secret storage

---

**Version**: 1.0 (BC17) / 2.0 (BC27)  
**Last Updated**: 2025-11-26  
**Status**: ✅ Production Ready
