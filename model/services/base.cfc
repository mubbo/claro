<cfcomponent>

    <cffunction name="simpleLog" returntype="void" access="public" output="false">
        <cfargument name="stLogData" type="struct" required="true">
        <cfargument name="filename" type="string" required="false" default="application">
        <cfargument name="directory" type="string" required="false" default="">
        <cfargument name="logErrorsAsHTML" type="boolean" required="false" default="false">
        <cfargument name="sendNotification" type="boolean" required="false" default="false">
        <cfargument name="cc" type="string" required="false" default="">

        <cfset var callStack = []>
        <cfset var sMethodName = "unknown">
        <cfset var type = "ERROR">
        <cfset var datePrefix = dateFormat(now(),"yyyymmdd")>
        <cfset var logPath = "#APPLICATION.general.rootPath#/logs/">
        <cfset var subject = "">
        <cfset var ccAddress = "">
        <cfif len(arguments.cc)>
            <cfset ccAddress = listAppend(ccAddress,arguments.cc)>
        </cfif>

        <cfif application.mode EQ "DEV">
            <cfset arguments.sendNotification = false>
        </cfif>
        <cfif len(arguments.directory)>
            <cfset logPath = variables.utilsService.ensurePath("#APPLICATION.general.rootPath#/logs/#arguments.directory#/#datePrefix#")>
        <cfelse>
            <cfset arguments.filename = arguments.filename & "_" & datePrefix>
            </cfif>
            <!--- check to ensure that we don't log anything if the fault response for some reason is empty --->
            <cfif NOT structIsEmpty(arguments.stLogData)>
                <cfset callStack = callStackGet()>
                <cfif arrayLen(callStack) GT 1>
                    <cfset sMethodName = callstack[2].function>
                </cfif>
                <cfif structKeyExists(arguments.stLogData,"type")>
                    <cfset type = arguments.stLogData.type>
                    <cfset structDelete(arguments.stLogData,"type")>
                </cfif>
                <cftry>
                    <cfif arguments.sendNotification eq True>
                        <cfset subject = "#application.general.appshortName# - #type# [function::#sMethodName#]">
                        <cfif structKeyExists(arguments.stLogData,"subject")>
                            <cfset subject = "#application.general.appshortName# - #type# [function::#sMethodName#] - #arguments.stLogData.subject#">
                            <cfset structDelete(arguments.stLogData,"subject")>
                        </cfif>
                        <cftry>
                            <cfmail from="#application.general.fromemail#" to="#APPLICATION.general.devContact#" subject="#subject#" cc="#ccAddress#" type="html">
                                <cfdump var="#arguments.stLogData#"/>
                            </cfmail>
                        <cfcatch>
                            <cffile action="append" file="#APPLICATION.general.rootPath#/logs/application_#datePrefix#.log" output="#type# [#now()# function::#sMethodName#]: #serializeJson(cfcatch)#" mode="777" charset="utf-8">
                        </cfcatch>
                        </cftry>
                    </cfif>
                    <cfif arguments.logErrorsAsHTML>
                        <cfdump var="#arguments.stLogData#" output="#logpath##arguments.filename#.html" format="html" label="#type# Occured ON:#now()#">
                    <cfelse>
                        <cffile action="append" file="#logpath##arguments.filename#.log" output="#type# [#now()# -> function::#sMethodName#]: #serializeJSON(arguments.stLogData)#" mode="777" charset="utf-8" >
                    </cfif>
                <cfcatch>
                    <cflog file="swisspost" text="#type# [#now()# -> function::#sMethodName#]: #serializeJSON(arguments.stLogData)#">
                    <cfmail from="#application.general.fromemail#" to="#APPLICATION.general.devContact#" subject="#subject#" cc="#ccAddress#" type="html">
                        <cfdump var="#arguments.stLogData#"/>
                    </cfmail>
                </cfcatch>
                </cftry>
            </cfif>
    </cffunction>

    <cffunction name="simpleFile" output="false" returntype="void" access="public">
        <cfargument name="filename" type="string" required="true" hint="filename with extension">
        <cfargument name="content" type="string" required="true" hint="the content of the file to write">
        <cfargument name="directory" type="string" required="true" hint="the directory where to write the file">
        <cfargument name="inThread" type="boolean" required="false" default="false">

        <cfset var filePath = variables.utilsService.ensurePath("#APPLICATION.general.rootPath#/backup/#arguments.directory#/")>
        <cfset var datePrefix = dateFormat(now(),"yyyymmdd")>

        <cfif arguments.inThread EQ true>
            <cfthread name="simpleFile_#arguments.filename#" action="run" filepath="#filepath#" filename="#arguments.filename#" output="#arguments.content#" >
                <cffile action="write" file="#filepath##datePrefix#_#filename#" output="#output#" mode="777" nameconflict="makeunique" charset="utf-8">
            </cfthread>
        <cfelse>
            <cffile action="write" file="#filepath##datePrefix#_#arguments.filename#" output="#arguments.content#" mode="777" nameconflict="makeunique" charset="utf-8">
        </cfif>

    </cffunction>

    <cffunction name="cutIdList" output="false" returntype="string" access="private"
        hint="Create string for SQL statements where given id list is cut to 1000 items per IN clause because of oracle limitations.">
        <!---
        split an ID list into parts for usage in sql 'IN' clause (oracle 8i/9i limits to 1000 items; last tested: 5/2003)
        usage: SELECT ... WHERE #cutIDlist(sColumn='o.object_ID', lID='99,99,99...')#
        =>  SELECT ... WHERE (o.object_ID IN (...) OR o.object_ID IN (...))
        --->
        <cfargument name="sColumn" type="string" required="Yes" hint="'Alias.columnName' before IN statement.">
        <cfargument name="lID" type="string" required="Yes" hint="Comma separated ID list.">

        <cfset var arCutLists = []>
        <cfset var arList = listToArray(arguments.lID)>
        <cfset var iArray = 1>
        <cfset var iIndex = 1>
        <cfset var sSqlCode = "">

        <cfset arCutLists[1] = []>
        <cfloop from="1" to="#arrayLen(arList)#" index="iIndex">
            <cfif arrayLen(arCutLists[iArray]) IS 1000>
                <cfset iArray = iArray + 1>
                <cfset arCutLists[iArray] = []>
            </cfif>
            <cfset arrayAppend(arCutLists[iArray], arList[iIndex])>
        </cfloop>

        <cfif listLen(arguments.lID) IS 1>
            <cfset sSqlCode = trim(listFirst(arguments.lID))>
            <cfif NOT isNumeric(sSqlCode) AND left(sSqlCode, 1) NEQ "'" AND left(sSqlCode, 1) NEQ '"'>
                <cfset sSqlCode = listQualify(sSqlCode, "'")><!--- add quotes to string values --->
            </cfif>
            <cfreturn "(" & arguments.sColumn & " = " & sSqlCode & ")">
        <cfelse>
            <cfloop from="1" to="#arrayLen(arCutLists)#" index="iIndex">
                <cfif iIndex GT 1>
                    <cfset sSqlCode = sSqlCode & " OR ">
                </cfif>
                <cfset sSqlCode = sSqlCode & arguments.sColumn & " IN (" & arrayToList(arCutLists[iIndex]) & ")">
            </cfloop>
            <cfreturn "(" & trim(sSqlCode) & ")">
        </cfif>

    </cffunction>

</cfcomponent>