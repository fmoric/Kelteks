# BC27 Extension - Windows Authentication Setup Guide

## Overview

Setup guide for Kelteks API Integration BC27 extension using **Windows Authentication** (domain integrated) to connect to BC v17.

**Best for**: Same Windows domain environments with single sign-on.

---

## Prerequisites

- BC v27 and BC v17 in the same Windows domain
- Service Principal Names (SPNs) configuration rights
- Active Directory access

---

## Step 1: Configure BC17 for Windows Authentication

```powershell
# On BC17 server
Set-NAVServerConfiguration -ServerInstance BC170 `
    -KeyName "ClientServicesCredentialType" `
    -KeyValue "Windows"

Restart-NAVServerInstance -ServerInstance BC170
```

### Configure BC17 Service Account
1. Open **Services** on BC17 server
2. Find **Microsoft Dynamics 365 Business Central Server [BC170]**
3. Properties > Log On tab
4. Set to domain account: `DOMAIN\BC17Service`
5. Restart service

---

## Step 2: Configure Service Principal Names (SPNs)

```powershell
# Register SPNs for BC17
setspn -S HTTP/bc17-server.company.local DOMAIN\BC17Service
setspn -S HTTP/bc17-server DOMAIN\BC17Service
setspn -S DynamicsNAV/bc17-server.company.local DOMAIN\BC17Service
setspn -S DynamicsNAV/bc17-server DOMAIN\BC17Service

# Verify
setspn -L DOMAIN\BC17Service
```

---

## Step 3: Configure Kerberos Delegation

### On BC27 Service Account
1. Open **Active Directory Users and Computers**
2. Find BC27 service account
3. Properties > Delegation tab
4. Select: "Trust this user for delegation to specified services only"
5. Select: "Use any authentication protocol"
6. Add SPNs:
   - `HTTP/bc17-server.company.local`
   - `DynamicsNAV/bc17-server.company.local`

---

## Step 4: Create Service Account

### Create Domain User
1. Open AD Users and Computers
2. New User: `kelteks-sync-svc`
3. Set password, "Password never expires"

### Grant Rights
1. Add to required groups
2. Grant "Log on as a service" on BC27 server

---

## Step 5: Create BC User in BC17

1. Open BC17 Web Client
2. Navigate to **Users** > **New**
3. User Name: `DOMAIN\kelteks-sync-svc`
4. Windows Security ID: Select domain account
5. Assign permissions:
   - Read/Write Purchase Invoice tables

---

## Step 6: Install BC27 Extension

```powershell
Publish-NAVApp -ServerInstance BC270 `
    -Path ".\KelteksAPIIntegrationBC27.app" `
    -SkipVerification

Sync-NAVApp -ServerInstance BC270 `
    -Name "Kelteks API Integration BC27"

Install-NAVApp -ServerInstance BC270 `
    -Name "Kelteks API Integration BC27"
```

---

## Step 7: Configure BC27 Extension

Search: `KLT API Configuration`

| Field | Value |
|-------|-------|
| **Base URL** | `http://bc17-server.company.local:7048/BC170/ODataV4/` |
| **Company ID** | BC17 GUID |
| **Authentication Method** | `Windows` |
| **Use Default Credentials** | ☑ Yes |
| **Enabled** | ☑ Yes |

---

## Step 8: Test Connection

Click **Actions** > **Test Connection**

✅ **Success**:
```
Connection successful!
Authentication: Windows (Kerberos)
User: DOMAIN\kelteks-sync-svc
```

---

## Step 9: Configure Job Queue

Set BC27 service to run as service account:

```powershell
# On BC27 server
# Services > BC270 > Properties > Log On
# Set to: DOMAIN\kelteks-sync-svc
```

Create Job Queue Entry:
- Object ID: `50155`
- Minutes between Runs: `15`

---

## Troubleshooting

### "401 Unauthorized"
1. Verify SPNs: `setspn -L DOMAIN\BC17Service`
2. Check Event Viewer for Kerberos errors
3. Verify delegation configured

### "Target principal name incorrect"
1. Re-register SPNs
2. Use FQDN in Base URL
3. Clear Kerberos cache: `klist purge`

---

## Security Best Practices

1. Use HTTPS even with Windows Auth
2. Use constrained delegation (not unconstrained)
3. Monitor Kerberos authentication logs
4. Dedicated service account

---

## Support

**Consultant**: Ana Šetka
**Client**: Kelteks
**JIRA**: ZGBCSKELTE-54

---

**Last Updated**: 2025-01-26
**Version**: 1.0.0
**Extension**: Kelteks API Integration BC27
