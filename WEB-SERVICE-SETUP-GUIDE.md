# Web Service Setup Guide
## Kelteks API Integration - Configurable Web Service Publication

**Date**: 2025-11-28  
**Feature**: Configurable API Web Service Publication

---

## Overview

The Kelteks API Integration now supports **configurable web service publication** through the setup page. This allows administrators to easily publish, verify, and manage the API endpoints that receive data from the other system.

---

## Key Features

### 1. Automated Web Service Publication ✅

**Location**: KLT API Configuration page → Actions → "Publish API Web Services"

**What it does**:
- Automatically publishes all KLT API pages as web services
- Registers them in the Tenant Web Services table
- Makes them accessible via standard BC web service endpoints

**For BC17**:
- Publishes: Purchase Invoice API, Purchase Cr. Memo API

**For BC27**:
- Publishes: Sales Invoice API, Sales Cr. Memo API

### 2. Web Service Verification ✅

**Location**: KLT API Configuration page → Actions → "Verify Web Services"

**What it does**:
- Checks if all required API web services are published
- Verifies they are marked as "Published" in Tenant Web Services
- Provides clear feedback on status

### 3. Manual Management ✅

Administrators can also:
- Navigate to **Web Services** page in BC
- View all published KLT services (prefix: "KLT_")
- Manually publish/unpublish individual services
- View OData URLs for each service

---

## How API Pages Work in Business Central

### Automatic vs Manual Publication

**API Pages (PageType = API)**:
- ✅ **Auto-published** at the `/api/` endpoint
- ✅ Available immediately when extension is installed
- ✅ Follow custom API URL pattern: `/api/{publisher}/{group}/{version}/...`
- ⚠️ Can ALSO be registered in Tenant Web Services for visibility

**Regular Pages (PageType = List, Card, etc.)**:
- ❌ NOT auto-published
- ❌ Require manual publication in Web Services page
- ✅ Exposed via `/OData/` endpoint only after publication

### Our Implementation

**Custom API URLs** (auto-available):
```
BC17 Purchase API:
https://bc-server/BC/api/kelteks/api/v2.0/companies(CompanyName)/purchaseInvoices

BC27 Sales API:
https://bc-server/BC/api/kelteks/api/v2.0/companies(CompanyName)/salesInvoices
```

**Optional Tenant Web Service Registration**:
- Provides visibility in Web Services page
- Shows service name, object type, published status
- Useful for documentation and discovery
- NOT required for API pages to function

---

## Setup Workflow

### Initial Setup (BC17)

1. Open **KLT API Configuration** page
2. Configure connection to BC27
3. Click **"Publish API Web Services"**
   - Publishes: KLT_PurchaseInvoices, KLT_PurchaseCreditMemos
4. Click **"Verify Web Services"**
   - Confirms: "All API web services are published and ready."
5. Click **"Test Connection"** to verify BC27 is reachable

### Initial Setup (BC27)

1. Open **KLT API Configuration** page
2. Configure connection to BC17
3. Click **"Publish API Web Services"**
   - Publishes: KLT_SalesInvoices, KLT_SalesCreditMemos
4. Click **"Verify Web Services"**
   - Confirms: "All API web services are published and ready."
5. Click **"Test Connection"** to verify BC17 is reachable

---

## Web Service Names

### BC17
| API Page | Object ID | Service Name | Entity |
|----------|-----------|--------------|--------|
| KLT Purchase Invoice API | 80124 | KLT_PurchaseInvoices | purchaseInvoices |
| KLT Purchase Cr. Memo API | 80126 | KLT_PurchaseCreditMemos | purchaseCreditMemos |

### BC27
| API Page | Object ID | Service Name | Entity |
|----------|-----------|--------------|--------|
| KLT Sales Invoice API | 80120 | KLT_SalesInvoices | salesInvoices |
| KLT Sales Cr. Memo API | 80122 | KLT_SalesCreditMemos | salesCreditMemos |

---

## Accessing Published Web Services

