<cfcomponent displayname="bean" accessors="true" extends="base" hint="service component for handling crud operations for DB beans">
    <cfproperty name="beanFactory">


    <cffunction name="init" output="false" returntype="any">
        <cfargument name="fw" type="any" required="true">

        <cfset variables.fw = arguments.fw>

        <cfreturn this>
    </cffunction>
    <!---
        find: Finds the record in the database for the given bean name based on the passed in query structure, optionally returns a query instead of a bean
                if the record count > 0  returns an array of beans (asbean = true). optionally allows an order by.
                no aggregation!
    --->
    <cffunction name="find" access="public" returntype="any" output="false" hint="returns the record as a Bean or Null">
        <cfargument name="beanName" type="string" required="true">
        <cfargument name="stQuery" type="struct" required="false" default="#{}#">
        <cfargument name="asBean" type="boolean" required="false" default="true">
        <cfargument name="fields" type="string" required="false" default="">
        <cfargument name="orderby" type="string" required="false" default="">

        <cfset var fn = "">
        <cfset var qResults = "">
        <cfset var sCol= "">
        <cfset var val = "">
        <cfset var results = []>
        <cfset var record = variables.beanFactory.getBean("#arguments.beanName#Bean")>
        <cfset var beanProps = record.getProperties()>


        <!--- search for the record using the supplied query struct --->
        <cfquery name="qResults" datasource="#application.datasource#">
            select <cfif NOT len(arguments.fields)>*<cfelse>#arguments.fields#</cfif> from `#beanProps.tablename#`
            where 1=1
            <cfif NOT structIsEmpty(arguments.stQuery)>
                <cfloop collection="#arguments.stQuery#" item="sCol">
                    <cfif (beanProps.columns[sCol].type EQ "numeric" OR beanProps.columns[sCol].type EQ "boolean") AND isNumeric(arguments.stQuery["#sCol#"])>
                        AND #scol# = <cfqueryparam value="#arguments.stQuery["#sCol#"]#" cfsqltype="cf_sql_numeric">
                    <cfelseif beanProps.columns[sCol].type EQ "numeric" AND listLen(arguments.stQuery["#sCol#"],",") GT 0>
                        AND #scol# in (<cfqueryparam value="#arguments.stQuery["#sCol#"]#" cfsqltype="cf_sql_numeric" list="true">)
                    <cfelseif beanprops.columns[sCol].type EQ "string">
                        AND #scol# = <cfqueryparam value="#arguments.stQuery["#sCol#"]#" cfsqltype="cf_sql_varchar">
                    <cfelseif beanProps.columns[sCol].type EQ "date">
                        <cfif isSimpleValue(arguments.stQuery["#sCol#"])>
                            AND #scol# = <cfqueryparam value="#arguments.stQuery["#sCol#"]#" cfsqltype="cf_sql_date">
                        <cfelse>
                        <!--- criterion --->
                        <cfswitch expression="#arguments.stQuery["#sCol#"].criteria#">
                            <cfcase value="between">
                                AND #scol# BETWEEN <cfqueryparam value="#arguments.stQuery["#sCol#"].datefrom#" cfsqltype="cf_sql_date"> AND <cfqueryparam value="#arguments.stQuery["#sCol#"].dateto#" cfsqltype="cf_sql_date">
                            </cfcase>
                            <cfcase value=">">
                                AND #scol# > <cfqueryparam value="#arguments.stQuery["#sCol#"].datefrom#" cfsqltype="cf_sql_date">
                            </cfcase>
                            <cfcase value="<">
                                AND #scol# > <cfqueryparam value="#arguments.stQuery["#sCol#"].dateto#" cfsqltype="cf_sql_date">
                            </cfcase>
                        </cfswitch>
                        </cfif>
                    </cfif>
                </cfloop>
            </cfif>
            <cfif len(arguments.orderby)>
                order by #arguments.orderby#
            </cfif>
        </cfquery>


        <!--- if a record was found then populate a record bean and return it --->
        <cfif arguments.asBean>
            <cfif qResults.recordcount EQ 1>
                    <cfset record = variables.beanFactory.getBean("#arguments.beanName#Bean")>
                    <cfloop collection="#beanProps.columns#" item="sCol">
                        <cfif listFindNoCase(qResults.columnlist, sCol)>
                            <cfset val = qResults["#sCol#"]>
                            <cftry>
                            <cfif len(val)>
                                <cfset record["set#sCol#"](val)>
                            </cfif>
                            <cfcatch>
                                <cfset simpleLog({"type":"error", "error":cfcatch})>
                            </cfcatch>
                            </cftry>
                        </cfif>
                    </cfloop>
                    <cfreturn record>
            <cfelseif qResults.recordcount GT 1>
                <cfloop query="qResults">
                    <cfset record = variables.beanFactory.getBean("#arguments.beanName#Bean")>
                    <cfloop collection="#beanProps.columns#" item="sCol">
                        <cfif listFindNoCase(qResults.columnlist, sCol)>
                            <cfset val = qResults["#sCol#"]>
                            <cftry>
                            <cfif len(val)>
                                <cfset record["set#sCol#"](val)>
                            </cfif>
                            <cfcatch>
                                <cfset simpleLog({"type":"error", "error":cfcatch})>
                            </cfcatch>
                            </cftry>
                        </cfif>
                    </cfloop>
                    <cfset arrayAppend(results, record)>
                </cfloop>
                <cfreturn results>
            </cfif>
            <cfreturn>
        <cfelse>
            <cfreturn qResults>
        </cfif>
    </cffunction>

    <!---
        save: either update or create the bean in the database, dynamically build insert or update query based on bean properties
    --->
    <cffunction name="save" access="public" output="false" returntype="void" hint="saves/creates a record in the db">
        <cfargument name="bean" type="any" required="true">

        <cfset var col = "">
        <cfset var sInsertCols = "">
        <cfset var iInsertLen = 0>
        <cfset var i = 0>
        <cfset var beanProps = arguments.bean.getProperties()>

        <cfif arguments.bean.getid() GT 0>
            <cfquery datasource="#application.datasource#">
            update `#beanProps.tableName#`
            set
            <cfloop collection="#beanProps.columns#" item="col">
                <!--- don't try to update the id column --->
                <cfif col NEQ "id">

                <!--- acf doesnt like dynamic function calls so we have to have an intermediary variable --->
                    <cfset arguments.bean.fn = arguments.bean["get#col#"]>
                    <cfif beanProps.columns[col].type eq "date">
                        <cfif NOT isNull(arguments.bean.fn()) AND len(arguments.bean.fn()) GT 1>
                            <cfif i GT 0>,</cfif> #col# = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.bean.fn()#">
                            <cfset i++>
                        <cfelse>
                            <cfif i GT 0>,</cfif> #col# = <cfqueryparam cfsqltype="cf_sql_timestamp" null="true">
                            <cfset i++>
                        </cfif>
                    <cfelseif beanProps.columns[col].type EQ "numeric" OR beanProps.columns[col].type EQ "boolean">
                        <cfif i GT 0>,</cfif>
                        <cfif NOT isNull(arguments.bean.fn())>
                            #col# = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.bean.fn()#">
                        <cfelse>
                            #col# = <cfqueryparam cfsqltype="cf_sql_numeric" null="true">
                        </cfif>
                        <cfset i++>
                    <cfelseif beanProps.columns[col].type EQ "string">
                        <cfif i GT 0>,</cfif>
                        <cfif NOT isNull(arguments.bean.fn()) AND len(arguments.bean.fn())>
                            #col# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.bean.fn()#">
                        <cfelse>
                            #col# = <cfqueryparam cfsqltype="cf_sql_varchar" null="true">
                        </cfif>
                        <cfset i++>
                    </cfif>

                </cfif>
            </cfloop>
            where id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.bean.getid()#">
            </cfquery>
        <cfelse>
            <!--- insert the bean --->
            <cfloop list="#structKeyList(beanProps.columns)#" index="col">
                <!--- acf doesnt like dynamic function calls so we have to have an intermediary variable --->
                <cfset arguments.bean.fn = arguments.bean["get#col#"]>
                <cfif NOT isNull(arguments.bean.fn()) AND len(arguments.bean.fn()) AND col NEQ "ID">
                    <cfset sInsertCols = listAppend(sInsertCols, col)>
                </cfif>
            </cfloop>
            <cfset iInsertLen = listLen(sInsertCols)>
            <cfquery datasource="#application.datasource#">
            insert into `#beanProps.tableName#` (#sInsertCols#)
            values (<cfloop list="#sInsertCols#" index="col"><cfset i++>
                <!--- acf doesnt like dynamic function calls so we have to have an intermediary variable --->
                <cfset arguments.bean.fn = arguments.bean["get#col#"]>
                <cfif beanProps.columns[col].type eq "date">
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.bean.fn()#"><cfif i LT iInsertLen>,</cfif>
                <cfelseif beanProps.columns[col].type EQ "numeric" OR beanProps.columns[col].type EQ "boolean">
                    <cfqueryparam cfsqltype="numeric" value="#arguments.bean.fn()#"><cfif i LT iInsertLen>,</cfif>
                <cfelse>
                    <cfqueryparam cfsqltype="varchar" value="#arguments.bean.fn()#"><cfif i LT iInsertLen>,</cfif>
                </cfif>
                </cfloop>)
            </cfquery>
        </cfif>
    </cffunction>
</cfcomponent>