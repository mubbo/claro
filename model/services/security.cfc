<cfcomponent output="false" accessors="true" extends="base">

    <cffunction name="init" output="false" returntype="any">
        <cfargument name="fw" type="any" required="true">
        <cfargument name="beanFactory" type="any" required="true">

        <cfset variables.fw = arguments.fw>
        <cfset variables.beanFactory = arguments.beanFactory>

        <cfreturn this>
    </cffunction>


</cfcomponent>