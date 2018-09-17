public class UserLoginCtrl {

   public String ClientId = '648598935999-agidbcfik64sihalf62a4pccjra1dcu2.apps.googleusercontent.com';
   public string ClientSecret = 'LzTzeyXctDyss1MuK6JEtU8b';
   public string redirectURI  = 'https://lightningwave1-dev-ed--c.ap4.visual.force.com/apex/UserLogin';
  
   public string responseBody{get;set;}
   public string IdentificationToken{get;set;}
   public string accessToken{get;set;}
   
   public UserLoginCtrl(){
      IdentificationToken=ApexPages.CurrentPage().getParameters().get('code');
      if(IdentificationToken!=null){
        authenticate();
      }
      
   }
   
   public pageReference ConnectWithGoogle(){
   
   pageReference p=new pageReference(new GoogleOAuth(ClientID,redirectUri).OAuthUri);
   
   return p;
   
   }
  
   
   public string accessToken()
  {
    HttpRequest req=new HttpRequest();
    req.setEndpoint('https://accounts.google.com/o/oauth2/token');
    req.setMethod('POST');
    req.setHeader('content-type','application/x-www-form-urlencoded');
    String b='code='+IdentificationToken+'&client_id='+ClientID+'&client_secret='+ClientSecret+'&redirect_uri='+redirectUri+'&grant_type=authorization_code';
    req.setBody(b);
    
  
    Http ht=new Http();
    
    HttpResponse res=ht.send(req);
    
    string body=res.getBody();
    
    fromJSON2 fd2=(fromJSON2)JSON.deserialize(body,fromJSON2.class);
    
    accessToken=fd2.access_Token;
    
    return accessToken;
  }
  
   
   
   public pageReference authenticate(){
   
    if(string.isNotEmpty(IdentificationToken)){
       string accessToken = accessToken();   
   
     HttpRequest req = new HttpRequest();
     req.setEndpoint('https://people.googleapis.com/v1/people/me?personFields=addresses,emailAddresses,genders,names,birthdays');
     req.setMethod('GET');
     req.setHeader('content-type','application/json');
     req.setHeader('Authorization','Bearer ' + accessToken);
     Http ht = new Http();
     HttpResponse res  = ht.send(req);
     responseBody = res.getBody();
     fromJSON fd  = (fromJSON)JSON.deserialize(responseBody, fromJSON.class);
     string resourceId  =  fd.names[0].metadata.source.id;
     string displayName  =  fd.names[0].displayName;
     string emailAddress = fd.emailAddresses[0].value; 
     system.debug(fd.names[0].metadata.source.id +' '+fd.names[0].displayName+' '+fd.emailAddresses[0].value);
     
     List<User_Details_SSO__c> UserLoginDetails  = [SELECT id,Display_Name__c,Resource_Id__c,Source__c,Email__c 
                                                           FROM User_Details_SSO__c WHERE Resource_Id__c=:resourceId];
     pageReference p = new pageReference('/apex/UserDetails');
     
     p.getParameters().put('resourceId',resourceId); 
     p.setRedirect(true);                                                     
     if(UserLoginDetails.isEmpty()){
        User_Details_SSO__c userDetails = new User_Details_SSO__c();
        userDetails.Display_Name__c = displayName;
        userDetails.Resource_Id__c = resourceId;
        userDetails.Source__c = 'Google';
        //userDetails.Email__c =  emailAddress;
        insert userDetails;
        p.getParameters().put('id',userDetails.id);
       
     }
     else{
       p.getParameters().put('id',UserLoginDetails[0].id);
       
     }
     return p; 
    }
     return null;
     
   }
   
   public class fromJSON{
    public String resourceName; //people/106452211227304310962
    public String etag; //%EgsBAj0HCAk+EEA3LhoMAQIDBAUGBwgJCgsM
    public cls_names[] names;
    public cls_birthdays[] birthdays;
    public cls_emailAddresses[] emailAddresses;
    }
    class cls_names {
        public cls_metadata metadata;
        public String displayName;  
        public String familyName;   
        public String givenName;    
        public String displayNameLastFirst; 
    }
    class cls_metadata {
        public boolean primary;
        public boolean verified;
        public cls_source source;
    }
    class cls_source {
        public String type; //ACCOUNT
        public String id;   //106452211227304310962
    }
    class cls_birthdays {
        public cls_metadata metadata;
        public cls_date dates;
    }
    class cls_date {
        public Integer year;    
        public Integer month;   
        public Integer day; 
    }
    class cls_emailAddresses {
        public cls_metadata metadata;
        public String value;    
    }
    
    public class fromJSON2
  {
     public string access_token{get;set;} 
  }

}