/// <summary>
/// Web Service Setup - Manages publication of API pages as web services (BC27)
/// Provides automated setup and verification of web service endpoints
/// </summary>
codeunit 80156 "KLT Web Service Setup"
{
    var
        WebServiceAlreadyExistsMsg: Label 'Web service %1 already published.';
        WebServicePublishedMsg: Label 'Web service %1 published successfully.';
        WebServiceNotFoundMsg: Label 'Web service %1 not found in tenant web services.';
        AllWebServicesPublishedMsg: Label 'All API web services are published and ready.';

    /// <summary>
    /// Publishes all KLT API pages as web services
    /// </summary>
    procedure PublishAllAPIWebServices()
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        // BC27 Sales API pages
        PublishAPIWebService(Page::"KLT Sales Invoice API", 'KLT_SalesInvoices');
        PublishAPIWebService(Page::"KLT Sales Cr. Memo API", 'KLT_SalesCreditMemos');

        Message(AllWebServicesPublishedMsg);
    end;

    /// <summary>
    /// Publishes a single API page as web service
    /// </summary>
    local procedure PublishAPIWebService(ObjectID: Integer; ServiceName: Text[240])
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        // Check if already exists
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", ObjectID);
        if TenantWebService.FindFirst() then begin
            Message(WebServiceAlreadyExistsMsg, ServiceName);
            exit;
        end;

        // Create new web service entry
        TenantWebService.Init();
        TenantWebService."Object Type" := TenantWebService."Object Type"::Page;
        TenantWebService."Object ID" := ObjectID;
        TenantWebService."Service Name" := ServiceName;
        TenantWebService.Published := true;
        TenantWebService.Insert(true);

        Message(WebServicePublishedMsg, ServiceName);
    end;

    /// <summary>
    /// Unpublishes all KLT API web services
    /// </summary>
    procedure UnpublishAllAPIWebServices()
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        // BC27 Sales API pages
        UnpublishAPIWebService(Page::"KLT Sales Invoice API");
        UnpublishAPIWebService(Page::"KLT Sales Cr. Memo API");
    end;

    /// <summary>
    /// Unpublishes a single web service
    /// </summary>
    local procedure UnpublishAPIWebService(ObjectID: Integer)
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", ObjectID);
        if TenantWebService.FindFirst() then
            TenantWebService.Delete(true);
    end;

    /// <summary>
    /// Verifies all API web services are published
    /// </summary>
    procedure VerifyWebServicesPublished(): Boolean
    var
        TenantWebService: Record "Tenant Web Service";
        AllPublished: Boolean;
    begin
        AllPublished := true;

        // Check BC27 Sales APIs
        AllPublished := AllPublished and IsWebServicePublished(Page::"KLT Sales Invoice API");
        AllPublished := AllPublished and IsWebServicePublished(Page::"KLT Sales Cr. Memo API");

        exit(AllPublished);
    end;

    /// <summary>
    /// Checks if a specific web service is published
    /// </summary>
    local procedure IsWebServicePublished(ObjectID: Integer): Boolean
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", ObjectID);
        TenantWebService.SetRange(Published, true);
        exit(TenantWebService.FindFirst());
    end;

    /// <summary>
    /// Gets the published endpoint URL for an API page
    /// </summary>
    procedure GetPublishedEndpointURL(ObjectID: Integer): Text
    var
        TenantWebService: Record "Tenant Web Service";
        BaseURL: Text;
    begin
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Page);
        TenantWebService.SetRange("Object ID", ObjectID);
        if not TenantWebService.FindFirst() then
            exit('');

        // Get base URL from config
        BaseURL := GetBaseURL();
        exit(BaseURL + '/' + TenantWebService."Service Name");
    end;

    /// <summary>
    /// Gets the base URL for the current BC instance
    /// </summary>
    local procedure GetBaseURL(): Text
    begin
        // This would need to be configured or detected
        // For now, return placeholder
        exit('https://api.businesscentral.dynamics.com/v2.0');
    end;
}
