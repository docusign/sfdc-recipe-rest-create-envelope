# sfdc-recipe-rest-create-envelope

## Introduction:
This repository will aid end users in sending Envelopes from Salesforce using DocuSign eSignature for Salesforce, Apex and REST API.
This will be useful especially when business requirements require envelopes to be sent out without users clicking on Send with DocuSign. We will be using JWT Authentication for authenticating to DocuSign REST API's and then sending the envelope using REST API. This recipe will serve as a building block for users to customize and apply their own strategies while sending envelopes from Salesforce using Apex.

## Pre-requisites:
- Get a Salesforce Developer account
https://developer.salesforce.com/signup

- Get a DocuSign Developer account
https://go.docusign.com/o/sandbox

- Install DocuSign eSignature for Salesforce Managed package in your Salesforce org
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N30000001taX4EAI 

## Problem Statement:
Universal containers use DocuSign for electronically signing key Business documents. They use Salesforce as their CRM system and have DocuSign eSignature for Salesforce installed in their Salesforce instance.The Sales reps at Universal Containers use out of the box buttons provided by DocuSign eSignature for Salesforce to send Orders to prospective clients.The Legal department requires Approval documents to be sent dynamically based on certain business rules and does not want reps to manually send Envelopes.

## Solution:
Configure Envelope sending via Apex. This Apex Utility class can then be used in either triggers / Process Builders / Scheduled jobs to achieve the business requirement of dynamically sending an envelope from Salesforce.


##  Building Blocks:
- Install DocuSign eSignature for Salesforce
- DocuSign Integrator Key setup.
- DocuSign Template Setup.
- Installing Github source.
- Salesforce Remote Sites and Custom Metadata types setup.
- Developer Console demo.

