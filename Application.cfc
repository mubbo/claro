<cfcomponent displayname="Application" output="false">
	<cfset this.name="swisspostalapp">
	<cfset this.Datasource 			= "swisspostal">
	<cfset this.applicationTimeout  = createTimeSpan(0,20,0,0)>
    <cfset this.sessionmanagement = false>
    <cfset this.SetClientCookies = false>

	<cfset this.rootDir = getDirectoryFromPath(getCurrentTemplatePath()) />
	<cfset this.mappings[ "/framework" ] = "#this.rootDir#framework" />
	<cfset this.mappings[ "/app" ] = "#this.rootDir#" />

    <cfsetting requesttimeout = "1200">

	  <cfset this.cache.connections["default"] = {
		class: 'lucee.runtime.cache.ram.RamCache'
	  , storage: false
	  , custom: {
		  "timeToIdleSeconds":"0",
		  "timeToLiveSeconds":"0"
	  }
	  , default: 'object'
  }>


	<cffunction name="_get_framework_one" returntype="any" output="false">

		<cfif NOT structKeyExists( request, '_framework_one' )>
            <cfset request._framework_one = new MyApplication({
				trace: false,
				reload = 'reload',
                decodeRequestBody = true,
				missingview = 'main.missingview',
				generateSES = true,
                SESOmitIndex = true,
				reloadApplicationOnEveryRequest = true,
                subsystemdelimiter = ":",
                preflightOptions = true,
                routes:[
                    {"$GET/api/products/{id:[0-9]+}" = "products/get/id/:id"},
                    {"$POST/api/products/{id:[0-9]+}" = "products/update/id/:id"},
                    {"$POST/api/products/" = "products/new"},
                    {"$POST/api/inventory/{id:[0-9]+}" = "products/updateInventory/id/:id"} 
                ],
                routesCaseSensitive = false
			})>

        </cfif>
        <cfreturn request._framework_one>
    </cffunction>

	<cffunction	name="OnRequestStart" access="public" output="false">
		<cfargument name="TargetPage" type="string" required="true"/>

		<cfset _get_framework_one().onRequestStart( TargetPage )>

		<cfreturn true>
	</cffunction>

	<cffunction	name="OnApplicationStart" access="public" output="false">
		<cfreturn _get_framework_one().onApplicationStart()>
	</cffunction>

	<cffunction name="onSessionStart" access="public" output="false">
		<cfset _get_framework_one().onSessionStart()>
	</cffunction>



	<cffunction name="onRequest" access="public" output="true">
		<cfargument name="targetPage" type="string" required="true">
		<cfset _get_framework_one().onRequest( targetPage )>
	</cffunction>

	<cffunction name="onRequestEnd">
		<cfreturn _get_framework_one().onRequestEnd( )>
	</cffunction>

	<cffunction name="onError">
		<cfargument name="exception">
		<cfargument name="event">

		<cfreturn _get_framework_one().onError( exception, event )>
	</cffunction>



</cfcomponent>