/* This class is responsible for sending Envelopes by making REST Callouts to DocuSign */
/* You can extend the createEnvelope method by invoking it from triggers / scheduled apex / batch jobs */
/* You can also create invocable actions by referencing the createEnvelope method and use it in Process Builders */

public class DocuSignRESTUtility {

    //Get Rest Configuration Setings from Custom Metadata provided as a part of the installation source 
    private static Map<String, DocuSignRESTSettings__mdt> settingsMap { 
        //Getter Method
        get {
            //populate only if settingsMap is null
            if (settingsMap == null) {
                settingsMap = new Map<String, DocuSignRESTSettings__mdt>();
                //Query the Custom Metadata and add it to the Map
                //Query against Custom Metadata does not count against the SOQL query Limit
                for (DocuSignRESTSettings__mdt setting : [Select DeveloperName,MasterLabel, Value__c from DocuSignRESTSettings__mdt]) {
                    settingsMap.put(setting.MasterLabel, setting);
                }
            }
            return settingsMap;
        }
        //Blank Setter Method
        set {
        }
    }

    private static Docusign_Access_Token__c processNewAccessToken() {
        Map<String, Object> tokInfo     = createNewAccessToken();
        Docusign_Access_Token__c accTok = new Docusign_Access_Token__c(
            Expire_Time__c = String.ValueOf((Datetime.now().getTime()/1000) + (Integer)tokInfo.get('expires_in')),
            Token_Value__c = (String)tokInfo.get('access_token')
        );
        return accTok;
    }

    public static Docusign_Access_Token__c getAccessToken() {
        
        Docusign_Access_Token__c token = null;
        // authData = getAuthData();
        
        List<Docusign_Access_Token__c> dats = [
            SELECT Id, Expire_Time__c, Token_Value__c
            FROM Docusign_Access_Token__c
            ORDER BY Expire_Time__c DESC, CreatedDate DESC
        ];
        if (dats != null && dats.size() > 0) {
            Docusign_Access_Token__c existing = dats[0];
            Long expTime = long.valueOf(existing.Expire_Time__c);
            if ( expTime != null && expTime > ( Datetime.now().getTime() / 1000 ) ) {
                token = existing;
                System.Debug('Retrieve existing access token from object and it is : ' + token);
            }
            else {
                token = processNewAccessToken();
                System.Debug('New access token created and it is : ' + token);
            }
        }
        else 
        {
            token = processNewAccessToken();
            System.Debug('New access token created and it is : ' + token);
        }
        return token;
    }

    //This method will call the DocuSignJWT class to obtain an access token from DocuSign
    public static Map<String, Object> createNewAccessToken() {
         Map<String, Object> access_token = null;
        
        //Instantiate a request object
        HttpRequest req = new HttpRequest();
        //set the request METHOD
        req.setMethod('POST');
        
        //set the request endpoint
        String authendpoint = settingsMap.get('RequestAuthEndpoint').Value__c;
        System.Debug(LoggingLevel.INFO, '**RequestAuthEndpoint' + authendpoint);
        req.setEndPoint(authendpoint);

        //set the request headers
        //1. Content -type
        String authRequestContentType = settingsMap.get('RequestAuthContentType').Value__c;
        System.Debug(LoggingLevel.INFO, '**authRequestContentType ' + authRequestContentType);
        req.setHeader('Content-type', authRequestContentType);

        //2. Host
        String authRequestDomain = settingsMap.get('RequestAuthDomain').Value__c;
        System.Debug(LoggingLevel.INFO, '**authRequestDomain ' + authRequestDomain);
        req.setHeader('Host', authRequestDomain);

        //Body of the request
        String alg = 'RS256';
        String iss = settingsMap.get('RequestIntegratorKey').Value__c;
        String pkey = settingsMap.get('RequestPrivateKey').Value__c;
        String scope = settingsMap.get('RequestScope').Value__c;
        DocusignJWT jwtObject = new DocusignJWT(alg, settingsMap.get('DSUserName').Value__c, iss, pkey, scope, authRequestDomain);
		
	//Set the request body	
        String requestBody = settingsMap.get('RequestAuthBody').Value__c + jwtObject .issue();
        System.Debug(LoggingLevel.INFO, '**RequestAuthBody' + requestBody);
        req.setBody(requestBody);

        //call the service
        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.Debug(LoggingLevel.INFO, '**ResponseAuthBody' + res.getbody());
        System.Debug(LoggingLevel.INFO, '**ResponseAuth' + res);

        Map<String, Object> token = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
		
	//Obtain the access token from the Response
        if (res.getStatusCode() == 200) {
            access_token = token; 
        }

        return access_token;

    }
    
