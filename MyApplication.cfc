component extends="framework.one"{


    function setupApplication() {

        include "config/config.cfm";

        application.general.root = getDirectoryFromPath(getCurrentTemplatePath());
        application.general.rootpath = getDirectoryFromPath(getCurrentTemplatePath());

    }

    function setupEnvironment( env ) { }

    function setupSession() {
     }

    public function setupRequest() {
        
    }

    function setupResponse( rc ) {
     }

    function setupSubsystem( module ) { }

    function setupView( rc ) {

        arguments.rc["_"] = geti18nText;

    }



    string function geti18nText(string key){
        var stI18n = application.i18n[request.security.getCurrentLanguage()];
        if(structKeyExists(stI18n,arguments.key)){
            return stI18n[arguments.key];
        }else{
            return request.security.getCurrentLanguage() & ": " & arguments.key;
        }
    }

}
