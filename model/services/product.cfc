<cfcomponent output="false" accessors="true" extends="base">

  
    <cfproperty name="shopifyService">

    
    <cffunction name="init" output="false" returntype="any">
        <cfargument name="fw" type="any" required="true">


        <cfset variables.fw = arguments.fw>
        
        <cfreturn this>
    </cffunction>

    <cffunction name='get' returntype="struct" output="false">
        <cfargument name="id" type="numeric" required="true">

        <cfset var qProduct = queryNew("dummy")>

        <cfquery name="qProduct" datasource="#application.datasource#">
            select id from products where id = <cfqueryparam cfsqltype="numeric" value="#arguments.id#">
        </cfquery>
        <cfif qProduct.recordcount>
            <cfreturn {"ok":true,"product":{"id": qProduct.id}}>
        </cfif>
       
        <cfreturn {"ok":false,"product":{}}>

    </cffunction>

    <cffunction name="new" returntype="struct" output="false">
        <cfargument name="product" type="struct" required="true">


        <cfset var stResult = {}>
        <cfset var formatted = formatProduct(arguments.product)>

        <cfif len(arguments.product.parent_id) eq 0 or arguments.product.parent_id eq arguments.product.sap_id>
            <!--- stand alone product  --->
            <cfset stResult = upsertProduct(arguments.product,formatted)>
        <cfelse>
            <cfset stResult = upsertVariant(arguments.product,formatted)>
        </cfif>
       
      <cfreturn stResult>
    </cffunction>


    <cffunction name="update" returntype="struct" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfargument name="product" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var formatted = {}>
        <cfset var qProduct = getProduct(arguments.id)>

        <cfif qProduct.recordcount>

            <cfset formatted = formatProduct(arguments.product)>
            <cfif len(arguments.product.parent_id) eq 0 or arguments.product.parent_id eq arguments.product.sap_id>
                <cfset stResult = updateProduct(arguments.product,formatted, qProduct)>
            <cfelse>
                <cfset stResult = updateVariant(arguments.product,formatted, qProduct)>
            </cfif>

        <cfelse>
            <cfset stResult = {
                "ok":false,
                "error": "not found",
                "error_code": 404
            }>
        </cfif>

      <cfreturn stResult>
    </cffunction>

    <cffunction name="updateInventory" access="public" returntype="struct" output="false">
        <cfargument name="id" type="numeric" required="true" hint="sap product id">
        <cfargument name="product" type="struct" required="true">

        <cfset var stResult = {}>
        <cfset var qProduct = getProduct(arguments.id)>
        <cfset var stockAdjustments = []>

        <cfif qProduct.recordcount>

            <cfset arrayAppend(stockAdjustments,{
                "inventoryItemId": "gid://shopify/InventoryItem/#qProduct.inventory_item_id#",
                "locationId": "gid://shopify/Location/#application.claro.location_id#",
                "quantity": floor(arguments.product.inventory_quantity)
            })>
        
            <cfset var stbulkInventory =  variables.shopifyservice.bulkUpdateInventory(
                inventories = stockAdjustments,
                shop = application.shopify.shop,
                accessToken = application.shopify.accessToken)>
            <cfif stbulkInventory.ok>
                <cfset stResult = {
                    "ok":true,
                }>
            <cfelse>
                <cfset stResult = {
                    "ok":false,
                    "error": stResult.result
                }>
            </cfif>
        <cfelse>
            <cfset stResult = {
                "ok":false,
                "error": "not found",
                "error_code": 404
            }>
        </cfif>

        <cfreturn stResult>
    </cffunction>


    <cffunction name="validateProduct" access="public" returntype="boolean" output="false">
        <cfargument name="product" type="struct" required="true">

        <cfset var requiredFields = ["title","price","parent_id","parent_name","description","product_type","category","vendor","sap_id","size"]>
        <cfset var fields = structKeyArray(arguments.product)>

        <cfset requiredfields.removeAll(fields)>

        <cfreturn arraylen(requiredFields) eq 0>
        
    </cffunction>
    
