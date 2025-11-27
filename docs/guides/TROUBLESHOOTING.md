# Kelteks API Integration - Troubleshooting Guide

## Quick Diagnostics

### Symptom: "Connection failed" error

**Possible Causes:**
1. Network connectivity issue
2. Incorrect URL or Company ID
3. Authentication failure
4. Firewall blocking connection
5. Web services disabled

**Diagnostic Steps:**
1. Open **KLT API Configuration**
2. Click **Test Connection**
3. Review error message details
4. Check Event Viewer for additional details

**Solutions:**
- Verify Target Base URL format
- Ping target server to test connectivity
- Check firewall rules allow HTTPS traffic
- Verify web services enabled on target
- Review authentication credentials

### Symptom: Documents not syncing automatically

**Possible Causes:**
1. Job Queue not running
2. Sync disabled in configuration
3. Job Queue entry not configured correctly
4. Batch size too small

**Diagnostic Steps:**
1. Open **Job Queue Entries**
2. Find "Kelteks API Sync" entry
3. Check Status field
4. Review **Job Queue Log Entries**

**Solutions:**
- Set Job Queue status to **Ready**
- Verify **Enable Sync** = Yes in KLT API Configuration
- Check Object ID matches codeunit (80106 for BC17, 80154 for BC27)
- Increase batch size if queue growing

### Symptom: Sync succeeds but document not created in target

**Possible Causes:**
1. Master data missing in target
2. Posting period closed in target
3. Validation error
4. Number series not configured

**Diagnostic Steps:**
1. Open **KLT Document Sync Log**
2. Filter by document number
3. Review error message
4. Check **Error Message** table

**Solutions:**
- Synchronize master data (customers/vendors)
- Open posting periods in target
- Configure number series for purchase documents
- Review validation error and fix source data

## Error Message Reference

### Authentication Errors

#### Error: "Failed to connect to authentication service"
**Meaning**: Cannot reach OAuth token endpoint  
**Cause**: Network issue or invalid Tenant ID  
**Solution**: 
- Verify Tenant ID format (GUID)
- Check internet connectivity
- Verify https://login.microsoftonline.com is accessible

#### Error: "Authentication failed with status code: 401"
**Meaning**: Invalid credentials  
**Cause**: Wrong Client ID, Client Secret, or username/password  
**Solution**:
- For OAuth: Verify Client ID and Client Secret in Azure AD
- For Basic: Verify username and password
- Check if password expired
- Verify user has web services access

#### Error: "Failed to extract access token from response"
**Meaning**: OAuth response doesn't contain token  
**Cause**: Permissions not granted or wrong scope  
**Solution**:
- Grant API.ReadWrite.All permission in Azure AD
- Admin consent required for application permissions
- Verify scope includes Business Central API

#### Error: "Windows authentication is not supported in BC17"
**Meaning**: Attempting to use Windows auth which isn't available  
**Cause**: BC17 runtime limitations  
**Solution**: Use OAuth 2.0 or Basic Authentication instead

#### Error: "Certificate authentication requires manual certificate configuration"
**Meaning**: Certificate auth not fully implemented in BC17  
**Cause**: BC17 runtime limitations for certificate handling  
**Solution**: 
- Contact administrator for manual certificate setup
- Or use OAuth 2.0 or Basic Authentication

### API Communication Errors

#### Error: "HTTP GET request failed: Connection error"
**Meaning**: Cannot connect to target API  
**Cause**: Network issue, firewall, or wrong URL  
**Solution**:
- Verify Target Base URL is correct
- Check network connectivity with ping
- Verify firewall allows outbound HTTPS (port 443)
- For on-premise: Verify port 7048 accessible

#### Error: "HTTP GET failed with status 404"
**Meaning**: API endpoint not found  
**Cause**: Wrong URL or company ID  
**Solution**:
- Verify Target Company ID is correct GUID
- Check URL format matches deployment type:
  - SaaS: `https://api.businesscentral.dynamics.com/v2.0/{environment}/api/v2.0/`
  - On-Prem: `https://server:7048/BC270/ODataV4/`

