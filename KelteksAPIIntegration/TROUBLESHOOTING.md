# Troubleshooting Guide - Kelteks API Integration

## Quick Diagnostics

### Check Integration Status

1. Open **API Configuration** page
2. Click **Test Connection**
3. Review result message

### Check Recent Sync Activity

1. Open **Document Sync Log** page
2. Filter by recent dates
3. Review Status column
4. Check for Failed entries

### Check Active Errors

1. Open **Document Sync Error** page
2. Filter: Resolved = No
3. Review error categories
4. Note error patterns

## Common Issues

### 1. Connection Test Fails

**Symptom:** Test Connection returns error message

**Possible Causes:**
- Incorrect Base URL
- Wrong Company ID
- Invalid OAuth credentials
- Network connectivity issues
- Azure AD configuration problems

**Solutions:**

**A. Verify Base URL**
```
Correct format:
https://api.businesscentral.dynamics.com/v2.0/[environment-name]

Example:
https://api.businesscentral.dynamics.com/v2.0/production
```

**B. Verify Company ID**
1. In source BC, go to Companies page
2. Show column: ID
3. Copy the exact GUID
4. Paste into configuration (no braces)

**C. Verify OAuth Credentials**
1. Check Azure AD app registration
2. Verify Client ID is correct
3. Generate new Client Secret if needed
4. Ensure API permissions are granted
5. Required permission: Dynamics 365 Business Central (.default)

**D. Test Network Connectivity**
1. From server, try accessing the Base URL in browser
2. Should return 401 Unauthorized (expected without auth)
3. If timeout/error, check firewall rules
4. Ensure HTTPS (443) is allowed

### 2. Documents Not Syncing

**Symptom:** No new entries in Document Sync Log

**Possible Causes:**
- Synchronization is disabled
- Job Queue Entry is not running
- No new documents in source system
- Posting periods are closed

**Solutions:**

**A. Check Sync is Enabled**
1. Open API Configuration
2. Verify "Enable Sync" is checked
3. If not, check and save

**B. Verify Job Queue Entry**
1. Go to Job Queue Entries page
2. Search for "Kelteks API"
3. Check Status = Ready
4. Verify Last Ready State = recent timestamp
5. If missing, click "Create Job Queue Entry" in API Configuration

**C. Check for New Documents**
1. In BC17, verify posted sales invoices exist
2. Check Last Modified DateTime
3. Compare with last sync log entry timestamp

**D. Verify Posting Periods**
1. Check User Setup → Allow Posting From/To
2. Check General Ledger Setup → Allow Posting From/To
3. Ensure dates cover document dates

### 3. Authentication Errors

**Symptom:** Error Category = Authentication in sync errors

**Error Messages:**
- "Unauthorized"
- "Invalid token"
- "Authentication failed"
- "401 Unauthorized"

**Solutions:**

**A. Regenerate OAuth Credentials**
1. Go to Azure AD → App Registrations
2. Select your app
3. Go to Certificates & Secrets
4. Create new client secret
5. Copy and update in API Configuration
6. Test connection

**B. Verify Token Endpoint**
1. Tenant ID should be your Azure AD tenant GUID
2. Format: https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token
3. Verify Tenant ID is correct

**C. Check API Permissions**
1. Azure AD → App Registrations → Your App
2. API Permissions
3. Should have: Dynamics 365 Business Central / .default
4. Grant admin consent if required

**D. Clear Token Cache**
```AL
// In AL code (for testing)
APIAuth: Codeunit "KLT API Authentication";
APIAuth.ClearTokenCache();
```

### 4. Master Data Missing Errors

**Symptom:** Error Category = Master Data Missing

**Error Messages:**
- "Customer {no} does not exist"
- "Vendor {no} does not exist"
- "Item {no} does not exist"

**Solutions:**

**A. Verify Master Data Exists**
1. Note the missing record number from error
2. In target system, search for that record
3. If missing, create it