<!--- private functions --->
    <cffunction name="upsertProduct" access="private" returntype="struct" output="false">
        <cfargument name="product" type="struct" required="true">
        <cfargument name="formatted" type="struct" required="true">

        <cfset var qProduct = getProduct(arguments.product.sap_id)>
        <cfset var stReturn = {"ok":false,"product":""}>
        <cfset var stResult = {}>

        <cfset var updated = false>


        <cfif qProduct.recordcount>
            <!--- update the product --->
            <cfset stReturn = updateProduct(arguments.product,arguments.formatted,qProduct)>
        <cfelse>
            <!--- insert the product --->
            <cfset stResult = variables.shopifyService.createProduct(
                product = arguments.formatted,
                shop = application.shopify.shop,
                accesstoken = APPLICATION.shopify.AccessToken)>
            <!--- update the inventory --->
            
            <cfset arrayAppend(stockAdjustments,{
                "inventoryItemId": "gid://shopify/InventoryItem/#stResult.result.product.variants[1].inventory_item_id#",
                "locationId": "gid://shopify/Location/#application.claro.location_id#",
                "quantity": floor(arguments.product.inventory_quantity)
            })>
        
            <cfset var stbulkInventory =  variables.shopifyservice.bulkUpdateInventory(
                inventories = stockAdjustments,
                shop = application.shopify.shop,
                accessToken = application.shopify.accessToken)>

            <cfset updated = saveProduct(
                stProduct = stResult.result.product,
                sap_id = arguments.product.sap_id)>

                <cfif updated>
                    <cfset stReturn.ok = true>
                    <cfset stReturn.product = {"id":arguments.product.sap_id}>
                </cfif>
        
        </cfif>
       <cfreturn stReturn>
    </cffunction>


    <cffunction name="upsertVariant" access="private" returntype="struct" output="false">
        <cfargument name="product" type="struct" required="true">
        <cfargument name="formatted" type="struct" required="true">

        <cfset var qProduct = getProduct(arguments.product.sap_id)>
        <cfset var stReturn = {"ok":false,"product":""}>
        <cfset var stResult = {}>

        <cfset var updated = false>


        <cfif qProduct.recordcount>
            <!--- update the product --->
            <cfset stReturn = updateVariant(
                product = arguments.product,
                formatted = arguments.formatted,
                qProduct = qProduct)>
        <cfelse>
            <!--- insert the product --->
            <cfset stResult = variables.shopifyService.createVariant(
                productID = qProduct.product_id,
                product = arguments.formatted,
                shop = application.shopify.shop,
                accesstoken = APPLICATION.shopify.AccessToken)>
            <!--- update the inventory --->
            
            <cfset arrayAppend(stockAdjustments,{
                "inventoryItemId": "gid://shopify/InventoryItem/#stResult.result.variants.inventory_item_id#",
                "locationId": "gid://shopify/Location/#application.claro.location_id#",
                "quantity": floor(arguments.product.inventory_quantity)
            })>
        
            <cfset var stbulkInventory =  variables.shopifyservice.bulkUpdateInventory(
                inventories = stockAdjustments,
                shop = application.shopify.shop,
                accessToken = application.shopify.accessToken)>

            <cfset updated = saveVariant(
                stProduct = stResult.result.variant,
                sap_id = arguments.product.sap_id)>

            <cfif updated>
                <cfset stReturn.ok = true>
                <cfset stReturn.product = {"id":arguments.product.sap_id}>
            </cfif>
        
        </cfif>
       <cfreturn stReturn>
    </cffunction>


    <cffunction name="formatProduct" access="private" returntype="struct" output="false">
        <cfargument name="product" type="struct" required="true">
        
        <cfset var price = "">
        <cfset var stMeta = {}>
        <cfset var compare_at_price = 0>
        <cfset var productTitle = arguments.product.title>

        <cfif structkeyExists(arguments.product,"sale_price") AND len(arguments.product.sale_price)>
            <cfset price = arguments.product.sale_price>
            <cfset compare_at_price = arguments.product.price>
        <cfelse>
            <cfset price = arguments.product.price>
            <cfset compare_at_price = 0>
        </cfif>
        
        <cfif len(arguments.product.parent_id)>
            <cfset productTitle = argument.product.parent_name>
        </cfif>
        <cfif len(arguments.product.parent_id) eq 0 or arguments.product.parent_id eq arguments.product.sap_id>
            <!--- stand alone product  --->
            <cfset var stTempProd = [
                "product":[
                    "title":  productTitle,
                    "body_html" : arguments.product.description,
                    "product_type" : arguments.product.product_type,
                    "status" : "active",
                    "tags" : arguments.product.category,
                    "vendor": arguments.product.vendor,
                    "variants":[
                        [
                            "sku": arguments.product.sap_id,
                            "price": price,
                            "compare_at_price": compare_at_price,
                            "inventory_management": "shopify",
                            "inventory_policy": "deny"
                        ]
                    ],
                    "images": [],
                    "metafields":[]
                ]
            ]>
            <!--- images --->

            <!--- metafields --->
            <cfif structKeyExists(arguments.product,"metafields")>
                <cfloop array="#arguments.product.metafields#" item="stMeta">
                    <cfset arrayAppend(stTempProd.product.metafields,
                        {
                            "key": "#stMeta.key#",
                            "namespace":"properties",
                            "type": "single_line_text_field",
                            "value": stMeta.value}
                        )> 
                </cfloop>
            </cfif>

        <cfelse>
            <!--- is a child product --->
            <cfset stTempProd = {
                "variant":[
                    "option1": arguments.product.size,
                    "sku": arguments.product.sap_id,
                    "price": price,
                    "compare_at_price": compare_at_price,
                    "inventory_management": "shopify",
                    "inventory_policy": "deny"]
            }>
        </cfif>

        
        <cfreturn stTempProd>
    </cffunction>

    <cffunction name="updateProduct" access="private" returntype="struct" output="false">
        <cfargument name="product" type="struct" required="true" hint="raw product from sap webhook">
        <cfargument name="formatted" type="struct" required="true" hint="product formated for shopify">
        <cfargument name="qProduct" type="query" required="true" hint="database entry of product">

        <cfset var stReturn = {"ok":false,"product":""}>
        <cfset var stMeta = {}>
        <cfset var stResult = {}>
        <cfset var stMetaResult = {}>
        <cfset var stMetaFields = {}>
        <cfset var sourceImages = []>
        <cfset var updated = false>

        <cfset arguments.formatted.product["id"] = qProduct.product_id>
        <cfset arguments.formatted.product.variants[1]["id"] = qProduct.variant_id>
        
        <cfset stMetafields = arguments.formatted.product.metafields>
        <cfloop array="#stMetafields#" item="stMeta">
            <cfset stMeta["ownerId"] = "gid://shopify/Product/#qProduct.product_id#">
        </cfloop>
        
        <cfset sourceimages = arguments.formatted.product.images>
        <cfset structDelete(arguments.formatted.product,"metafields")>
        <cfset structDelete(arguments.formatted.product,"images")>

        <cfset stResult = variables.shopifyService.updateProduct(
            product = arguments.formatted,
            shop = application.shopify.shop,
            accesstoken = APPLICATION.shopify.AccessToken)>

        <cfif stResult.ok>
            <cfset stMetaResult = updateMeta(
                metafields = stMetafields,
                shop = application.shopify.shop,
                accessToken = application.shopify.accesstoken
                )>
            <cfset shopifyService.updateInventory(
                inventoryItemId = qProduct.inventory_item_id,
                locationID = application.claro.location_ID,
                quantity = arguments.product.inventory_quantity,
                shop = application.shopify.shop,
                accessToken = application.shopify.accessToken
            )>

            <cfset updated = saveProduct(
                stProduct = stResult.result.product,
                sap_id = arguments.product.sap_id)>

            <cfif updated>
                <cfset stReturn.ok = true>
                <cfset stReturn.product = {"id":arguments.product.sap_id}>
            </cfif>
        <cfelse>
            <cfset stReturn.result = stResult.result>
        
        </cfif>
        <cfreturn stReturn>
    </cffunction>


    <cffunction name="updateVariant" access="private" returntype="struct" output="false">
        <cfargument name="product" type="struct" required="true" hint="raw product from sap webhook">
        <cfargument name="formatted" type="struct" required="true" hint="product formated for shopify">
        <cfargument name="qProduct" type="query" required="true" hint="database entry of product">

        <cfset var stReturn = {"ok":false,"product":""}>
        <cfset var stResult = {}>
        <cfset var updated = false>

        <cfset arguments.formatted.variant["id"] = qProduct.variant_id>

        <cfset stResult = variables.shopifyService.updateVariant(
            variant = arguments.formatted,
            shop = application.shopify.shop,
            accesstoken = APPLICATION.shopify.AccessToken)>

        <cfif stResult.ok>
            
            <cfset shopifyService.updateInventory(
                inventoryItemId = qProduct.inventory_item_id,
                locationID = application.claro.location_ID,
                quantity = arguments.product.inventory_quantity,
                shop = application.shopify.shop,
                accessToken = application.shopify.accessToken
            )>

            <cfset updated = saveVariant(
                stProduct = stResult.result.variant,
                sap_id = arguments.product.sap_id)>

            <cfif updated>
                <cfset stReturn.ok = true>
                <cfset stReturn.product = {"id":arguments.product.sap_id}>
            </cfif>
        
        </cfif>
        <cfreturn stReturn>
    </cffunction>


    <cffunction name="getProduct" access="private" returntype="query" output="false">
        <cfargument name="id" type="numeric" required="true">

        <cfset var qProduct = "">

        <cfquery datasource="#application.datasource#" name="qProduct">
            select * from products
            where id = <cfqueryparam cfsqltype="numeric" value="#arguments.id#">
        </cfquery>

        <cfreturn qProduct>
    </cffunction>


    <cffunction name="saveProduct" output="false" returntype="boolean" hint="save the product in the db" access="private">
        <cfargument name="stProduct" type="struct" required="true">
        <cfargument name="sap_id" type="numeric" required="true">


        <cfset var stVariant = {}>
        <cfset var idx = 0>

        <cftry>
        <cfquery datasource="#application.datasource#">
            INSERT INTO products (id,product_id,variant_id,inventory_item_id)
            VALUES
            <cfloop array="#arguments.stProduct.variants#" item="stVariant" index="idx">
                <cfif stVariant.sku eq arguments.sap_id>
                (
                    <cfqueryparam cfsqltype="integer" value="#arguments.sap_id#">
                    ,<cfqueryparam cfsqltype="varchar" value="#stVariant.product_id#">
                    ,<cfqueryparam cfsqltype="varchar" value="#stVariant.id#">
                    ,<cfqueryparam cfsqltype="varchar" value="#stVariant.inventory_item_id#">
                )
                </cfif>
            </cfloop>
            ON DUPLICATE KEY UPDATE
                product_id = values(product_id),
                variant_id = values(variant_id),
                inventory_item_id = values(inventory_item_id)
        </cfquery>
        <cfcatch>
            <cfset simpleLog(stLogdata={"error":cfcatch},filename="products")>
            <cfreturn false>
        </cfcatch>

        </cftry>
        <cfreturn true>
    </cffunction>

    <cffunction name="saveVariant" output="false" returntype="void" hint="save the product in the db" access="private">
        <cfargument name="stVariant" type="struct" required="true">
        <cfargument name="sap_id" type="numeric" required="true">

        <cfquery datasource="#application.datasource#">
            INSERT INTO products (id,product_id,variant_id,inventory_item_id)
            VALUES
            
                (
                    <cfqueryparam cfsqltype="integer" value="#arguments.sap_id#">
                    ,<cfqueryparam cfsqltype="varchar" value="#arguments.stVariant.product_id#">
                    ,<cfqueryparam cfsqltype="varchar" value="#arguments.stVariant.id#">
                    ,<cfqueryparam cfsqltype="varchar" value="#arguments.stVariant.inventory_item_id#">
                )
            
            ON DUPLICATE KEY UPDATE
                product_id = values(product_id),
                variant_id = values(variant_id),
                inventory_item_id = values(inventory_item_id)
        </cfquery>
    </cffunction>


    <cffunction name="updateMeta" returntype="struct" output="false" access="private">
        <cfargument name="metafields" type="array" required="true">
        <cfargument name="shop" type="string" required="true">
        <cfargument name="accesstoken" type="string" required="true">

        <cfset var gql = "">
        <cfset var stVars = {}>
        <cfset var stmetaupdate = {}>
        <cfsavecontent variable="gql">
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

        <cfset stVars = {
            "metafields": arguments.metafields
        }>
        <cfreturn variables.shopifyService.graphQL(
                query = gql,
                queryvars = stVars,
                shop = arguments.shop,
                accessToken = arguments.accesstoken
                )>
    </cffunction>
</cfcomponent>