    private static void insertAccessTokenIfNew(Docusign_Access_Token__c accTok) {
        if (String.isBlank(accTok.Id)) {
            insert accTok;
        }
    }
    
    //This method will invoke the outbound REST call to the Docusign API for creating the envelope
    @future(callout=true)
    public static void createEnvelope() {
        //Get the access token
        Docusign_Access_Token__c accessToken = getAccessToken();   
        System.Debug(LoggingLevel.INFO, '***accessToken ' + accessToken);

        //Call envelope Creation service if a non-empty access token is returned
        if (!String.isEmpty(accessToken.Token_Value__c)) {
            //instantiate an Http instance  
            Http httpProtocol = new Http();

            //instantiate an HttpRequest instance  
            HttpRequest request = new HttpRequest();

            //Set the request parameters 
            // Request endpoint for createEnvelope call
            String endpoint = settingsMap.get('RequestEnvelopeEndpoint').Value__c + settingsMap.get('DSAccountID').Value__c + '/envelopes';
            System.Debug(LoggingLevel.INFO, '***endpoint ' + endpoint);
            request.setEndPoint(endpoint);

            //set the POST method
            request.setMethod('POST');

            //set Authentication Header
            request.setHeader('grant_type', 'Bearer');
            request.setHeader('Authorization', 'Bearer ' + accessToken.Token_Value__c);

            //set Accept Header
            request.setHeader('Accept', 'application/json');

            //set Content Type Header
            request.setHeader('Content-type', 'application/json');

            //create the request Body

            //create instance of the EnvelopeCreationRequest class
            DocuSignRESTUtility.EnvelopeCreationRequest requestObject = new DocuSignRESTUtility.EnvelopeCreationRequest();
            requestObject.status = settingsMap.get('RequestEnvelopeStatus').Value__c;
            requestObject.emailSubject = settingsMap.get('RequestEnvelopeSubject').Value__c;
            requestObject.templateId = settingsMap.get('RequestEnvelopeTemplateID').Value__c;
                        

            System.Debug(LoggingLevel.INFO, '***requestObject() ' + requestObject);
            String jsonBody = json.serialize(requestObject);
            System.Debug(LoggingLevel.INFO, '***jsonBody() ' + jsonBody);
            request.setBody(jsonBody);

            //Make the request and capture the response
            HttpResponse response = httpProtocol.send(request);
            System.Debug(LoggingLevel.INFO, '***response.getBody() ' + response.getBody());
            System.debug(LoggingLevel.INFO, '***response.getStatus() ' + response.getStatus());
			
	    //Parse the response
            String responseStatus = response.getStatus();
            if (responseStatus.equals('Created')) {
                DocuSignRESTUtility.EnvelopeCreationResponse responseObject = new DocuSignRESTUtility.EnvelopeCreationResponse();
                responseObject = (DocuSignRESTUtility.EnvelopeCreationResponse)System.JSON.deserialize(response.getBody(), DocuSignRESTUtility.EnvelopeCreationResponse.class);
                System.Debug(LoggingLevel.INFO, '***responseObject ' + responseObject);
            }
            
            insertAccessTokenIfNew(accessToken);
            
        }
    }

    //wrapper class for Envelope Creation Request
    //This class can be further re-vamped to create complex Envelopes to be passed to the createEnvelope Service
    //For more information refer https://developers.docusign.com/esign-rest-api/reference/Envelopes/Envelopes/create
    public class EnvelopeCreationRequest {
        public String emailSubject { get; set; }
        public String status { get; set; }
        public String templateId { get; set; }
    }

    //wrapper class for Envelope Creation Response
    public class EnvelopeCreationResponse {
        public String envelopeId { get; set; }
        public String uri { get; set; }
        public String status { get; set; }
        public String statusDateTime { get; set; }
    }

}
