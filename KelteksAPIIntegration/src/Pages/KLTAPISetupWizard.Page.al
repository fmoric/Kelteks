/// <summary>
/// Setup wizard for initial configuration
/// </summary>
page 50104 "KLT API Setup Wizard"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Kelteks API Integration Setup Wizard';

    layout
    {
        area(Content)
        {
            group(Step1)
            {
                Caption = 'Welcome';
                Visible = Step = Step::Welcome;

                group(Welcome)
                {
                    Caption = 'Welcome to Kelteks API Integration';
                    InstructionalText = 'This wizard will help you configure the API integration for Sales & Purchase Documents synchronization between BC v17 and BC v27.';
                    
                    field(WelcomeText; WelcomeTextVar)
                    {
                        ApplicationArea = All;
                        Caption = '';
                        MultiLine = true;
                        Editable = false;
                        ShowCaption = false;
                    }
                }
            }

            group(Step2)
            {
                Caption = 'BC17 Configuration';
                Visible = Step = Step::BC17Config;

                field("BC17 Base URL"; APIConfig."BC17 Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the BC17 API base URL';
                    ShowMandatory = true;
                }
                field("BC17 Company ID"; APIConfig."BC17 Company ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the BC17 Company GUID';
                    ShowMandatory = true;
                }
                field("BC17 Tenant ID"; APIConfig."BC17 Tenant ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the Azure AD Tenant ID for BC17';
                    ShowMandatory = true;
                }
                field("BC17 Client ID"; APIConfig."BC17 Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the OAuth Client ID for BC17';
                    ShowMandatory = true;
                }
                field("BC17 Client Secret"; APIConfig."BC17 Client Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the OAuth Client Secret for BC17';
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;
                }
            }

            group(Step3)
            {
                Caption = 'BC27 Configuration';
                Visible = Step = Step::BC27Config;

                field("BC27 Base URL"; APIConfig."BC27 Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the BC27 API base URL';
                    ShowMandatory = true;
                }
                field("BC27 Company ID"; APIConfig."BC27 Company ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the BC27 Company GUID';
                    ShowMandatory = true;
                }
                field("BC27 Tenant ID"; APIConfig."BC27 Tenant ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the Azure AD Tenant ID for BC27';
                    ShowMandatory = true;
                }
                field("BC27 Client ID"; APIConfig."BC27 Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the OAuth Client ID for BC27';
                    ShowMandatory = true;
                }
                field("BC27 Client Secret"; APIConfig."BC27 Client Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the OAuth Client Secret for BC27';
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;
                }
            }

            group(Step4)
            {
                Caption = 'Synchronization Settings';
                Visible = Step = Step::SyncSettings;

                field("Sync Interval (Minutes)"; APIConfig."Sync Interval (Minutes)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specify the interval between sync operations (recommended: 15 minutes)';
                }
                field("Batch Size"; APIConfig."Batch Size")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specify the maximum documents per batch (recommended: 100)';
                }
                field("API Timeout (Seconds)"; APIConfig."API Timeout (Seconds)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specify the API timeout (recommended: 5 seconds)';
                }
                field("Max Retry Attempts"; APIConfig."Max Retry Attempts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specify maximum retry attempts (recommended: 3)';
                }
                field("Alert Email Address"; APIConfig."Alert Email Address")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter email address for critical alerts';
                }
            }

            group(Step5)
            {
                Caption = 'Test Connection';
                Visible = Step = Step::TestConnection;

                group(TestResult)
                {
                    Caption = 'Connection Test Results';
                    
                    field(TestResultText; TestResultVar)
                    {
                        ApplicationArea = All;
                        Caption = '';
                        MultiLine = true;
                        Editable = false;
                        ShowCaption = false;
                        StyleExpr = TestResultStyle;
                    }
                }
            }

            group(Step6)
            {
                Caption = 'Finish';
                Visible = Step = Step::Finish;

                group(Completion)
                {
                    Caption = 'Setup Complete';
                    
                    field(FinishText; FinishTextVar)
                    {
                        ApplicationArea = All;
                        Caption = '';
                        MultiLine = true;
                        Editable = false;
                        ShowCaption = false;
                    }
                    
                    field("Enable Sync"; APIConfig."Enable Sync")
                    {
                        ApplicationArea = All;
                        Caption = 'Enable Automatic Synchronization';
                        ToolTip = 'Check to enable automatic synchronization';
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BackAction)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Image = PreviousRecord;
                InFooterBar = true;
                Enabled = Step <> Step::Welcome;

                trigger OnAction()
                begin
                    Step := Step - 1;
                end;
            }

            action(NextAction)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Image = NextRecord;
                InFooterBar = true;
                Enabled = Step <> Step::Finish;

                trigger OnAction()
                begin
                    if Step = Step::TestConnection then
                        RunConnectionTest();
                    
                    Step := Step + 1;
                end;
            }

            action(FinishAction)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Image = Approve;
                InFooterBar = true;
                Visible = Step = Step::Finish;

                trigger OnAction()
                begin
                    FinishSetup();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Step := Step::Welcome;
        APIConfig.GetInstance();
        InitializeText();
    end;

    local procedure InitializeText()
    begin
        WelcomeTextVar := 'This wizard will guide you through:\n\n' +
                         '1. Configuring BC17 API connection\n' +
                         '2. Configuring BC27 API connection\n' +
                         '3. Setting synchronization parameters\n' +
                         '4. Testing the connection\n' +
                         '5. Enabling the integration\n\n' +
                         'Before you start, ensure you have:\n' +
                         '- API credentials for both BC17 and BC27\n' +
                         '- Company GUIDs for both environments\n' +
                         '- Azure AD Tenant IDs\n' +
                         '- OAuth Client IDs and Secrets';

        FinishTextVar := 'Setup is complete!\n\n' +
                        'The API integration has been configured successfully.\n\n' +
                        'Next steps:\n' +
                        '1. Review the configuration in API Configuration page\n' +
                        '2. Create a Job Queue Entry for scheduled sync\n' +
                        '3. Enable automatic synchronization\n' +
                        '4. Monitor the Document Sync Log\n\n' +
                        'For more information, see the README documentation.';
    end;

    local procedure RunConnectionTest()
    var
        APIAuth: Codeunit "KLT API Authentication";
    begin
        APIConfig.Modify(true);
        
        if APIAuth.ValidateAuthentication() then begin
            TestResultVar := 'Connection test SUCCESSFUL!\n\n' +
                           'Both BC17 and BC27 connections are working correctly.\n\n' +
                           'Authentication is functioning properly.';
            TestResultStyle := 'Favorable';
        end else begin
            TestResultVar := 'Connection test FAILED!\n\n' +
                           'Please check your configuration:\n' +
                           '- Verify Base URLs are correct\n' +
                           '- Check Company IDs\n' +
                           '- Validate Azure AD Tenant IDs\n' +
                           '- Ensure Client IDs and Secrets are correct\n' +
                           '- Verify network connectivity';
            TestResultStyle := 'Unfavorable';
        end;
    end;

    local procedure FinishSetup()
    var
        SyncEngine: Codeunit "KLT Sync Engine";
    begin
        APIConfig.Modify(true);
        
        if APIConfig."Enable Sync" then begin
            SyncEngine.CreateJobQueueEntry();
            Message('Setup completed successfully!\n\nAutomatic synchronization has been enabled.');
        end else
            Message('Setup completed successfully!\n\nYou can enable synchronization later from the API Configuration page.');
        
        CurrPage.Close();
    end;

    var
        APIConfig: Record "KLT API Configuration";
        Step: Option Welcome,BC17Config,BC27Config,SyncSettings,TestConnection,Finish;
        WelcomeTextVar: Text;
        FinishTextVar: Text;
        TestResultVar: Text;
        TestResultStyle: Text;
}