## Step by Step Walkthrough
  
  ### 1. Install DocuSign eSignature for Salesforce
  After setting up a Salesforce Developer account as well as a DocuSign Developer account, [Install DocuSign eSignature for Salesforce from AppExchange](https://appexchange.salesforce.com/listingDetail?listingId=a0N30000001taX4EAI) in your Salesforce org.
  
  ### 2. DocuSign Integrator key setup 
  - Login to your DocuSign Developer account and click on **Settings** . 
  - Select **API and Keys** link which should be found under **'Integrations'**. 
  - Click on **Add Integrator Key**
  - Provide an App Description and click **Save**
  - Click on the newly created Integrator Key and from the resulting pop-up note down the **Integrator Key** . This will be a unique GUID which will be associated with your Integrator key.This needs to be updated in Salesforce.
  - Click on **Add URI** and add 'https://localhost.com'.
  - Click on **Add RSA Key Pair** and note down the Private Key. 
  The Private key will be updated in Salesforce. **Do not copy the ----BEGIN RSA PRIVATE KEY---- and ----END RSA PRIVATE KEY---- lines**. 
  Click OK. 
  We have chosen to generate the RSA Key Pair since we will generating the JWT token to pass to the authentication key using the Private Key that we have noted down. This Private Key will be signed with Header and Body of the Request to complete the JWT token. Please refer the [JSON Web Token Bearer Grant](https://developers.docusign.com/esign-rest-api/guides/authentication/oauth2-jsonwebtoken) link for additional information on JWT and token construction.
  
  
 ![Integrator Key Screenshot](/images/IntegratorKey.JPG) 
 
 #### Impersonating user for API calls.
 Since our recipe will be using the Integrator key to send Envelopes we must ensure that a DocuSign user provides consent to the Integrator key. In this case the DocuSign user will be our Sandbox user. In case of service integrations we can setup a service user and grant consent on this user's behalf.
 
 To complete this step open the following URI in a browser:
 
 `https://account-d.docusign.com/oauth/auth?
  response_type=code&scope=signature%20impersonation&client_id=YOUR_KEY&redirect_uri=https://localhost.com`
 
 Make sure we add the correct Integrator key for the client_id URL parameter and also make sure the redirect_uri parameter matches with the redirect uri you have setup under the integrator key.
 
 This will open up a consent screen. Click Accept
 
 ![Consent Screenshot](/images/Consent.JPG) 
 
 After clicking Accept you will be redirected to the redirect URI specified in the URI as well as the Integrator key. For the purpose of this recipe I am using 'https://localhost.com' so, if you are redirected to this URI it means that the consent has been granted successfully.
 
  ### 3. Note down DocuSign API UserName and API AccountID.
  - Login to your DocuSign Developer Sandbox and click on **Go to Admin** . 
  - Select **API and Keys** link which should be found under **'Integrations'**. 
  - Note down the **API Username** and **API AccountID**. This will be stored in Salesforce Custom Metadata.
  
  ### 4. DocuSign Template Setup.
  - Create a Template in DocuSign and add a recipient to the template. 
  - The recipient email address will be the destination for our envelope for this case study. 
  - Add a sample document as an attachment to the template.
  - Add signature field on the template.
  - Save the template
  
  For more information visit [Creating templates in DocuSign](https://support.docusign.com/guides/ndse-user-guide-create-templates)
  
  - Note down the Template ID. This will be stored in Salesforce Custom metadata.
  
  ![Template Id](/images/TemplateId.JPG) 
  

### 5. Install Source:
- Deploy the files present under the **src** folder to your Salesforce org. The src folder contains package package.xml which will help you to deploy the src.
- You can use Workbench for installation. Zip all the files such that folders and xml file present under src folder are at the root of the zip file.
- Login to Workbench
- Click on migration -> Deploy
- Select the zip file created in the earlier step. Check the **Single Package** checkbox and click on **Next**
- Click Deploy



### 6. Salesforce Custom Metadata setup:
- Once the source files have been deployed successfully to your Salesforce org, navigate to Setup -> Custom metadata types
- Click **Manage Records** under **DocuSignRESTSettings**
- Replace the values in the settings with the values for your DocuSign instance:
   - DSAccount  -> Your DocuSign API AccountID noted in step 3.
   - DSUserName -> Your DocuSign API Username noted in step 3.
   - DSUserName -> Your DocuSign API Username noted in step 3.
   - RequestIntegratorKey -> Your Integrator Key Id created in step 2.
   - RequestPrivateKey -> Your Private Key created in step 2.
   - RequestEnvelopeTemplateID -> Your DocuSign template Id created in Step 4.
   - RequestEnvelopeSubject -> Subject for the DocuSign Envelope (Edit this value if you want your own subject)
   
### 7. Salesforce Remote Site Settings: 
- Add '	https://account-d.docusign.com' as a Remote Site URL in your Salesforce instance. 
- DocuSign eSignature for Salesforce managed package already adds 'https://demo.docusign.net' as a Remote Site URL.
- Both thes URL's should be present under Remote Site settings for the integration to work as expected

### 8. Access Token Demo: 
- Open Developer Console
- Press CTRL + E (open execute Anonymous code window)
- Add the following line of code :
  `DocuSignRestUtility.getAccessToken();`
- Highlight the added line of code and press **Execute Highlighted**  
- Navigate to the generated log file and choose *Debug Only* level to monitor the logs generated.
- If the Integration and setup is successfull you will notice a Status Code of 200 and the **ResponseAuthBody** parameter will also contain the `access_token`

![DeveloperConsole.JPG](/images/DeveloperConsole.JPG) 

### 9. Send Envelope using Apex:
- Open Developer Console
- Press CTRL + E (open execute Anonymous code window)
- Add the following line of code :
  `DocuSignRESTUtility.createEnvelope();`
- Highlight the added line of code and press **Execute Highlighted**    

This should send a DocuSign Envelope with the Template as the Document and the recipient defined in the template.

## Extending the Recipe:
The createEnvelope method can be extended to:
- Future callouts in order to send Envelopes via Apex Trigger / Scheduled Jobs / Batch jobs
- Invocable methods to send Envelopes via Process Builders.

## License

The DocuSign Java Client is licensed under the following [License](LICENSE).
