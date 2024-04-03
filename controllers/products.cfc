<cfcomponent accessors="true" output="false" extends="app.model.services.base">

    <cfproperty name="productService">
    <cfproperty name="merchantService">


    <cffunction name="init" output="false" returntype="any">
        <cfargument name="fw" type="any" required="true">

        <cfset variables.fw = arguments.fw>
        <cfreturn this>
    </cffunction>

    <cffunction name="before" access="public" output="false">
        <cfargument name="rc" type="struct" required="true">
        <cfargument name="headers" type="struct" required="true">

        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var hash = "Basic #toBase64("#application.claro.username#:#application.claro.password#")#">

        <cfif NOT structKeyExists(arguments.headers,"Authorization") OR (structKeyExists(arguments.headers,"Authorization") AND hash NEQ arguments.headers["Authorization"])>
            <cfset simpleLog(stLogData = {"type":"warning","message":"rejected API Call", "arguments":arguments}, filename = "API")>
            <cfset variables.fw.renderData().data({}).type("json").statusCode(401)>
            <cfset variables.fw.abortController()>
        </cfif>
       
    </cffunction>

    <cffunction name="get" output="false">
        <cfargument name="rc" type="struct" required="true">

        
        <cfif structKeyExists(arguments.rc,'id')>
            <cfset var stResult = variables.productService.get(id=arguments.rc.id)>
            
            <cfif stResult.ok>
                <cfset variables.fw.renderData().data(stResult.product).type("json").statusCode(200)>
                <cfset variables.fw.abortController()>
            <cfelse>
                <cfset variables.fw.renderData().data({}).type("json").statusCode(404)>
                <cfset variables.fw.abortController()>
            </cfif>
        </cfif>
        <cfset variables.fw.renderData().data({"error":"required parameter missing or invalid"}).type("json").statusCode(406)>
    </cffunction>


    <cffunction name="new" output="false">
        <cfargument name="rc" type="struct" required="true">

        <cfset var stResult = {}>

        <cfif structKeyExists(arguments.rc,"product") and variables.productService.validateProduct(arguments.rc.product)>

            <cfset stResult = variables.productservice.new(product = arguments.rc.product)>
            
            <cfif stResult.ok>
                <cfset variables.fw.renderData().data(stResult.product).type("json").statusCode(200)>
            <cfelse>
                <cfset variables.fw.renderData().data(stResult.error).type("json").statusCode(400)>
            </cfif>
        <cfelse>
            <cfset variables.fw.renderData().data({"error":"required parameter missing or invalid"}).type("json").statusCode(406)>
        </cfif>

    </cffunction>
    
    <cffunction name="update" output="false">
        <cfargument name="rc" type="struct" required="true">

        <cfif structKeyExists(arguments.rc,"product") and variables.productService.validateProduct(arguments.rc.product) and structKeyExists(arguments.rc,"id") >

            <cfset var stResult = variables.productservice.update(id = arguments.rc.id, product = arguments.rc.product)>
            
            <cfif stResult.ok>
                <cfset variables.fw.renderData().data(stResult.product).type("json").statusCode(200)>
            <cfelse>

                <cfset var error_code = 400>
                <cfif structkeyExists(stResult,"error_code")>
                    <cfset error_code = stResult.error_code>
                </cfif>
                <cfset variables.fw.renderData().data(stResult).type("json").statusCode(error_code)>
            </cfif>
        <cfelse>
            <cfset variables.fw.renderData().data({"error":"required parameter missing or invalid"}).type("json").statusCode(406)>
        </cfif>

    </cffunction>

    <cffunction name="updateInventory" output="false">
        <cfargument name="rc" type="struct" required="true">

        <cfif structKeyExists(arguments.rc,"product") and structKeyExists(arguments.rc,"id") and structKeyExists(arguments.rc.product,"inventory_quantity")>

            <cfset var stResult = variables.productservice.updateInventory(id = arguments.rc.id, product = arguments.rc.product)>
            
            <cfif stResult.ok>
                <cfset variables.fw.renderData().data({}).type("json").statusCode(200)>
            <cfelse>
                <cfset var error_code = 400>
                <cfif structkeyExists(stResult,"error_code")>
                    <cfset error_code = stResult.error_code>
                </cfif>
                <cfset variables.fw.renderData().data({"error":stResult.error}).type("json").statusCode(error_code)>
            </cfif>
        <cfelse>
            <cfset variables.fw.renderData().data({"error":"required parameter missing or invalid"}).type("json").statusCode(406)>
        </cfif>

    </cffunction>


    
</cfcomponent>