#### Error: "HTTP POST failed with status 400"
**Meaning**: Bad request - invalid JSON or data  
**Cause**: Missing required fields or invalid data format  
**Solution**:
- Review source document data
- Check all required fields populated
- Verify dates in valid format
- Check decimal/numeric field formats

#### Error: "HTTP POST failed with status 403"
**Meaning**: Forbidden - insufficient permissions  
**Cause**: Service account lacks API permissions  
**Solution**:
- Grant API.ReadWrite.All permission
- Verify user has Create/Modify permissions on Purchase documents
- Check permission set includes KELTEKS-API

#### Error: "HTTP POST failed with status 500"
**Meaning**: Internal server error on target  
**Cause**: Issue on target BC environment  
**Solution**:
- Check target BC Event Log
- Verify target BC service running
- Review target BC error details
- May be temporary - retry after few minutes

#### Error: "Failed to parse JSON response"
**Meaning**: Response from API not valid JSON  
**Cause**: Non-JSON response or corrupt data  
**Solution**:
- Review raw response in debugger
- Check API endpoint returning JSON
- May indicate target BC configuration issue

### Data Validation Errors

#### Error: "Customer {code} does not exist"
**Meaning**: Customer not found in source environment  
**Cause**: Customer deleted or wrong code  
**Solution**:
- Verify customer exists in BC17
- Check customer code matches exactly
- Recreate customer if deleted

#### Error: "Vendor {code} not found"
**Meaning**: Vendor doesn't exist in target as vendor  
**Cause**: Master data not synchronized  
**Solution**:
- Create vendor in BC27 with same code as BC17 customer
- Synchronize master data between environments
- Verify vendor not blocked

#### Error: "Vendor {code} has no posting group assigned"
**Meaning**: Vendor missing required posting group  
**Cause**: Incomplete vendor setup  
**Solution**:
- Open Vendor card in target
- Assign Vendor Posting Group
- Verify posting group accounts configured

#### Error: "Posting Date is required"
**Meaning**: Missing posting date in source  
**Cause**: Document has blank posting date  
**Solution**:
- Should not occur for posted documents
- If occurs, check document integrity
- May indicate data corruption

#### Error: "Posting Date {date} is before allowed posting from date {date}"
**Meaning**: Posting period closed in target  
**Cause**: GL Setup restricts posting to future dates  
**Solution**:
- Open posting period in target GL Setup
- Or adjust document posting date
- Or configure sync to skip closed periods

#### Error: "Currency {code} does not exist"
**Meaning**: Currency not found in target  
**Cause**: Currency not set up in target  
**Solution**:
- Create currency in target
- Or sync in LCY only
- Synchronize currency codes between environments

#### Error: "Duplicate: Posted invoice with External Document No. {no} already exists"
**Meaning**: Document already synced previously  
**Cause**: Attempting to sync same document twice  
**Solution**:
- This is expected behavior (prevents duplicates)
- If legitimate re-sync needed, change External Document No.
- Or delete previously synced document in target

#### Error: "Duplicate: Unposted invoice with External Document No. {no} already exists"
**Meaning**: Unposted document with same number exists  
**Cause**: Previous sync created unposted document  
**Solution**:
- Review unposted document in target
- Either post it or delete it
- Then retry sync

#### Error: "Item {code} does not exist"
**Meaning**: Item not found in target  
**Cause**: Item master not synchronized  
**Solution**:
- Create item in target with same code
- Or change line type to G/L Account
- Synchronize item master data

#### Error: "Item {code} is blocked"
**Meaning**: Item exists but is blocked  
**Cause**: Item blocked for purchasing/sales  
**Solution**:
- Unblock item in target
- Or use different item
- Check Blocked field and Sales Blocked/Purch Blocked

#### Error: "G/L Account {code} is not a posting account"
**Meaning**: Account type is not Posting  
**Cause**: Using heading or total account  
**Solution**:
- Use posting-type G/L account instead
- Check Account Type field
- Review chart of accounts structure

