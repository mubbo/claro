<cfcomponent  displayName="base" output="false" accessors="true">

    <cffunction name="init" output="false" returntype="any">
        <cfset var prop = "">
        <cfset var metaData = getMetaData(this)>
        <cfset var props = metaData.properties>
        <cfset var colName = "">

        <cfset variables["_properties"] = {
            "tablename": metaData.tablename,
            "columns":{}
        }>
        <cfloop array="#props#" index="prop">
            <cfset colName = prop.name>
            <cfset variables._properties["columns"][colName] = prop>
            <cfif NOT structKeyExists(prop,"default")>
                <cfset variables._properties["columns"][colName]["default"] = javaCast( "null", 0 )>
            </cfif>
        </cfloop>
        <cfreturn this>
    </cffunction>

    <cffunction name="getProperties" returntype="struct" output="false">
        <cfreturn variables._properties>
    </cffunction>

    <cffunction name="hasProperty" returntype="boolean" output="false">
        <cfargument name="prop" type="string" required="true">

        <cfreturn structKeyExists(variables._properties.columns,arguments.prop)>

    </cffunction>

</cfcomponent>