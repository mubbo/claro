
<!--- <cfif structKeyExists(request,"security") AND request.security.getMode() EQ "DEV"> --->
  <cfoutput>
  <cfif listfirst(CGI.CONTENT_TYPE,";") eq "application/json">
  {
    "Exception":{
      "action":<cfif structKeyExists( request, 'failedAction' )>
        <!--- sanitize user supplied value before displaying it --->
        "#replace( request.failedAction, "<", "&lt;", "all" )#"
      <cfelse>
        "unknown"
      </cfif>,
      "message": "#request.exception.message#",
      "detail": "#request.exception.detail#",
      "stack": #serializeJson(request.exception.cause.tagcontext)#
    }
  }
 <cfelse>

  <div class="page-500 mode-dev">
    <div class="outer">
      <h4>An Error Occurred</h4>

      <p>Details of the exception:</p>
        <ul>
          <li>Failed action:
                <cfif structKeyExists( request, 'failedAction' )>
                  <!--- sanitize user supplied value before displaying it --->
                  #replace( request.failedAction, "<", "&lt;", "all" )#
                <cfelse>
                  unknown
                </cfif>
              </li>
          <li>Application event: #request.event#</li>
          <li>Exception type: #request.exception.type#</li>
          <li>Exception message: #request.exception.message#</li>
          <li>Exception detail: #request.exception.detail#</li>
          <li><div style ="overflow:auto;width:875px;height:500px"> <cfdump var="#request.exception#" expand="true"/></div>
        </ul>
    </div>
</div>
</cfif>
</cfoutput>
<!--- <cfelse>
  <cfmail from="ospa@ecommercify.ch" to="helpdesk@ecommercify.ch" subject="OSPA - ERROR #request.exception.type#/#request.exception.message#" type="html">
    shop: [<cfif structKeyExists(request,"security")>#request.security.getMerchantshop()#</cfif>]
    <cfdump var="#request.exception#"/>
  </cfmail>
  <div class="page-500">
    <div class="outer">
        <div class="middle">
            <div class="inner">
                <div class="inner-circle"><i class="fa fa-cogs"></i><span>500</span></div>
                <span class="inner-status">Opps! An unexpected error occured!</span>
                <span class="inner-detail">Don't worry our team has been informed of the error.</span>
            </div>
        </div>
    </div>
</cfif> --->
