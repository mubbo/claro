<!--- bundle lite --->
<cfcomponent output="false">

    <cffunction name="init" access="public" returntype="any" output="false">
        <cfargument name="slang" type="string" required="false" default="#application.general.languages[1]#">
        <cfif arrayFind(application.general.languages,arguments.slang)>
            <cfset variables.slang = arguments.slang>
        <cfelse>
            <cfset variables.slang = "en">
        </cfif>
        <cfreturn this>
    </cffunction>

    <cffunction name="getBundle" access="public" returntype="struct" output="false">
        <cfargument name="sBundle" type="string">
        <cfargument name="sBundlePath" type="string" default="./i18n/">
        <cfargument name="lang" type="string" required="false" default="#variables.slang#">

            <cfset var bIsOk = false> // success flag
            <cfset var keys = "">
            <cfset var stResourceBundle = {}> // structure to hold resource bundle
            <cfset var thisKey = "">
            <cfset var thisMSG = "">
            <cfset var sResourceFilePath = "">

                // java objects to read bundle
            <cfset var oI18N = CreateObject("java", "java.util.PropertyResourceBundle")>
            <cfset var oFis = CreateObject("java", "java.io.FileInputStream")>

            <cfset sResourceFilePath = expandPath(arguments.sBundlePath & arguments.sBundle & "_" & arguments.Lang & ".properties")>

            <cfif (fileExists(sResourceFilePath)) >
                <cfset bIsOk=true>
                <cfset oFis.init(sResourceFilePath)>
                <cfset oI18N.init(oFis)>
                <cfset keys=oI18N.getKeys()>
                <cfscript>
                    while (keys.hasMoreElements()) {
                        thisKEY=keys.nextElement();
                        thisMSG=oI18N.handleGetObject(thisKey);
                        stResourceBundle["#lcase(thisKEY)#"]=thisMSG;
                    }
                    oFis.close();
                </cfscript>
            </cfif>
            <cfif (bIsOk)>
                <cfset request["st#arguments.sBundle#"] = stResourceBundle>
            <cfelse>
                <cfthrow message="Fatal error: resource bundle #sResourceFilePath# not found.">
            </cfif>
        <cfreturn stResourceBundle>
	</cffunction>

</cfcomponent>