### Via Web Services Page

1. Search for "Web Services" in BC
2. Filter by "Object Type" = Page
3. Look for services starting with "KLT_"
4. View OData URL, Service Name, Published status

### Via API Endpoint

**Direct API access** (no web service publication needed):
```
GET /api/kelteks/api/v2.0/companies(CompanyName)/purchaseInvoices
POST /api/kelteks/api/v2.0/companies(CompanyName)/purchaseInvoices
```

**OData access** (requires web service publication):
```
GET /OData/Company('CompanyName')/KLT_PurchaseInvoices
```

**Note**: The sync uses the direct API endpoint, not OData.

---

## Troubleshooting

### "Web service already published"

**Cause**: The service is already registered  
**Solution**: No action needed - service is ready to use

### "Some API web services are not published"

**Cause**: Services not found in Tenant Web Services  
**Solution**: Click "Publish API Web Services" button

### API still not accessible

**Check**:
1. Extension is installed and published
2. User has permissions to API page objects
3. Base URL is correct in configuration
4. Authentication credentials are valid

---

## Security Considerations

### Permissions Required

**To publish web services**:
- SUPER user or
- Permission set with INSERT/MODIFY on "Tenant Web Service" table

**To access API endpoints**:
- Permission to read/write source tables (Sales Header, Purchase Header)
- Permission to execute API page objects

### Best Practices

1. ✅ Publish services with descriptive names (prefix: KLT_)
2. ✅ Verify services after publication
3. ✅ Use HTTPS for all API communications
4. ✅ Implement proper authentication (OAuth recommended)
5. ✅ Monitor API usage via BC telemetry

---

## API vs OData - Key Differences

| Feature | API Pages | OData (Web Services) |
|---------|-----------|---------------------|
| **Publication** | Auto-published | Manual via Web Services page |
| **URL Pattern** | `/api/{publisher}/{group}/{version}/` | `/OData/Company('...')/{ServiceName}` |
| **Use Case** | Modern integrations | Legacy integrations |
| **Performance** | Optimized for CRUD | General query support |
| **Our Usage** | Primary sync method | Optional/not used |

---

## Configuration Actions Summary

### KLT API Configuration Page Actions

1. **Test Connection**
   - Tests API connectivity to target system
   - Validates authentication
   
2. **Create Job Queue Entry**
   - Sets up automatic sync schedule
   - Uses configured interval (default: 15 min)

3. **Publish API Web Services** ⭐ NEW
   - Registers API pages in Tenant Web Services
   - Makes them visible in Web Services page
   
4. **Verify Web Services** ⭐ NEW
   - Checks publication status
   - Confirms all required services are ready

5. **Quick Setup Guide**
   - Launches guided setup wizard
   - Steps through configuration

---

## Technical Implementation

### Web Service Setup Codeunit

**BC17**: Codeunit 80106 "KLT Web Service Setup"  
**BC27**: Codeunit 80156 "KLT Web Service Setup"

**Key Methods**:
- `PublishAllAPIWebServices()` - Publishes all KLT APIs
- `VerifyWebServicesPublished()` - Checks publication status
- `UnpublishAllAPIWebServices()` - Removes web service entries
- `IsWebServicePublished(ObjectID)` - Checks specific service

### Example Code

```al
// Publish services
var
    WebServiceSetup: Codeunit "KLT Web Service Setup";
begin
    WebServiceSetup.PublishAllAPIWebServices();
end;

// Verify status
if WebServiceSetup.VerifyWebServicesPublished() then
    Message('All services published')
else
    Error('Missing services');
```

---

## Conclusion

The configurable web service publication feature provides:

✅ **Easy Setup** - One-click publication from config page  
✅ **Verification** - Built-in status checking  
✅ **Visibility** - Services appear in Web Services page  
✅ **Flexibility** - Publish/unpublish as needed  
✅ **Documentation** - Clear service names and endpoints  

This enhancement makes API deployment and management significantly easier for administrators.

---

**End of Guide**