### Business Logic Errors

#### Error: "Line Type is required"
**Meaning**: Missing line type in JSON  
**Cause**: Source line has no type specified  
**Solution**:
- Should not occur in normal operation
- Check source document lines
- May indicate data integrity issue

#### Error: "Quantity must be greater than zero"
**Meaning**: Line quantity is zero or negative  
**Cause**: Invalid line data  
**Solution**:
- Check source document line quantity
- For credit memos, quantity should be positive
- Review line validation logic

#### Error: "Unit Price cannot be negative"
**Meaning**: Negative unit price  
**Cause**: Invalid pricing data  
**Solution**:
- For credit memos, use positive price
- Check source document pricing
- Review price calculation logic

#### Error: "Sales invoice lines is not an array"
**Meaning**: JSON structure incorrect  
**Cause**: Programming error or corrupt data  
**Solution**:
- Should not occur in production
- Review JSON structure in sync log
- Contact support if recurring

### Retry Logic

#### Status: "Retrying" with Next Retry Time
**Meaning**: Sync failed but will be retried automatically  
**Explanation**: 
- First retry after 1 minute (2^0)
- Second retry after 2 minutes (2^1)
- Third retry after 4 minutes (2^2)
- Maximum 3 retry attempts

**Action Required**: 
- None - system will retry automatically
- If still failing after 3 retries, review error message
- Fix underlying issue and use **Reset Failed Queue Items** action

## Performance Issues

### Symptom: Sync takes too long (> 5 seconds per document)

**Possible Causes:**
1. Network latency high
2. Large document with many lines
3. Target system overloaded
4. Inefficient validation

**Diagnostic Steps:**
1. Check **KLT Document Sync Log** Duration field
2. Review number of lines in slow documents
3. Test network latency (ping target)
4. Check target BC resource usage

**Solutions:**
- Reduce batch size to avoid overwhelming target
- Schedule sync during off-peak hours
- Optimize network route between BC17 and BC27
- Review target BC performance

### Symptom: Job Queue keeps failing

**Possible Causes:**
1. Unhandled exception in code
2. Insufficient permissions
3. Database locked
4. Too many failures

**Diagnostic Steps:**
1. Review **Job Queue Log Entries**
2. Check Error Message field
3. Review Event Viewer
4. Check BC error log

**Solutions:**
- Fix specific error from log
- Grant necessary permissions
- Reduce batch size
- Check for database deadlocks

## Monitoring Best Practices

### Daily Checks
- [ ] Review failed sync count (should be < 5% of total)
- [ ] Check job queue execution (should run every 15 min)
- [ ] Review error messages for patterns
- [ ] Verify sync statistics in FactBox

### Weekly Checks
- [ ] Review average sync duration trend
- [ ] Check retry queue size (should be minimal)
- [ ] Review and resolve recurring errors
- [ ] Verify no critical errors in Event Log

### Monthly Checks
- [ ] Archive old sync logs (> 12 months)
- [ ] Review overall sync success rate
- [ ] Analyze performance trends
- [ ] Review and update documentation

## Advanced Diagnostics

### Enable Detailed Logging

To get more detailed error information:

1. Open Event Viewer
2. Navigate to Applications and Services Logs > Microsoft > DynamicsNAV > Server
3. Enable Verbose logging level
4. Reproduce issue
5. Review detailed error trace

### Test Connection Manually

To test API connectivity outside of sync:

1. Open **KLT API Helper** codeunit
2. Use **TestConnection** procedure
3. Review response in debugger
4. Check HTTP status code and response body

### Clear Token Cache

If OAuth tokens seem stale:

1. Open **KLT API Configuration**
2. Click **Clear Token Cache** action
3. Next sync will acquire fresh token
4. Verify new token acquired successfully

### Reset Failed Queue Items

To retry all failed items:

