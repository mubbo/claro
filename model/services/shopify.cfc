<cfcomponent accessors="true" output="false" extends="base">

    <cffunction name="init" output="false" returntype="any">
        
        <cfreturn this>
    </cffunction>

    <!---
        Description: gets the shop information for the current shop
    --->
    <cffunction name="getShopInfo" returntype="struct" output="false">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfreturn do_apiaction(endpoint = "shop.json", method = "GET", shop=arguments.shop, accessToken = arguments.accessToken)>

    </cffunction>

    <!---
        Description: builds the orders request, handles pagination
    --->
    <cffunction name="getOrders" returntype="struct" output="false">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="limit" required="false" type="numeric" default="50">
        <cfargument name="page_info" required="false" type="string" default="">
        <cfargument name="status" required="false" type="string" default="any">
        <cfargument name="fields" required="false" type="string" default="">
        <cfargument name="query" required="false" type="struct" default="#{}#">

        <cfset var apiEndpoint = "orders.json?limit=#arguments.limit#">

        <cfif len(page_info)>
            <cfset apiEndpoint &= "&#arguments.page_info#">
        <cfelse>
            <cfset apiEndpoint &= "&status=#arguments.status#">
        </cfif>

        <cfif len(arguments.fields)>
            <cfset apiEndpoint &= "&fields=" & arguments.fields>
        </cfif>
        <cfif NOT structIsEmpty(arguments.query)>
            <cfloop collection="#arguments.query#" item="local.key">
                <cfset apiEndpoint &= "&#key#=#arguments.query[local.key]#">
            </cfloop>
        </cfif>


        <cfreturn do_apiaction(endpoint = apiEndpoint, method = "get", shop = arguments.shop, accessToken = arguments.accessToken)>

    </cffunction>


    <cffunction name="getOrderById" returntype="struct" output="false">
        <cfargument name="id" type="string" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfreturn  do_apiaction(endpoint = "orders/#arguments.id#.json", method="get", shop = arguments.shop, accessToken = arguments.accessToken)>

    </cffunction>

    <!---
        Description: builds the products request, handles pagination
    --->
    <cffunction name="getProducts" returntype="struct" output="false">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="limit" required="false" type="numeric" default="50">
        <cfargument name="page_info" required="false" type="string" default="">
        <cfargument name="fields" required="false" type="string" default="">
        <cfargument name="query" required="false" type="struct" default="#{}#">

        <cfset var apiEndpoint = "products.json?limit=#arguments.limit#">
        <cfset var stResult = {}>
        <cfif len(page_info)>
            <cfset apiEndpoint &= "&#arguments.page_info#">
        </cfif>

        <cfif len(arguments.fields)>
            <cfset apiEndpoint &= "&fields=" & arguments.fields>
        </cfif>
        <cfif NOT structIsEmpty(arguments.query)>
            <cfloop collection="#arguments.query#" item="local.key">
                <cfset apiEndpoint &= "&#key#=#arguments.query[local.key]#">
            </cfloop>
        </cfif>

        <cfset stResult = do_apiaction(endpoint = apiEndpoint, method = "get", shop = arguments.shop, accessToken = arguments.accessToken)>

        <cfreturn stResult>

    </cffunction>

    <!--- get product by id --->
    <cffunction name="getProductByID" returntype="struct" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var stResult = {}>

        <cfset stResult = do_apiaction(endpoint = '/products/#arguments.id#.json', method = "get", shop = arguments.shop, accessToken = arguments.accessToken)>

        <cfreturn stResult>
    </cffunction>
    <!---
        get locations associated with the merchant
    --->

    <cffunction name="getLocations" access="public" output="false" returntype="struct">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfreturn do_apiaction(endpoint = "locations.json", method="get", shop=arguments.shop, accessToken = arguments.accessToken)>

    </cffunction>
    <!---
        Description: Simple function that builds the shopify oAuth URL
    --->
    <cffunction name="getAuthenticationURL" access="public" output="false" returntype="String">
        <cfargument name="shopURL" required="true" type="string">

        <cfreturn "#arguments.shopURL#/admin/oauth/authorize?client_id=#APPLICATION.shopify.APIkey#&scope=#APPLICATION.shopify.specifyParts#&redirect_uri=#APPLICATION.shopify.callbackURL#">
    </cffunction>

    <!---
        create a reacurring charge
    --->
    <cffunction name="createRecurringCharge" returntype="struct" output="false">
        <cfargument name="name" 			required="true" type="string">
        <cfargument name="price" 			required="true" type="numeric">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="cappedAmount" 	required="false" type="numeric" default="0">
        <cfargument name="terms"         	required="false" type="string" default="">
        <cfargument name="returnURL" 		required="false" type="string" default="#APPLICATION.shopify.chargeCallbackURL#">
        <cfargument name="testing" 			required="false" type="boolean" default="false">
        <cfargument name="trialDays" 		required="false" type="numeric" default="0">

        <cfset var sPayload = "">
        <cfset var stReturn = {}>
        <cfset var apiEndpoint = "recurring_application_charges.json">

        <cfsavecontent variable="sPayload"><cfoutput>
            {
                "recurring_application_charge": {
                    "name": "#arguments.name#",
                    "price": #arguments.price#,
                    "return_url": "#arguments.returnURL#"
                    <cfif arguments.cappedAmount GT 0>,"capped_amount": #arguments.cappedAmount#</cfif>
                    <cfif arguments.trialDays GT 0>,"trial_days": #arguments.trialDays#</cfif>
                    <cfif arguments.testing>,"test": true</cfif>
                    <cfif len(arguments.terms) GT 0>,"terms": "#arguments.terms#"</cfif>
                }
            }
        </cfoutput></cfsavecontent>

        <cfset stReturn = do_apiaction(endpoint = apiEndpoint, sBody=sPayload, method="post", shop=arguments.shop, accessToken = arguments.accessToken)>

        

        <cfreturn stReturn>

    </cffunction>

    <!--- create Usage Charge --->

    <cffunction name="createUsageCharge" returntype="struct" output="false">
        <cfargument name="chargeID" type="numeric" required="true">
        <cfargument name="price" type="numeric" required="true">
        <cfargument name="description" type="string" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var sPayload = "">
        <cfset var stReturn = {}>
        <cfset var apiEndpoint="recurring_application_charges/#arguments.chargeID#/usage_charges.json">

		<cfsavecontent variable="sPayload"><cfoutput>
			{
			  "usage_charge": {
				"description": "#arguments.description#",
				"price": #arguments.price#
			  }
			}
		</cfoutput></cfsavecontent>

        <cfset stReturn = do_apiaction(endpoint = apiEndpoint, sBody=sPayload, method="post", shop=arguments.shop, accessToken = arguments.accessToken)>

        

        <cfreturn stReturn>
    </cffunction>

    <!---
        activates a reacurring charge - deprecated
    --->

    <cffunction name="activateSubscription" returntype="struct" output="false">
        <cfargument name="chargeID" type="string" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var sPayload = "">
        <cfset var stReturn = {}>
        <cfset var sEndpoint = "recurring_application_charges/#arguments.chargeID#/activate.json">

        <cfsavecontent variable="sPayload"><cfoutput>
            {
                "recurring_application_charge": {
                  "id": #arguments.chargeID#
                }
            }
        </cfoutput></cfsavecontent>

        <cfset stReturn = do_apiaction(endpoint = sEndpoint, sBody = sPayload, shop=arguments.shop, accessToken = arguments.accessToken)>

       

        <cfreturn stReturn>

    </cffunction>

    <!---
        Create a New Fulfillment for an order
        https://shopify.dev/docs/admin-api/rest/reference/shipping-and-fulfillment/fulfillment#create-2020-10
    --->

    <cffunction name="createFulfillment" access="public" returntype="struct" output="false">
        <cfargument name="orderId" type="numeric" required="true">
        <cfargument name="locationId" type="numeric" required="true">
        <cfargument name="trackingNumbers" type="array" required="true">
        <cfargument name="trackingUrls" type="array" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="trackingCompany" type="string" required="false" default="Other">
        <cfargument name="notifyCustomer" type="boolean" required="false" default="False">

        <cfset var sJson = "">
        <cfset var stResult = {}>
        <cfset var sEndpoint = "orders/#arguments.orderId#/fulfillments.json">


        <cfsavecontent variable="sJson"><cfoutput>
            {
                "fulfillment": {
                  "location_id": #arguments.locationId#,
                  "tracking_company": "#arguments.trackingCompany#",
                  "tracking_numbers": #serializeJson(arguments.trackingNumbers)#,
                  "tracking_urls": #serializeJson(arguments.trackingUrls)#,
                  "notify_customer": #arguments.notifyCustomer#
                }
              }
        </cfoutput></cfsavecontent>
        <cfset stResult = do_apiaction(endpoint = sEndpoint, sBody = sJson, method = "POST", shop=arguments.shop, accessToken = arguments.accessToken)>

        <cfreturn stResult>
    </cffunction>

    <!--- get fulfillments --->
    <cffunction name="getFulfillments" access="public" returntype="struct" output="false">
        <cfargument name="orderid" type="numeric" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfreturn do_apiaction(endpoint = "orders/#arguments.orderid#/fulfillments.json", shop = arguments.shop, accessToken = arguments.accessToken, method = "GET")>
    </cffunction>

    <!--- cancel fulfillment --->

    <cffunction name="cancelFulfillment" access="public" returntype="struct" output="false">
        <cfargument name="fulfillmentid" type="numeric" required="true">
        <cfargument name="orderid" type="numeric" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfreturn do_apiaction(endpoint = "orders/#arguments.orderid#/fulfillments/#arguments.fulfillmentid#/cancel.json", sBody="{}", shop = arguments.shop, accessToken = arguments.accessToken )>

    </cffunction>

    <!--- get Themes --->

    <cffunction name="getThemes" access="public" returntype="struct" output="false">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="role" type="string" required="false" default="">

        <cfset var endpoint = "themes.json">

        <cfif len(arguments.role)>
            <cfset endpoint &= "?role=" & arguments.role>
        </cfif>

        <cfreturn do_apiaction(endpoint = endpoint, shop = arguments.shop, accessToken = arguments.accessToken, method = "GET")>

    </cffunction>

    <!--- get theme --->

    <cffunction name="getTheme" access="public" returntype="struct" output="false">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="id" type="numeric" required="true" >

        <cfset var endpoint = "themes/#arguments.id#.json">

        <cfreturn do_apiaction(endpoint = endpoint, shop = arguments.shop, accessToken = arguments.accessToken, method = "GET")>

    </cffunction>

    <!--- adds the defined asset to the specified theme --->

    <cffunction name="putAsset" access="public" returntype="struct" output="false">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="themeId" type="numeric" required="true" >
        <cfargument name="type" type="string" required="true" hint="image/text">
        <cfargument name="key" type="string" required="true" hint="the path of where to save the asset in shopify e.g. templates/index.liquid">
        <cfargument name="source" type="string" required="true" hint="either plain text, base64encoded image, or a fully qualified URL to an image">
        <cfargument name="isBase64Encoded" type="boolean" required="false" default="false">

        <cfset var endpoint = "themes/#arguments.themeId#/assets.json">
        <cfset var stReturn = {}>
        <cfset var stJson =
            {
                "asset":{
                    "key" : arguments.key
                }
            }>
        <cfif arguments.type EQ "text">
            <cfset stJson.asset["value"] = arguments.source>
        <cfelseif arguments.type EQ "image" AND arguments.isBase64Encoded>
            <cfset stJson.asset["attachment"]= arguments.source>
        <cfelse>
            <cfset stJson.asset["src"] = arguments.source>
        </cfif>

        <cfset stReturn = do_apiaction(endpoint = endpoint, method = "PUT", sBody = serializeJson(stJson), shop = arguments.shop, accessToken = arguments.accessToken)>

      

        <cfreturn stReturn>

    </cffunction>

    <!---
        get Scoped metafields to the shop
    --->
    <cffunction name="getMetaFields" access="public" returntype="struct" output="false" hint="returns the metafields for the specified endpoint">
        <cfargument name="endpoint" type="string" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfreturn do_apiaction(endpoint = arguments.endpoint, method="GET", shop = arguments.shop, accessToken = arguments.accessToken)>

    </cffunction>

    <!--- set Metafields --->

    <cffunction name="setMetaFields" returntype="struct" output="false" access="public">
        <cfargument name="metafields" type="array" required="true" hint="Shopify metafield object array">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accesstoken" type="string" required="true">

        <cfset var sGQL = "">
        <cfset var stVars = {}>
        <cfset var stResult = {"ok":true}>
        <cfset var stReturn = {"ok":true}>
        <cfset var adj = {}>
        <cfset var idx = 0>


        <cfsavecontent variable="sGQL">
            mutation MetafieldsSet($metafields: [MetafieldsSetInput!]!) {
                metafieldsSet(metafields: $metafields) {
                  userErrors {
                    field
                    message
                    code
                  }
                }
              }
        </cfsavecontent>

        <cfloop from="1" to="#arraylen(arguments.metafields)#" step="25" index="idx">
            <cfset adj = {}>

            <cfif idx+25 LT arrayLen(arguments.metafields)>
                <cfset adj = arraySlice(arguments.metafields,idx,25)>
            <cfelse>
                <cfset adj = arraySlice(arguments.metafields,idx)>
            </cfif>

            <cfset stVars = {
                "metafields": adj
            }>

            <cfset stResult = graphQL(
                query = sGQL,
                queryvars = stVars,
                shop = arguments.shop,
                accesstoken = arguments.accessToken)>

            <cfif stResult.ok eq false>
                <cfset stReturn.ok = false>
                <cfset stReturn.result = stResult.result>
            </cfif>

        </cfloop>

        <cfreturn stReturn>
    </cffunction>

    <!---
	Create a webhook for s specific topic

	Example:
	POST /admin/webhooks.json
	{
	  "webhook": {
		"topic": "orders\/create",
		"address": "http:\/\/whatever.hostname.com\/",
		"format": "json"
	  }
	}

	Documentation:
	https://docs.shopify.com/api/webhook#create

	@param topic			string:		(Ex. 'App') 			-> https://docs.shopify.com/api/webhook#content
	@param action			string:		(Ex. 'uninstalled') 	-> https://docs.shopify.com/api/webhook#content
	@param hookURL			string:		URL the webhook should call
	--->
	<cffunction name="addWebhook" 			access="public"  output="false">
		<cfargument name="topic" 			required="true" type="string">
		<cfargument name="action" 			required="true" type="string">
        <cfargument name="hookURL" 			required="true" type="string">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var stReturn = {}>
		<cfset var stBody=
			{
				"webhook": {
					"topic": "#arguments.topic#/#arguments.action#",
					"address": "#arguments.hookURL#",
					"format": "json"
				}
			}>

        <cfset stReturn =  do_apiaction(endpoint = "webhooks.json", sBody = serializejson(stBody), method = "POST", shop=arguments.shop, accessToken = arguments.accessToken)>

       

        <cfreturn stReturn>
    </cffunction>

    <!--- get webhooks --->

    <cffunction name="getWebhooks" 	access="public"  output="false">

        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfreturn do_apiaction(endpoint = "webhooks.json", method = "GET", shop=arguments.shop, accessToken = arguments.accessToken)>

    </cffunction>

    <!--- create product --->

    <cffunction name="createProduct" returntype="struct" access="public" output="true">
        <cfargument name="product" type="struct" required="true" hint="a structure containing the product data that matches the format at https://shopify.dev/docs/admin-api/rest/reference/products/product?api[version]=2020-04##create-2020-04">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var stReturn = {}>


        <cfset stReturn  = do_apiaction(endpoint = "products.json",
        sBody = serializeJson(arguments.product),
        shop = arguments.shop,
        accessToken = arguments.accessToken)>

        <cfreturn stReturn>

    </cffunction>

    <!--- create variant --->

    <cffunction name="createVariant" returntype="struct" access="public" output="true">
        <cfargument name="productID" type="numeric" required="true" hint="the product id to add the variant to">
        <cfargument name="variant" type="struct" required="true" hint="a structure containing the product data that matches the format at https://shopify.dev/docs/admin-api/rest/reference/products/product?api[version]=2020-04##create-2020-04">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var stReturn = {}>


        <cfset stReturn  = do_apiaction(endpoint = "products/#arguments.productid#/variants.json",
            sBody = serializeJson(arguments.variant),
            shop = arguments.shop,
            accessToken = arguments.accessToken)>

        <cfreturn stReturn>

    </cffunction>

    <!--- find product by sku --->
    <cffunction name="findProductBySKU" returntype="struct" access="public" output="false">
        <cfargument name="sku" type="string" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var stResult = {}>
        <cfset var stReturn = {}>
        <cfset var graphQLRequest = "">
        <cfsavecontent variable="graphQLRequest">
            {
                productVariants(first: 1, query: "sku:<cfoutput>#arguments.sku#</cfoutput>") {
                    edges {
                      node {
                        id,
                        inventoryItem{
                            id
                        }
                        product {
                          id
                        }
                      }
                    }
                  }
            }
        </cfsavecontent>
        <cfset stResult = do_apiaction(endpoint = 'graphql.json', sBody = serializeJson({"query":graphQLRequest}),shop=arguments.shop,accessToken=arguments.accessToken)>
        <cfif stResult.ok AND ArrayLen(stResult.result.data.productVariants.edges)>
            <cfset stReturn["variant_id"] = listLast(stResult.result.data.productVariants.edges[1].node.id,"/")>
            <cfset stReturn["product_id"] = listLast(stResult.result.data.productVariants.edges[1].node.product.id,"/")>
            <cfset stReturn["inventory_item_id"] = listLast(stResult.result.data.productVariants.edges[1].node.inventoryItem.id,"/")>
        </cfif>
        <cfreturn stReturn>
    </cffunction>


    <cffunction name="updateProduct" returntype="struct" access="public" output="false">
        <cfargument name="product" type="struct" required="true" hint="shopify specific product data">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var stReturn = {ok:false}>
        <cfif NOT structIsEmpty(arguments.product)>
            <cfset stReturn = do_apiaction(endpoint = "products/#arguments.product.product.ID#.json",
                sBody = serializeJson(arguments.product),
                method = "PUT",
                shop = arguments.shop,
                accessToken = arguments.accessToken)>
            <cfreturn stReturn>
        </cfif>

        <cfreturn stReturn>
    </cffunction>


    <cffunction name="updateVariant" returntype="struct" access="public" output="false">
        <cfargument name="variant" type="struct" required="true" hint="shopify specific variant data">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var stReturn = {ok:false}>
        <cfif NOT structIsEmpty(arguments.variant)>
            <cfset stReturn = do_apiaction(endpoint = "variants/#arguments.variant.variant.ID#.json",
                sBody = serializeJson(arguments.variant),
                method = "PUT",
                shop = arguments.shop,
                accessToken = arguments.accessToken)>

           

            <cfreturn stReturn>
        </cfif>

        <cfreturn stReturn>
    </cffunction>



    <cffunction name="getProductVariantsByLocation" returntype="struct" access="public" output="false">
        <cfargument name="locationid" type="string" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="cursor" type="string" required="false" default="">
        <cfargument name="direction" type="string" required="false" default="next">
        <cfargument name="limit" type="numeric" required="false" default="50">

        <cfset var gqlRequest = "">
        <cfset var gqlVariables = "">
        <cfset var stGQL = {}>
        <cfset var stVariant = {}>
        <cfset var stEdge = {}>
        <cfset var products = []>
        <cfset var stProducts = {}>
        <cfset var previouscursor = "">
        <cfset var productId = "">
        <cfset var stResult = {}>
        <cfset var i = 0>
        <cfset var stReturn = {"ok":true, "result":{}}>

        <!--- limit max is 50 --->
        <cfif arguments.limit GT 50>
            <cfset arguments.limit = 50>
        </cfif>

        <cfsavecontent variable="gqlRequest">
            query InventoryItems($first: Int, $last: Int, $before: String, $after: String, $sortKey: ProductVariantSortKeys, $reverse: Boolean, $query: String, $savedSearchId: ID, $locationId: ID!, $isMultiLocation: Boolean!) {
                productVariants(first: $first, after: $after, last: $last, before: $before, sortKey: $sortKey, reverse: $reverse, query: $query, savedSearchId: $savedSearchId) {
                edges {
                    cursor
                    node {
                    id
                    displayName
                    title
                    sku
                    barcode
                    weight
                    weightUnit
                    price
                    selectedOptions{
                        name
                        value
                      }
                    inventoryItem {
                        id
                        sku
                        inventoryLevel(locationId: $locationId) @include(if: $isMultiLocation) {
                        ...InventoryItemsLevel
                        __typename
                        }
                    }
                    product {
                        id
                        hasOnlyDefaultVariant
                        title
                        vendor
                        productType
                        publishedAt
                        __typename
                    }
                    __typename
                    }
                    __typename
                }
                pageInfo {
                    hasNextPage
                    hasPreviousPage
                    __typename
                }
                __typename
                }
            }

            fragment InventoryItemsLevel on InventoryLevel {
                id
                available
                incoming
                __typename
            }
            </cfsavecontent>

        <cfset gqlVariables ={
            "query": "location_id:#arguments.locationid# managed:'true'",
            "isMultiLocation": true,
            "locationId": "gid://shopify/Location/#arguments.locationid#",
            "sortKey": "ID",
            "reverse": false,
            "first": arguments.limit
            }>
        <!--- if a cursor is supplied --->
        <cfif len(arguments.cursor)>
            <cfif arguments.direction eq "next">
                <cfset gqlVariables["after"] = arguments.cursor>
            <cfelse>
                <cfset gqlVariables["before"] = arguments.cursor>
            </cfif>
        </cfif>

        <cfset stGQL["query"] = gqlRequest>
        <cfset stGQL["variables"] = gqlVariables>

        <cfset stResult = do_apiaction(endpoint = 'graphql.json', sBody = serializeJson(stGQL),shop=arguments.shop,accessToken=arguments.accessToken)>

        <cfif stResult.ok>
            <cfloop array="#stResult.result.data.productVariants.edges#" index="stEdge">
                <cfif len(previouscursor) EQ 0>
                    <cfset previouscursor = stEdge.cursor>
                </cfif>
                <cfset productId = listLast(stEdge.node.product.id,"/")>
                <cfif NOT structKeyExists(stProducts, productId)>
                    <cfset stProducts[productId] = {
                        "id" : productId,
                        "vendor": stEdge.node.product.vendor,
                        "product_type" : stEdge.node.product.producttype,
                        "published_at" : "",
                        "title" : stEdge.node.product.title,
                        "variants":[]
                    }>
                    <cfif NOT isNull(stEdge.node.product.publishedat)>
                        <cfset stProducts[productId]["publishedat"] = stEdge.node.product.publishedat>
                    </cfif>
                    <cfset arrayAppend(products,stProducts[productId])>
                </cfif>
                <!--- only add the variant if it has a defined sku --->
                <cfif NOT isnull(stEdge.node.sku)>
                    <cfset stVariant = {
                        "id" : listLast(stEdge.node.id,"/"),
                        "title": stEdge.node.title,
                        "sku": stEdge.node.sku,
                        "barcode": isnull(stEdge.node.barcode)?"":stEdge.node.barcode,
                        "weight": stEdge.node.weight,
                        "weight_unit":stEdge.node.weightUnit,
                        "price": stEdge.node.price,
                        "inventory_item_id": listlast(stEdge.node.inventoryItem.id,"/")
                    }>
                    <cfloop from="1" to="#arrayLen(stEdge.node.selectedOptions)#" index="i">
                        <cfset stVariant["option#i#"] = stEdge.node.selectedOptions[i].value>
                    </cfloop>
                    <cfset arrayAppend(stProducts[productId].variants,stVariant)>
                </cfif>
            </cfloop>

            <cfset stReturn.result["products"] = products>
            <cfif stResult.result.data.productVariants.pageInfo.hasNextPage OR stResult.result.data.productVariants.pageInfo.hasPreviousPage>
                <cfset stReturn.result["pagination"] = {
                    "hasNext" = stResult.result.data.productVariants.pageInfo.hasNextPage,
                    "hasPrevious" = stResult.result.data.productVariants.pageInfo.hasPreviousPage,
                }>
                <cfif stResult.result.data.productVariants.pageInfo.hasNextPage>
                    <cfset stReturn.result["pagination"]["nextcursor"] = stEdge.cursor>
                </cfif>
                <cfif stResult.result.data.productVariants.pageInfo.hasPreviousPage>
                    <cfset stReturn.result["pagination"]["previouscursor"] = previouscursor>
                </cfif>
            </cfif>
        <cfelse>
            <cfset stReturn = stResult>
        </cfif>
        <cfreturn stReturn>
    </cffunction>

    <!--- calculate refund --->

    <cffunction name="calculateRefund" returntype="struct" access="public" output="false">
        <cfargument name="orderId" type="numeric" required="true">
        <cfargument name="itemsToReturn" type="array" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="fullrefund" type="boolean" required="false" default="false">

        <cfset var stReturn = {"ok": false, result={}}>
        <cfset var sEndpoint = "orders/#arguments.orderid#/refunds/calculate.json">
        <cfset var x = 0>
        <cfset var numItemsToReturn = arrayLen(arguments.itemsToReturn)>
        <cfset var sJson = "">

        <cfsavecontent variable="sJson"><cfoutput>
            {
                "refund": {
                  "shipping": {
                    "full_refund": #arguments.fullrefund#
                  },
                  "refund_line_items": [<cfloop from="1" to="#numItemsToReturn#" index="x">
                    #serializeJson(arguments.itemsToReturn[x])#
                    <cfif x LT numItemsToReturn>,</cfif>
                    </cfloop>
                  ]
                }
              }
        </cfoutput>
        </cfsavecontent>

        <cfset stReturn = do_apiaction(endpoint = sEndpoint,
                sBody = sJson,
                method = "POST",
                shop = arguments.shop,
                accessToken = arguments.accessToken)>

        <cfreturn stReturn>
    </cffunction>

    <!--- refund --->

    <cffunction name="refund" returntype="struct" access="public" output="false">
        <cfargument name="sRefund" type="string" required="true" hint="shopify refund structure">
        <cfargument name="orderid" type="numeric" required="true" hint="shopify order id">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var stReturn = do_apiaction(endpoint = 'orders/#arguments.orderid#/refunds.json',
                sBody = sRefund,
                method = "POST",
                shop = arguments.shop,
                accessToken = arguments.accessToken)>

        <cfreturn stReturn>
    </cffunction>

    <!--- cancel order --->

    <cffunction name="cancelOrder" returntype="struct" access="public" output="false">
        <cfargument name="orderid" type="numeric" required="true" hint="shopify order id">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var stReturn = do_apiaction(endpoint = 'orders/#arguments.orderid#/cancel.json',
                method = "POST",
                sBody = "{}",
                shop = arguments.shop,
                accessToken = arguments.accessToken)>
        <cfreturn stReturn>
    </cffunction>

    <!--- update inventory --->

    <cffunction name="updateInventory" returntype="struct" access="public" output="false">
        <cfargument name="inventoryItemID" type="numeric" required="true">
        <cfargument name="locationID" type="numeric" required="true">
        <cfargument name="quantity" type="numeric" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var sJson = "">
        <cfset var stReturn = {}>

        <cfsavecontent variable="sJson"><cfoutput>
            {
                "location_id": #arguments.locationid#,
                "inventory_item_id": #arguments.inventoryItemId#,
                "available": #arguments.quantity#
            }</cfoutput>
        </cfsavecontent>

        <cfset stReturn = do_apiaction(endpoint = 'inventory_levels/set.json',
                sBody = sJson,
                method = "POST",
                shop = arguments.shop,
                accessToken = arguments.accessToken)>
        <cfreturn stReturn>
    </cffunction>

    <cffunction name="bulkUpdateInventory" returntype="struct" access="public" output="false">
        <cfargument name="inventories" type="array" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var sJson = "">
        <cfset var stVars = {}>
        <cfset var stReturn = {}>

        <cfsavecontent variable="sJson">
        mutation inventorySetOnHandQuantities($input: InventorySetOnHandQuantitiesInput!) {
            inventorySetOnHandQuantities(input: $input) {
              userErrors {
                field
                message
              }
            }
          }
        </cfsavecontent>

        <cfset stVars =
            {
                "input": {
                  "reason": "cycle_count_available",
                  "setQuantities": arguments.inventories
                }
            }>

        <cfset stReturn = graphQL(query=sJson,
                queryvars=stVars,
                shop = arguments.shop,
                accessToken = arguments.accessToken)>
        <cfreturn stReturn>
    </cffunction>


    <cffunction name="adjustInventory" returntype="struct" access="public" output="false">
        <cfargument name="inventoryItemID" type="numeric" required="true">
        <cfargument name="locationID" type="numeric" required="true">
        <cfargument name="adjustment" type="numeric" required="true" hint="postive value increases, negative decreases ">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var sJson = "">
        <cfset var stReturn = {}>

        <cfsavecontent variable="sJson"><cfoutput>
            {
                "location_id": #arguments.locationid#,
                "inventory_item_id": #arguments.inventoryItemId#,
                "available_adjustment": #arguments.adjustment#
            }</cfoutput>
        </cfsavecontent>

        <cfset stReturn = do_apiaction(endpoint = 'inventory_levels/adjust.json',
                sBody = sJson,
                method = "POST",
                shop = arguments.shop,
                accessToken = arguments.accessToken)>
        <cfreturn stReturn>
    </cffunction>

    <!--- get shipping zones --->

    <cffunction name="getShippingZones" returntype="struct" access="public" output="false">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">


        <cfreturn do_apiaction(endpoint = 'shipping_zones.json',
            method = "GET",
            shop = arguments.shop,
            accessToken = arguments.accessToken)>

    </cffunction>


    <!---
    update order
    --->

    <cffunction name="updateOrder" returntype="struct" access="public" output="false">
        <cfargument name="id" type="numeric" required="true" hint="the order id - should also be contained in the order parameter">
        <cfargument name="order" type="struct" required="true" hint="a valid structure to pass to shopify containing the bits of the order to update">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">


        <cfreturn do_apiaction("orders/#arguments.ID#.json",arguments.shop, arguments.accessToken, serializeJson(arguments.order),"PUT")>
    </cffunction>


    <!---
        create gift card
    --->
    <cffunction name="createGiftCard" returntype="struct" access="public" output="false">
        <cfargument name="payload" type="struct" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfreturn do_apiaction("gift_cards.json", arguments.shop, arguments.accessToken, serializeJson(arguments.payload),"POST")>
    </cffunction>


    <cffunction name="graphQL" returntype="struct" access="public" output="false">
        <cfargument name="query" type="string" required="true">
        <cfargument name="queryvars" type="struct" required="false" default="#{}#">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">


        <cfset var stGQL = {}>

        <cfset stGQL["query"] = arguments.query>
        <cfif structKeyExists(arguments,"queryvars") AND NOT structIsEmpty(arguments.queryvars)>
            <cfset stGQL["variables"] = arguments.queryvars>
        </cfif>

        <cfreturn do_apiaction(endpoint = 'graphql.json', sBody = serializeJson(stGQL), shop = arguments.shop, accessToken = arguments.accessToken)>


    </cffunction>

    <!---
    add tags via graphql
    --->

    <cffunction name="addTags" returntype="struct" access="public" output="false">
        <cfargument name="id" type="string" required="true" hint="shopify GID formatted id">
        <cfargument name="tags" type="string" required="true" hint="comma list">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var gqlRequest = "">
        <cfset var gqlVariables = {}>
        <cfset var stGQL = {}>


        <cfsavecontent variable="gqlRequest">
            mutation addTags($id: ID!, $tags: [String!]!) {
                tagsAdd(id: $id, tags: $tags) {
                    node {id}
                    userErrors { message }
                }
            }
        </cfsavecontent>

        <cfset gqlVariables = {
            "id": arguments.id,
            "tags": arguments.tags,
        }>

        <cfset stGQL["query"] = gqlRequest>
        <cfset stGQL["variables"] = gqlVariables>

        <cfreturn do_apiaction(endpoint = 'graphql.json', sBody = serializeJson(stGQL), method="POST",shop = arguments.shop, accessToken = arguments.accessToken)>


    </cffunction>


    <!---
    add tags via graphql
    --->

    <cffunction name="removeTags" returntype="struct" access="public" output="false">
        <cfargument name="id" type="string" required="true" hint="shopify GID formatted id">
        <cfargument name="tags" type="string" required="true" hint="array">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">

        <cfset var gqlRequest = "">
        <cfset var gqlVariables = {}>
        <cfset var stGQL = {}>

        <cfsavecontent variable="gqlRequest">
                mutation removeTags($id: ID!, $tags: [String!]!) {
                    tagsRemove(id: $id, tags: $tags) {
                        node {id}
                        userErrors {message}
                    }
                }
        </cfsavecontent>
        <cfset gqlVariables ={
            "id": arguments.id,
            "tags": listTOArray(arguments.tags),
            }>

        <cfset stGQL["query"] = gqlRequest>
        <cfset stGQL["variables"] = gqlVariables>

        <cfreturn do_apiaction(endpoint = 'graphql.json', sBody = serializeJson(stGQL), method="POST",shop = arguments.shop, accessToken = arguments.accessToken)>


    </cffunction>

    <cffunction name="getSmartCollections" returntype="struct" access="public" output="false">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="limit" required="false" type="numeric" default="50">
        <cfargument name="page_info" required="false" type="string" default="">
        <cfargument name="fields" required="false" type="string" default="">


        <cfset var apiEndpoint = "smart_collections.json?limit=#arguments.limit#">
        <cfset var stResult = {}>

        <cfif len(arguments.fields)>
            <cfset apiEndpoint &= "&fields=" & arguments.fields>
        </cfif>
        <cfif len(page_info)>
            <cfset apiEndpoint &= "&#arguments.page_info#">
        </cfif>

        <cfreturn do_apiaction(endpoint = apiEndpoint, method="get", shop = arguments.shop, accessToken = arguments.accessToken)>
    </cffunction>


    <cffunction name="createSmartCollection" returntype="struct" access="public" output="false">
        <cfargument name="title" type="string" required="true">
        <cfargument name="column" type="string" required="true">
        <cfargument name="condition" type="string" required="true">
        <cfargument name="relation" type="string" required="false" default="equals">
        <cfargument name="image" type="string" required="false" default="">
        <cfargument name="rules" type="array" required="false" default="#[]#">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">


        <cfset var collection = {
            "smart_collection": {
              "title": "#arguments.title#",
              "rules": [
                {
                  "column": "#arguments.column#",
                  "relation": "#arguments.relation#",
                  "condition": "#arguments.condition#"
                }
              ]
            }
        }>
        <cfif len(image)>
            <cfset collection["smart_collection"]["image"]={
                "src": arguments.image
            }>
        </cfif>
        <cfif arraylen(arguments.rules)>
            <cfset ["smart_collection"]["rules"] = arguments.rules>
        </cfif>

        <cfreturn do_apiaction(endpoint = 'smart_collections.json', sBody = serializeJson(collection), method="POST",shop = arguments.shop, accessToken = arguments.accessToken)>


    </cffunction>

    <cffunction name="updateSmartCollection" returntype="struct" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfargument name="title" type="string" required="true">
        <cfargument name="column" type="string" required="true">
        <cfargument name="condition" type="string" required="true">
        <cfargument name="relation" type="string" required="false" default="equals">
        <cfargument name="image" type="string" required="false" default="">
        <cfargument name="ruels" type="array" required="false" default="#[]#">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">


        <cfset var collection = {
            "smart_collection": {
              "id": arguments.id,
              "title": "#arguments.title#",
              "rules": [
                {
                  "column": "#arguments.column#",
                  "relation": "#arguments.relation#",
                  "condition": "#arguments.condition#"
                }
              ]
            }
        }>

        <cfif len(image)>
            <cfset collection["smart_collection"]["image"]={
                "src":arguments.image
            }>
        </cfif>

        <cfif arraylen(arguments.rules)>
            <cfset collection["rules"] = arguments.rules>
        </cfif>

        <cfreturn do_apiaction(endpoint = 'smart_collections/#arguments.id#.json', sBody = serializeJson(collection), method="PUT",shop = arguments.shop, accessToken = arguments.accessToken)>


    </cffunction>

    <!--- ******************
        PRIVATE FUNCTIONS
    ********************* --->

    <cffunction name="do_apiaction" returntype="struct" access="public" output="false">
        <cfargument name="endpoint" type="string" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accessToken" type="string" required="true">
        <cfargument name="sBody" type="string" required="false">
        <cfargument name="method" type="string" required="false" default="POST">

        <cfset var stResult = {ok:true,result:{},pagination:{}}>
        <cfset var httpResult = {}>
        <cfset var stArgs = duplicate(arguments)>


        <cftry>
            <cfhttp url='https://#arguments.shop#/admin/api/#application.shopify.apiversion#/#arguments.endpoint#'
                method="#arguments.method#" charset="utf-8"  result="httpResult" >
                <cfhttpparam name="Content-Type" value="application/json" type="header">
                <cfhttpparam name="X-Shopify-Access-Token" value="#arguments.AccessToken#" type="header">
                <cfif listFindNoCase("POST,PUT",arguments.method)>
                    <cfif len(arguments.sBody)>
                    <cfhttpparam name="body" value="#arguments.sBody#" type="body">
                    </cfif>
                </cfif>
            </cfhttp>

            <cfif httpResult.status_code EQ 408 OR httpResult.status_code EQ 503 or httpresult.status_code eq 502>
            <!--- timeout error retry --->
                    <cfif NOT structKeyExists(stArgs,"retrycount")>
                        <cfset stArgs["retrycount"] = 0>
                    </cfif>
                    <cfset stArgs["retryCount"] += 1>
                <cfset simpleLog(stLogData = {"message":"#httpresult.status_code# response from Shopify - Retrying","arguments": stArgs, "merchant": arguments.shop, }, filename = "shopify", sendNotification = false)>
                <cfset sleep(1000)>
                <cfif stArgs.retrycount LT 10>
                    <cfreturn do_apiaction(argumentCollection = stArgs)>
                </cfif>
            <cfelseif httpResult.status_code EQ 429 AND StructKeyExists(httpResult.responseHeader,"retry-after")>
                <!--- too many requests --->
                <cfset sleep(1000 * httpResult.responseHeader.retry-after)>
                <cfreturn do_apiaction(argumentCollection = stArgs)>
            </cfif>

            <cfif structKeyExists(httpResult.responseHeader,"link")>
                <cfset stResult.pagination = extractPagination(httpResult.responseHeader.link)>
            </cfif>
            <cfif left(httpResult.status_code,1) GT 3>
                <cfset stResult.ok = false>
                <cfset simpleLog(stLogData = {arguments: arguments, response:httpResult, merchant: arguments.shop}, filename = "shopify", sendNotification = false)>
            </cfif>

            <cfif structKeyExists(httpResult,"filecontent")>
                <cftry>
                    <cfset stResult.result = DeserializeJSON(httpResult.filecontent)>
                <cfcatch>
                    <cfset stResult.result = httpResult.filecontent>
                </cfcatch>
                </cftry>
            </cfif>

            <cfcatch>
                <cfdump var="#cfcatch#" label="label">
                <cfabort>
                <cfset simpleLog(stLogData = {arguments: arguments, response:httpResult, merchant: arguments.shop, catch: cfCatch}, filename = "shopify", sendNotification = true)>
                <cfset stResult = {ok:false, error: 'an unhandled shopify error occured'}>
            </cfcatch>
        </cftry>
        <cfreturn stResult>
    </cffunction>


    <cffunction name="extractPagination" returntype="struct" access="private" output="false">
        <cfargument name="sPag" type="string" required="true">

        <cfset var pagLen = listLen(arguments.sPag)>
        <cfset var sTemp = "">
        <cfset var sPageInfo1 = "">
        <cfset var sPageInfo2 = "">
        <cfset var stReturn = {}>

        <cfset sTemp = listLast(listfirst(listFirst(arguments.sPag,","),";"),"&")>
        <cfset sPageInfo1 = left(sTemp,len(sTemp)-1)>
        <cfif pagLen EQ 1>
            <cfif findNoCase('rel="previous"',arguments.sPag)>
                <cfset stReturn["previous"] = sPageInfo1>
            <cfelse>
                <cfset stReturn["next"] = sPageInfo1>
            </cfif>
        <cfelse>
            <cfset stReturn["previous"] = sPageInfo1>
            <cfset sTemp = listLast(listfirst(listLast(arguments.sPag,","),";"),"&")>
            <cfset sPageInfo2 = left(sTemp,len(sTemp)-1)>
            <cfset stReturn["next"] = sPageInfo2>
        </cfif>

        <cfreturn stReturn>
    </cffunction>

</cfcomponent>