**B. Master Data Sync Checklist**
Ensure these exist in BOTH BC17 and BC27:
- [ ] All Customers (for sales docs)
- [ ] All Vendors (for purchase docs)
- [ ] All Items referenced in documents
- [ ] All G/L Accounts
- [ ] All Resources
- [ ] Payment Terms
- [ ] Currency Codes
- [ ] Posting Groups

**C. Compare Master Data**
```
1. Export Customers from BC17
2. Export Customers from BC27
3. Compare lists
4. Create missing records in target
```

**D. Check for Blocked Records**
1. Master record might exist but be blocked
2. In target system, find the record
3. Check Blocked field
4. Unblock if appropriate

### 5. Data Validation Errors

**Symptom:** Error Category = Data Validation

**Error Messages:**
- "Required field missing"
- "Invalid value"
- "Posting Date not in allowed period"

**Solutions:**

**A. Review Required Fields**
Required for all documents:
- Customer/Vendor No.
- Posting Date
- Document Date

**B. Check Posting Date**
1. Document posting date must be within allowed period
2. Check User Setup or General Ledger Setup
3. Adjust "Allow Posting To" date if needed

**C. Validate Currency**
1. If document has currency code
2. Ensure currency exists in target
3. Or leave blank to use LCY

**D. Check Payment Terms**
1. Verify payment terms code exists in target
2. Or it will use customer/vendor default

### 6. High Error Rate

**Symptom:** Alert about error rate > 25%

**Possible Causes:**
- System issue affecting all docs
- Master data sync problem
- API endpoint unavailable
- Network issues

**Solutions:**

**A. Check Error Statistics**
1. Open Document Sync Error page
2. Click Statistics action
3. Review error distribution by category

**B. If API Communication errors dominate:**
1. Check API endpoint availability
2. Check network connectivity
3. Review Azure AD service status
4. Check API quota/throttling

**C. If Master Data errors dominate:**
1. Run master data comparison
2. Create missing records
3. Consider bulk master data sync

**D. If Authentication errors:**
1. Regenerate credentials
2. Clear token cache
3. Test connection

### 7. Performance Issues

**Symptom:** Sync takes longer than 15 minutes

**Possible Causes:**
- Too many documents in batch
- Network latency
- API throttling
- Target system slow

**Solutions:**

**A. Reduce Batch Size**
1. Open API Configuration
2. Reduce "Batch Size" from 100 to 50
3. Save and test

**B. Increase Sync Interval**
1. Change from 15 to 30 minutes
2. Reduces API call frequency
3. Helps with throttling

**C. Check Network Latency**
1. Measure response times
2. Review Duration (ms) in sync log
3. If consistently > 5 seconds, investigate network
4. Consider API endpoint region

**D. Monitor API Quotas**
1. Check Azure AD app usage
2. Review Business Central API limits
3. Implement throttling if needed

### 8. Duplicate Documents

**Symptom:** Same document appears multiple times

**Possible Causes:**
- External Document No. is blank
- Duplicate check not working
- Manual re-sync

**Solutions:**

**A. Ensure External Doc No. is Set**
- Sales: externalDocumentNumber
- Purchase: vendorInvoiceNumber
- This field is used for duplicate detection

**B. Check Sync Log**
1. Open Document Sync Log
2. Filter by External Document No.
3. Review duplicate entries
4. If found, mark as resolved

**C. Manual Cleanup**
1. In target system, find duplicate documents
2. Delete unposted duplicates
3. Keep the correct one
4. Mark sync errors as resolved

### 9. Job Queue Not Running

**Symptom:** Last Ready State shows old timestamp

**Possible Causes:**
- Job Queue stopped
- Error in job execution
- User session required

**Solutions:**

**A. Check Job Queue Status**
1. Job Queue Entries page
2. Find Kelteks API entry
3. Check Status column
4. Should be "Ready" not "On Hold"