1. Open **KLT API Sync Queue**
2. Filter by Status = Failed
3. Click **Reset Failed Queue Items** action
4. All failed items reset to Pending
5. Wait for next scheduled sync

### Cleanup Old Logs

To free up space and improve performance:

1. Open **KLT Document Sync Log**
2. Click **Cleanup Old Logs** action
3. Specify days to keep (recommended: 365)
4. Confirm cleanup
5. Verify old logs deleted

## Common Scenarios

### Scenario: Migrating from Test to Production

**Steps:**
1. Export configuration from test environment
2. Adjust URLs for production
3. Update authentication credentials for production
4. Test connection before enabling sync
5. Start with small test batch
6. Monitor closely for first few hours

### Scenario: Certificate About to Expire

**Steps:**
1. Generate new certificate before expiry
2. Install new certificate on BC17 server
3. Update Certificate Thumbprint in configuration
4. Test connection with new certificate
5. Remove old certificate after verification

### Scenario: Changing Authentication Method

**Steps:**
1. Disable sync temporarily
2. Update Authentication Method in configuration
3. Enter new credentials
4. Test connection
5. Re-enable sync
6. Monitor sync log for issues

### Scenario: Temporary Network Outage

**Expected Behavior:**
- Syncs fail during outage
- Items moved to retry queue
- Automatic retry when network restored
- All documents eventually sync

**Manual Intervention:**
- None required if outage < 1 hour
- If > 1 hour, consider manually resetting failed items after network restored

## Getting Help

### Self-Service Resources
1. Review this troubleshooting guide
2. Check TESTING-GUIDE.md for test procedures
3. Review setup guides (SETUP-OAUTH.md, SETUP-BASIC.md)
4. Check README.md for architecture overview

### Internal Support
1. **Level 1**: Key users - Review sync logs, retry failed items
2. **Level 2**: IT team - Check authentication, network, permissions
3. **Level 3**: Development team - Code review, advanced diagnostics

### External Support
- **Consultant**: Ana Šetka
- **JIRA Project**: ZGBCSKELTE-54
- **Documentation**: See DOCUMENTATION-INDEX.md

### When Contacting Support

Include the following information:
1. **Environment**: BC17 or BC27, version numbers
2. **Error Message**: Exact text from sync log
3. **Steps to Reproduce**: What action triggered the error
4. **Frequency**: How often does this occur
5. **Impact**: How many documents affected
6. **Screenshots**: Sync log, configuration, error messages
7. **Logs**: Job Queue log, Event Viewer entries
8. **Recent Changes**: Any recent configuration changes

## Known Limitations

These are by design and not errors:

1. **Windows Authentication**: Not supported in BC17 - use OAuth or Basic
2. **Certificate Authentication**: Requires manual setup in BC17
3. **Item Tracking**: Lot/Serial numbers not synced (per spec)
4. **Automatic Posting**: Documents created unposted for manual review
5. **Attachments**: Document attachments not synchronized
6. **Historical Data**: Only syncs documents created after setup
7. **Prepayments**: Prepayment information not synchronized

## Emergency Procedures

### Emergency Stop (Critical Issue Found)

1. **Disable Sync Immediately**:
   - BC17: Open KLT API Configuration, set Enable Sync = No
   - BC27: Open KLT API Configuration, set Enable Sync = No

2. **Stop Job Queue**:
   - Open Job Queue Entries
   - Set status to **On Hold** for both BC17 and BC27 entries

3. **Notify Stakeholders**:
   - Finance team
   - IT team
   - Management
   - Consultant

4. **Document Issue**:
   - Capture error messages
   - Take screenshots
   - Export sync logs
   - Note time of incident

5. **Assess Impact**:
   - Count affected documents
   - Identify any posted documents
   - Determine data integrity status

6. **Execute Rollback** (if needed):
   - See DEPLOYMENT-CHECKLIST.md Rollback Plan
   - Uninstall extensions if severe
   - Restore backup if data corrupted

---

**Version**: 1.0  
**Last Updated**: 2025-11-27  
**Status**: Production Ready
