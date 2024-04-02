<cfcomponent displayname="security" output="false" accessors="true">

    <cfproperty name="merchantService">
    <cfproperty name="orderService">
    <cfproperty name="productService">

    <cffunction name="init" returntype="any" output="false">
        <cfargument name="fw" type="any" required="true">

        <cfset variables.fw = arguments.fw>
        <cfreturn this>
    </cffunction>

    <cffunction name="before" access="public" output="false">
        <cfargument name="rc" type="struct" required="true">
        <cfargument name="headers" type="struct" required="true">

        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var hash = binaryEncode(binaryDecode(hmac(httpContent.getBytes('utf-8'),application.shopify.credentialSets,"HMACSHA256"),"hex"),"base64")>

        <cfif NOT structKeyExists(arguments.headers,"x-shopify-hmac-sha256") OR (structKeyExists(arguments.headers,"x-shopify-hmac-sha256") AND hash NEQ arguments.headers["x-shopify-hmac-sha256"])>
            <cfset variables.merchantService.simpleLog(stLogData = {"type":"warning","message":"rejected webhook", "arguments":arguments}, filename = "webhooks", sendNotification = false)>
            <cfset variables.fw.renderData().data({}).type("json").statusCode(401)>
            <cfset variables.fw.abortController()>

        <!--- don't process any webhooks when in maintenance mode, return a 200ok immediately --->
        <cfelseif application.mode EQ "maint">
            <cfset variables.fw.renderData().data({}).type("json").statusCode(200)>
            <cfset variables.fw.abortController()>
        </cfif>

    </cffunction>


    <cffunction name="uninstallapp" access="public" output="false">
        <cfargument name="rc" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var stData = {}>

        <cfif isJSON(httpContent)>
            <cfset stData = deserializeJSON(httpContent)>
        </cfif>

        <cfif NOT structIsEmpty(stData)>
            <cftry>
            <cfset variables.merchantService.uninstallApp(stData)>
            <cfcatch>
                <cfset variables.merchantService.simpleLog(stLogData = cfcatch, filename = "webhooks", sendNotification = true)>
            </cfcatch>
            </cftry>
        </cfif>
        <cfset variables.fw.renderData().data(stResult).type("json").statusCode(200)>
        <cfreturn>

    </cffunction>


    <cffunction name="customerRedact" access="public" output="false">
        <cfargument name="rc" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var stData = {}>

        <cfif isJSON(httpContent)>
            <cfset stData = deserializeJSON(httpContent)>
        </cfif>
        <cftry>
        <cfif NOT structIsEmpty(stData)>
            <cfset variables.merchantService.customerRedact(stData)>
        </cfif>
        <cfcatch>
            <cfset variables.merchantService.simpleLog(stLogData = cfcatch, filename = "webhooks",sendNotification = true)>
        </cfcatch>
        </cftry>
        <cfset variables.fw.renderData().data(stResult).type("json").statusCode(200)>
        <cfreturn>
    </cffunction>


    <cffunction name="shopRedact" access="public" output="false">
        <cfargument name="rc" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var stData = {}>

        <cfif isJSON(httpContent)>
            <cfset stData = deserializeJSON(httpContent)>
        </cfif>
        <cftry>
        <cfif NOT structIsEmpty(stData)>
            <cfset variables.merchantService.shopRedact(stData)>
        </cfif>
        <cfcatch>
            <cfset variables.merchantService.simpleLog(stLogData = cfcatch, filename = "webhooks", sendNotification = true)>
        </cfcatch>
        </cftry>
        <cfset variables.fw.renderData().data(stResult).type("json").statusCode(200)>
        <cfreturn>
    </cffunction>


    <cffunction name="customerDataRequest" access="public" output="false">
        <cfargument name="rc" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var stData = {}>

        <cfif isJSON(httpContent)>
            <cfset stData = deserializeJSON(httpContent)>
        </cfif>
        <cftry>
        <cfif NOT structIsEmpty(stData)>
            <cfset stResult = variables.merchantService.customerDataRequest(stData)>
        </cfif>
        <cfcatch>
            <cfset variables.merchantService.simpleLog(stLogData = cfcatch, filename = "webhooks",sendNotification = true)>
        </cfcatch>
        </cftry>
        <cfset variables.fw.renderData().data(stResult).type("json").statusCode(200)>
        <cfreturn>
    </cffunction>

    <cffunction name="processOrder" access="public" output="false">
        <cfargument name="rc" type="struct" required="true">
        <cfargument name="headers" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var stData = {}>

        <cfif isJSON(httpContent)>
            <cfset stData = deserializeJSON(httpContent)>
            <cfif NOT structIsEmpty(stData)>
                <cfthread action="run" name="ordercreate_#(now()+0)#" stData="#stData#" shop="#arguments.headers["X-Shopify-Shop-Domain"]#">
                    <cftry>
                        <cfset var merchant = variables.merchantService.getMerchant(attributes.shop)>
                        <cfif NOT isNull(merchant)>
                            <cfset variables.orderService.sendOrder(merchant=merchant , orderData= attributes.stData)>
                        <cfelse>
                            <cfset variables.merchantService.simpleLog(stLogData = {"type":"error","message":"merchant [#attributes.shop#] not found!"}, filename = "webhooks")>
                        </cfif>
                        <cfcatch>
                            <cfset variables.merchantService.simpleLog(stLogData = {cfcatch:cfcatch}, filename = "webhooks")>
                        </cfcatch>
                    </cftry>
                </cfthread>
            </cfif>
        </cfif>
        <cfset variables.fw.renderData().data(stResult).type("json").statusCode(200)>
    </cffunction>


    <cffunction name="transferProduct" access="public" output="false">
        <cfargument name="rc" type="struct" required="true">
        <cfargument name="headers" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var stData = {}>


        <cfif isJSON(httpContent)>
            <cfset stData = deserializeJSON(httpContent)>

            <cfif NOT structIsEmpty(stData)>

                <cfthread action="run" name="ordercreate_#(now()+0)#" stData="#stData#" shop="#arguments.headers["X-Shopify-Shop-Domain"]#">
                    <cftry>
                        <cfset variables.productService.transferProductWebhook(shop = attributes.shop, productdata = attributes.stData)>
                        <cfcatch>
                            <cfset variables.productService.simpleLog(stLogData = {cfcatch:cfcatch}, filename = "webhooks")>
                        </cfcatch>
                    </cftry>
                </cfthread>
            </cfif>
        </cfif>
        <cfset variables.fw.renderData().data(stResult).type("json").statusCode(200)>
    </cffunction>


    <cffunction name="deleteProduct" access="public" output="false">
        <cfargument name="rc" type="struct" required="true">
        <cfargument name="headers" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var stData = {}>

        <cfif isJSON(httpContent)>
            <cfset stData = deserializeJSON(httpContent)>
            <cfif NOT structIsEmpty(stData)>
                <cfthread action="run" name="ordercreate_#(now()+0)#" stData="#stData#" shop="#arguments.headers["X-Shopify-Shop-Domain"]#">
                    <cftry>
                        <cfset variables.productService.deleteProductWebhook(shop = attributes.shop, productdata = attributes.stData)>
                    <cfcatch>
                        <cfset variables.productService.simpleLog(stLogData = {httpcontent:cfcatch}, filename = "webhooks")>
                    </cfcatch>
                    </cftry>
                </cfthread>
            </cfif>
        </cfif>
        <cfset variables.fw.renderData().data(stResult).type("json").statusCode(200)>
    </cffunction>


    <cffunction name="testwebhooks" access="public">
        <cfargument name="rc" type="struct" required="true">
        <cfargument name="headers" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var httpContent = getHTTPRequestData().content>
        <cfset var stData = {}>
        <cftry>
        <cfset var calculated = binaryEncode(binaryDecode(hmac(httpContent, APPLICATION.shopify.credentialSets,"HMACSHA256"),"hex"),"base64")>
        <cfset variables.productService.simpleLog(stLogData = {"calculated":calculated,"shopify-header":arguments.headers["x-shopify-hmac-sha256"],content=getHTTPRequestData()}, filename = "webhooks")>
        <cfcatch>
            <cfset variables.productService.simpleLog(stLogData = {cfcatch:cfcatch}, filename = "webhooks")>
        </cfcatch>
        </cftry>
        <cfset variables.productService.simpleFile(filename="webhook_content.json", content = httpContent, directory="webhooks")>
        <cfset variables.productService.simpleFile(filename="webhook_headers.json", content = serializeJSON(arguments.headers),directory="webhooks")>

        <cfset variables.fw.renderData().data(stResult).type("json").statusCode(200)>
    </cffunction>

</cfcomponent>