**B. Restart Job Queue**
1. If On Hold, click "Set Status to Ready"
2. Or delete and recreate using "Create Job Queue Entry"

**C. Check Error Log**
1. Select job queue entry
2. Click "Log Entries"
3. Review any errors
4. Address underlying issues

**D. Verify Job Queue is Running**
1. Administration → Job Queue
2. Ensure job queue management is started
3. Check server task scheduler

## Diagnostic Queries

### Check Recent Sync Activity
```
Document Sync Log filtered:
- Created DateTime: Last 24 hours
- Group by Status
```

### Error Distribution
```
Document Sync Error filtered:
- Resolved: No
- Group by Error Category
```

### Performance Metrics
```
Document Sync Log filtered:
- Status: Completed
- Calculate average Duration (ms)
- Identify slowest operations
```

### Success Rate
```
Total: All sync log entries
Success: Status = Completed
Failed: Status = Failed
Rate: (Success / Total) * 100
```

## Preventive Maintenance

### Daily
- [ ] Check sync log for failures
- [ ] Review error count
- [ ] Verify job queue is running

### Weekly
- [ ] Review error trends
- [ ] Test connection
- [ ] Check success rate (target > 95%)
- [ ] Review performance metrics

### Monthly
- [ ] Update credentials (if policy requires)
- [ ] Archive old logs
- [ ] Review capacity
- [ ] Test disaster recovery

## Getting Help

### Internal Support
1. Review this troubleshooting guide
2. Check error messages in sync error log
3. Review technical documentation
4. Contact your BC administrator

### External Support
1. Gather diagnostic information:
   - Error messages
   - Sync log entries
   - Configuration screenshots
   - Recent changes
2. Contact your Business Central partner
3. Provide all diagnostic information

### Diagnostic Information to Collect

When reporting an issue, include:

**Configuration:**
- Screenshot of API Configuration page (mask secrets)
- Sync interval and batch size
- BC version numbers (BC17 and BC27)

**Error Details:**
- Specific error message
- Error category
- Document type and number
- Timestamp when error occurred

**Sync Log:**
- Recent sync log entries
- Filter: last 24 hours
- Include successful and failed

**System Info:**
- Network topology
- Firewall rules
- Azure AD tenant info
- API endpoint regions

**Recent Changes:**
- Configuration changes
- Credential updates
- Master data changes
- System updates

## Advanced Troubleshooting

### Enable Detailed Logging

For debugging, you can add additional logging:

1. Modify `KLT API Helper` codeunit
2. Add logging to file or database
3. Capture full request/response
4. Remember to disable in production

### Test API Manually

Use Postman or similar tool:

**Get Token:**
```
POST https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id={clientId}
&client_secret={clientSecret}
&scope=https://api.businesscentral.dynamics.com/.default
```

**Call API:**
```
GET {baseUrl}/api/v2.0/companies({companyId})/salesInvoices
Authorization: Bearer {token}
```

### Check Azure AD Logs

1. Azure Portal → Azure AD
2. Enterprise Applications → Your App
3. Sign-ins → Review authentication logs
4. Check for failures

### Network Trace

If connection issues persist:

1. Capture network trace during sync
2. Look for TLS handshake failures
3. Check for proxy interference
4. Verify DNS resolution

## Emergency Procedures

### Stop All Sync
1. Open API Configuration
2. Uncheck "Enable Sync"
3. Save
4. Or set Job Queue Entry to "On Hold"

### Rollback Configuration
1. Keep backup of working configuration
2. Restore previous values
3. Test connection
4. Re-enable sync

### Clear Error Queue
If error queue is stuck:
1. Document Sync Error page
2. Mark problematic errors as Resolved
3. Or delete if appropriate
4. Prevents retry loops

## Contact Information

For support:
- Business Central Partner: [Your Partner]
- System Administrator: [Your Admin]
- Documentation: README.md and TECHNICAL.md

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-15
