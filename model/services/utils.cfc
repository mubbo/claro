<cfcomponent>

    <cffunction name="init" output="false" returntype="any">
        <cfargument name="fw" type="any" required="true">
        <cfargument name="charset" type="string" default="utf-8" hint="Character encoding used by the current instance of the CFC">
        <cfargument name="mode" type="string" default="777" hint="file mode used as Permissions for Unix or Linux">


        <cfset variables.charset = arguments.charset>
        <cfset variables.mode = arguments.mode>
        <cfset variables.os = lCase(listFirst(server.os.name, ' '))>

        <cfset variables.fw = arguments.fw>
        <cfreturn this>
    </cffunction>

    <cffunction name="uploadFile" access="public" output="No" hint="Uploads a file" returntype="any">
        <cfargument name="formField" required="Yes" type="string" hint="The name of the field that contains the file to be uploaded">
        <cfargument name="destination" required="Yes" type="string" hint="Directory file is to be uploaded to (absolute path)">
        <cfargument name="accept" hint="File types to accept" type="string" default="">
        <cfargument name="maxfilesize" hint="max file size" type="string" default="">
        <cfargument name="nameconflict" hint="File write behavior" type="string" default="MAKEUNIQUE">
        <cfargument name="fileMode" type="string" required="false" default="#variables.mode#" hint="file mode used as Permissions for Unix or Linux">
        <cfargument name="useFileMode" type="boolean" required="false" default="true">

        <cfif len(arguments.formField) AND checkDirectoryPath(arguments.destination) AND (NOT len(arguments.maxfilesize) OR (isNumeric(arguments.maxfilesize) AND val(cgi.content_length) LT arguments.maxfilesize))>
            <cftry>
                <cflock timeout="10" type="readonly" name="#arguments.formField#">
                    <cfif arguments.useFileMode AND variables.os NEQ "windows">
                        <cffile action="UPLOAD" filefield="#arguments.formField#" destination="#arguments.destination#" nameconflict="#arguments.nameconflict#" accept="#arguments.accept#" mode="#arguments.fileMode#">
                    <cfelse>
                        <cffile action="UPLOAD" filefield="#arguments.formField#" destination="#arguments.destination#" nameconflict="#arguments.nameconflict#" accept="#arguments.accept#">
                    </cfif>
                </cflock>

                <cfreturn duplicate(cffile)>

                <cfcatch>
                    <cffile action="append" file="#expandpath('#APPLICATION.general.root#/logs/general.log')#" output="ERROR [#now()#]: utils.uploadFile, error uploading file #arguments.formField# to #arguments.destination#: #cfcatch.message# / #cfcatch.detail#" mode="777">
                </cfcatch>
            </cftry>
        </cfif>

        <cfreturn false>
    </cffunction>

    <cffunction name="createDirectory" access="public" output="No" hint="Creates a directory">
        <cfargument name="directoryPath" type="string" required="true" hint="Absolute directory path">

        <cfset var stException = {}>

        <cfif NOT checkDirectoryPath(arguments.directoryPath)>
            <cftry>
                <cflock timeout="10" type="readonly" name="#arguments.directoryPath#">
                    <cfdirectory action="CREATE" directory="#arguments.directoryPath#" mode="777">
                </cflock>

                <cfreturn true>

                <cfcatch>
                    <cfset stException = duplicate(cfcatch)>
                    <cfif NOT findNoCase("already exists", stException.message)>
                        <cffile action="append" file="#expandpath('#APPLICATION.general.root#/logs/general.log')#" output="ERROR [#now()#]: filesystem.createDirectory, error creating directory: #arguments.directoryPath# and/or all necessary parent directories: #stException.message# / #stException.detail#">
                    </cfif>
                </cfcatch>
            </cftry>
        </cfif>

        <cfreturn false>
    </cffunction>

    <cffunction name="ensurePath" output="No" returntype="string" access="public" hint="Returns the path with fixed file system dependant path separator and an concatenated path separator at the end, if there is none.">
        <cfargument name="directoryPath" type="string" required="Yes" hint="Absolute path of the directory to be created.">

        <cfscript>
        var sPath = arguments.directoryPath;

        sPath = replace(sPath, "\", "/", "ALL");

        if (right(sPath, 1) NEQ "/") {
            sPath = sPath & "/";
        }

        if (NOT checkDirectoryPath(sPath)){
            createDirectory(sPath);
        }

        return sPath;
        </cfscript>
    </cffunction>


    <cffunction name="checkDirectoryPath" access="public" output="No" returntype="boolean">
		<cfargument name="directoryPath" type="string" required="true" hint="Absolute directory path">

		<cflock timeout="10" throwontimeout="yes" type="readonly" name="#arguments.directoryPath#">
			<cfreturn directoryExists(arguments.directoryPath)>
		</cflock>
    </cffunction>

    <cffunction name="copyFile" access="public" output="No" hint="Copy a file" returntype="boolean">
		<cfargument name="source" type="string" required="true" hint="Absolute file path of the file to copy">
		<cfargument name="destination" type="string" required="true" hint="Pathname of a directory where the file will be copied. If not an absolute path, it is relative to the source directory">
		<cfargument name="fileMode" type="string" required="false" default="#variables.mode#" hint="file mode used as Permissions for Unix or Linux">
		<cfargument name="useFileMode" type="boolean" required="false" default="true">

		<cfif checkFilePath(arguments.source) AND len(arguments.destination)>
			<cftry>
				<cflock timeout="10" type="readonly" name="#arguments.source#">
					<cfif arguments.useFileMode AND variables.os NEQ "windows">
						<cffile action="copy" source="#arguments.source#" destination="#arguments.destination#" mode="#arguments.fileMode#">
					<cfelse>
						<cffile action="copy" source="#arguments.source#" destination="#arguments.destination#">
					</cfif>
				</cflock>

				<cfreturn true>

				<cfcatch>
                    <cffile action="append" file="#expandpath('#APPLICATION.general.root#/logs/general.log')#" output="ERROR [#now()#]: utils.copyFile, error copying file #arguments.source# to #arguments.destination#: #cfcatch.message# / #cfcatch.detail#" >
				</cfcatch>
			</cftry>
		</cfif>

		<cfreturn false>
    </cffunction>

    <cffunction name="checkFilePath" access="public" output="No" returntype="boolean">
		<cfargument name="filePath" type="string" required="Yes" hint="Absolute file path">
		<cfreturn fileExists(arguments.filePath)>
    </cffunction>


    <cffunction name="formatShopifyAddressForSP" access="public" returntype="struct" output="false">
        <cfargument name="address" type="struct" required="true" hint="a shopify formatted address">

        <cfset var stReturn = {ok:false,result:{}}>
        <cfset var stAddress = {}>
        <cfset var houseNumber = "">
        <cfset var street1 = arguments.address.address1>
        <cfset var jpattern = createObject('java', 'java.util.regex.Pattern').compile('^(\b\D+\b)?\s*(\b.*?\d.*?\b)\s*(\b\D+\b)?$')>
        <cfset var jMatcher = jPattern.matcher(arguments.address.address1)>

        <cfif jMatcher.matches()>
            <cfif NOT isNull(jMatcher.group(1))>
                <cfset street1 = jMatcher.group(1)>
            </cfif>
            <cfif NOT isNull(jMatcher.group(2))>
                <cfset houseNumber = jMatcher.group(2)>
            </cfif>
        </cfif>
        <cfif structKeyExists(arguments.address,"address2")>
            <cfset houseNumber = arguments.address.address2>
        </cfif>
        <cfif len(houseNumber)>
            <cfset street1 =  replaceNoCase(street1, houseNumber,"","all")>
        </cfif>

        <cftry>
        <cfset stAddress =
            {
                "addressee":{
                    "firstName": isNull(arguments.address.firstname)?"":arguments.address.firstname,
                    "lastName": isNull(arguments.address.lastname)?"":arguments.address.lastname
                },
                "geographicLocation":{
                    "house":{
                        "street": street1,
                        "houseNumber": houseNumber,
                        "additionalAddress":""
                    },
                    "zip":{
                        "zip": isNull(arguments.address.zip)?"":arguments.address.zip,
                        "city": isNull(arguments.address.city)?"":arguments.address.city
                    }
                },
                 "fullValidation":true
            }>

            <cfif NOT isNull(arguments.address.address2)>
                <cfset stAddress["geographicLocation"]["house"]["additionalAddress"] = arguments.address.address2>
            </cfif>
            <cfset stReturn.ok = true>
            <cfset stReturn.result = stAddress>
        <cfcatch>

            <cffile action="append" file="#expandpath('#APPLICATION.general.root#/logs/general.log')#" output="ERROR [#now()#]: Error in utils.cfc[formatshopifyaddressforsp] - incoming address error #cfcatch.message# [#serializejson(arguments.address)#]">
        </cfcatch>
        </cftry>

        <cfreturn stReturn>
    </cffunction>

    <cffunction name="listDeleteList" output="No" returntype="string" access="public" hint="Deletes any item of second list from first.">
      <cfargument name="sourceList" type="string" required="yes" hint="List from which to delete items in removeList">
      <cfargument name="removeList" type="string" required="yes" hint="List with items to delete from sourceList">
      <cfargument name="delimiter" type="string" default="," hint="Delimiter of list">

      <cfset var iList = 0>
      <cfset var nPos = 0>
      <cfset var sReturn = arguments.sourceList>

      <cfloop list="#arguments.removeList#" index="iList" delimiters="#arguments.delimiter#">
          <cfloop condition="true">
              <cfset nPos = listFindNoCase(sReturn, iList, arguments.delimiter)>
              <cfif nPos>
                  <cfset sReturn = listDeleteAt(sReturn, nPos, arguments.delimiter)>
              <cfelse>
                  <cfbreak>
              </cfif>
          </cfloop>
      </cfloop>

      <cfreturn sReturn>
    </cffunction>


    <cffunction name="decodeQueryString" output="false" returntype="struct" access="public">
        <cfargument name="queryString" type="string" required="true">

        <cfset var stResult = {}>
        <cfset var itm = "">
        <cfset var itmName = "">
        <cfset var itmValue = "">
        <cfset var cleanName = "">
        <cfset var isArray = false>

        <cfloop list="#urlDecode(arguments.queryString)#" index="itm" delimiters="&">
            <cfset isArray = false>
            <cfset itmName = listFirst(itm,"=")>
            <cfset itmValue = listlast(itm,"=")>
            <cfset cleanName = itmName>
            <cfif findNoCase("[]",itmName)>
                <cfset isArray = true>
                <cfset cleanName = replace(itmName,"[]","")>
            </cfif>
            <cfif NOT structKeyExists(stResult, cleanName) and isArray>
                <cfset stResult[cleanName] = []>
            </cfif>
            <cfif isArray>
                <cfset arrayAppend(stResult[cleanName], itmValue)>
            <cfelse>
                <cfset stResult[cleanName] = itmValue>
            </cfif>
        </cfloop>

        <cfreturn stResult>
    </cffunction>

    <!--- xml utils --->
    <!---
        Description:
        ============
            xml library
        --->



  <cffunction name="validateXMLString" output="false" returntype="boolean"
    hint="Validate a formatted XML string against a DTD">
      <cfargument name="xmlString" type="string" required="true" hint="XML to validate">
      <cfargument name="throwerror" type="boolean" required="false" default="false" hint="Throw an exception if the document isn't valid">
      <cfargument name="baseUrl" type="string" required="false" default="" hint="Needed to resolve url found in the DOCTYPE declaration and external entity references. Format must be: http://www.mydomain.com/xmldirectory/">

      <cfset var bValid=true>
      <cfset var jStringReader="">
      <cfset var xmlInputSource="">
      <cfset var saxFactory="">
      <cfset var xmlReader="">
      <cfset var eHandler="">
      <cftry>
          <cfscript>
          //Use Java string reader to read the CFML variable
          jStringReader = CreateObject("java","java.io.StringReader").init(arguments.xmlString);
          //Turn the string into a SAX input source
          xmlInputSource = CreateObject("java","org.xml.sax.InputSource").init(jStringReader);
          //Call the SAX parser factory
          saxFactory = CreateObject("java","javax.xml.parsers.SAXParserFactory").newInstance();
          //Creates a SAX parser and get the XML Reader
          xmlReader = saxFactory.newSAXParser().getXMLReader();
          //Turn on validation
          xmlReader.setFeature("http://xml.org/sax/features/validation",true);
          //Add a system id if required
          if(IsDefined("arguments.baseUrl")){
              xmlInputSource.setSystemId(arguments.baseUrl);
          }
          //Create an error handler
          eHandler = CreateObject("java","org.apache.xml.utils.DefaultErrorHandler").init();
          //Assign the error handler
          xmlReader.setErrorHandler(eHandler);
          </cfscript>

          <!--- Throw an exception in case any Java initialization failed --->
          <cfcatch type="Object">
              <cfthrow message="validateXMLString: failed to initialize Java objects" type="validateXMLString">
          </cfcatch>
      </cftry>

      <cftry>
          <cfset xmlReader.parse(xmlInputSource)>

          <!--- Catch SAX's exception and set the flag --->
          <cfcatch type="org.xml.sax.SAXParseException">
              <!--- The SAX parser failed to validate the document --->
              <cfset bValid=false>
              <cfif arguments.throwerror>
                  <!--- Throw an exception with the error message if required	--->
                  <cfthrow message="validateXMLString: Failed to validate the document, #cfcatch.Message#" type="validateXMLString">
              </cfif>
          </cfcatch>
      </cftry>

      <cfreturn bValid>
  </cffunction>


  <cffunction name="xmlMerge" output="false" returntype="any"
    hint="Merges one xml document into another. Changes the first XML object">
      <cfargument name="xml1" type="string" required="true" hint="The XML object into which you want to merge">
      <cfargument name="xml2" type="string" required="true" hint="The XML object which you want to merge">
      <cfargument name="overwriteNodes" type="boolean" required="false" hint="Boolean value for whether you want to overwrite" default="true">

      <cfscript>
      var readNodeParent = arguments.xml2;
      var writeNodeList = arguments.xml1;
      var writeNodeDoc = arguments.xml1;
      var readNodeList = "";
      var writeNode = "";
      var readNode = "";
      var nodeName = "";
      var ii = 0;
      var writeNodeOffset = 0;
      var toAppend = 0;
      var nodesDone = {};
      var bOverwrite = arguments.overwriteNodes;
      var lTopNodes = "";//dont duplicate top nodes
      // if there's a 3rd argument, that's the overWriteNodes flag
      if(structCount(arguments) GT 2)
          bOverwrite = arguments[3];
      // if there's a 4th argument, it's the DOC of the writeNode -- not a user provided argument -- just used when doing recursion, so we know the original XMLDoc object
      if(structCount(arguments) GT 3)
          writeNodeDoc = arguments[4];
      // if we are looking at the whole document, get the root element
      if(isXMLDoc(arguments.xml2))
          readNodeParent = arguments.xml2.xmlRoot;
      //if we are looking at the whole Doc for the first element, get the root element
      if(isXMLDoc(arguments.xml1))
          writeNodeList = arguments.xml1.xmlRoot;
      if (structCount(arguments) LE 3){// get only top nodes
          for(nodeName in writeNodeList){
              lTopNodes = ListAppend(lTopNodes,nodeName);
          };
      };
      // loop through the readNodeParent (recursively) and override all xmlAttributes/xmlText in the first document with those of elements that match in the second document
      for(nodeName in readNodeParent){
          writeNodeOffset = 0;
          // if we haven't yet dealt with nodes of this name, do it
          if(NOT structKeyExists(nodesDone,nodeName)){
              readNodeList = readNodeParent[nodeName];
              // if there aren't any of this node, we need to append however many there are
              if(NOT structKeyExists(writeNodeList,nodeName)){
                  toAppend = arrayLen(readNodeList);
              }
              // if there are already at least one node of this name
              else{
                  // if we are overwriting nodes, we need to append however many there are minus however many there were (if there none new, it will be 0)
                  if(bOverwrite){
                      toAppend = arrayLen(readNodeList) - arrayLen(writeNodeList[nodeName]);
                  }
                  // if we are not overwriting, we need to add however many there are
                  else{
                      toAppend = arrayLen(readNodeList);
                      // if we are not overwriting, we need to make the offset of the writeNode equal to however many there already are
                      writeNodeOffset = arrayLen(writeNodeList[nodeName]);
                  }
              }
              // append however many nodes necessary of the name
              for(ii = 1;  ii LTE toAppend; ii = ii + 1){
                  if(NOT ListFind(lTopNodes,nodeName)) arrayAppend(writeNodeList.xmlChildren,xmlElemNew(writeNodeDoc,nodeName));
                  else writeNodeOffset = writeNodeOffset - 1;
              }
              // loop through however many of this nodeName there are, writing them to the writeNodes
              for(ii = 1; ii LTE arrayLen(readNodeList); ii = ii + 1){
                  writeNode = writeNodeList[nodeName][ii + writeNodeOffset];
                  readNode = readNodeList[ii];
                  // set the xmlAttributes and xmlText to this child's values
                  writeNode.xmlAttributes = readNode.xmlAttributes;
                  writeNode.xmlText = readNode.xmlText;
                  // if this element has any children, recurse
                  if(arrayLen(readNode.xmlChildren)){
                      xmlMerge(writeNode,readNode,bOverwrite,writeNodeDoc);
                  }
              }
              // add this node name to those nodes we have done -- we need to do this because an XMLDoc object can have duplicate keys
              nodesDone[nodeName] = true;
          }
      }
      </cfscript>
  </cffunction>


  <cffunction name="xmlUnformat" access="public" returntype="string" output="false"
    hint="UN-escapes the five forbidden characters in XML data. Opposite to encodeForXml().">
      <cfargument name="sString" type="string" required="yes" hint="String to format.">

      <cfset var sReturn = arguments.sString>
      <cfset sReturn = replaceNoCase(sReturn, "&apos;", "'", "ALL")>
      <cfset sReturn = replaceNoCase(sReturn, "&quot;", """", "ALL")>
      <cfset sReturn = replaceNoCase(sReturn, "&lt;", "<", "ALL")>
      <cfset sReturn = replaceNoCase(sReturn, "&gt;", ">", "ALL")>
      <cfset sReturn = replaceNoCase(sReturn, "&amp;", "&", "ALL")>
      <cfreturn sReturn>
  </cffunction>


  <cffunction name="XmlImportNode" access="public" returntype="boolean" output="false"
    hint="tree walker designed to implement the importNode function of most XML DOM parsers">
      <cfargument name="xmlTargetDoc" type="string" required="yes"><!--- the document that will accept the new node. This is used to create a new node with the same ownership as the target node --->
      <cfargument name="xmlTargetNode" type="string" required="yes"><!--- the complete path of the node (including the document) that will receive the new node --->
      <cfargument name="xmlImportedNode" type="string" required="yes"><!--- the node that will be copied into the receiving node --->

      <cfscript>
      var i = 0;
      var j = 0;
      var elem = XmlElemNew(xmlTargetDoc, "#xmlImportedNode.XmlName#");
      var key = "";

      // assign XmlText
      if(not isXmlRoot(xmlImportedNode)){
          elem.xmlText = xmlImportedNode.xmlText;}
      // assign XmlAttributes, need to loop though structure here
      if(not isXmlRoot(xmlImportedNode)){
          for(j = 1; j lte structcount(xmlImportedNode.xmlAttributes); j = j + 1){
              key = listgetat(structkeylist(xmlImportedNode.xmlAttributes),j);
              structInsert(elem.xmlAttributes,"#key#",structFind(xmlImportedNode.xmlAttributes,key));
          }
      }
      // assign XmlChildren, recursively loop through xmlchildren
      for(i = 1; i lte arrayLen(xmlImportedNode.xmlChildren); i = i + 1){
          XmlImportNode(xmlTargetDoc, elem, xmlImportedNode.xmlChildren[i]);
      }
      // append new element to target
      arrayAppend(xmlTargetNode.xmlChildren,elem);
      </cfscript>

      <cfreturn true>
  </cffunction>


  <cffunction name="xml2Struct" access="public" returntype="any" output="false"
    hint="Convert xml with attributes into cfml struct / array.">
      <cfargument name="xmlNode" type="xml" required="true">

      <cfset var iIndex = 0>
      <cfset var iItem = 0>
      <cfset var sTemp = 0>
      <cfset var stReturn = {}>

      <cfif xmlGetNodeType( arguments.xmlNode ) IS "DOCUMENT_NODE" AND NOT structKeyExists(arguments.xmlNode, "xmlChildren")>
          <cfset stReturn[ structKeyList(arguments.xmlNode) ] = xml2Struct( arguments.xmlNode[ structKeyList(arguments.xmlNode) ] )>
      </cfif>

      <cfif structKeyExists( arguments.xmlNode, "xmlText" ) AND len( trim(arguments.xmlNode.xmlText) )>
          <cfset stReturn.value = arguments.xmlNode.xmlText>
      </cfif>

      <cfif structKeyExists( arguments.xmlNode, "xmlAttributes" ) AND structCount( arguments.xmlNode.xmlAttributes )>
          <cfset stReturn.attributes = {}>
          <cfloop collection="#arguments.xmlNode.xmlAttributes#" item="iItem">
              <cfset stReturn.attributes[iItem] = arguments.xmlNode.xmlAttributes[iItem]>
          </cfloop>
      </cfif>

      <cfif structKeyExists(arguments.xmlNode, "xmlChildren")>
          <cfloop from="1" to="#arrayLen(arguments.xmlNode.xmlChildren)#" index="iIndex">
              <cfif structKeyExists( stReturn, arguments.xmlNode.xmlchildren[iIndex].xmlname )>
                  <cfif NOT isArray( stReturn[ arguments.xmlNode.xmlChildren[iIndex].xmlname ] )>
                      <cfset sTemp = stReturn[ arguments.xmlNode.xmlchildren[iIndex].xmlname ]>
                      <cfset stReturn[ arguments.xmlNode.xmlchildren[iIndex].xmlname ] = [ sTemp ]>
                  </cfif>
                  <cfset arrayAppend( stReturn[ arguments.xmlNode.xmlchildren[iIndex].xmlname ], xml2Struct( arguments.xmlNode.xmlChildren[iIndex] ) )>
              <cfelse>
                  <cfif structKeyExists( arguments.xmlNode.xmlChildren[iIndex], "xmlChildren" ) AND arrayLen( arguments.xmlNode.xmlChildren[iIndex].xmlChildren )>
                      <cfset stReturn[ arguments.xmlNode.xmlChildren[iIndex].xmlName ] = xml2Struct( arguments.xmlNode.xmlChildren[iIndex] )>
                  <cfelseif structKeyExists( arguments.xmlNode.xmlChildren[iIndex], "xmlAttributes" ) AND structCount( arguments.xmlNode.xmlChildren[iIndex].xmlAttributes )>
                      <cfset stReturn[ arguments.xmlNode.xmlChildren[iIndex].xmlName ] = xml2Struct( arguments.xmlNode.xmlChildren[iIndex] )>
                  <cfelse>
                      <cfset stReturn[ arguments.xmlNode.xmlChildren[iIndex].xmlName ] = arguments.xmlNode.xmlChildren[iIndex].xmlText>
                  </cfif>
              </cfif>
          </cfloop>
      </cfif>

      <cfreturn stReturn>
  </cffunction>


  <cffunction name="convertXmlToStruct" access="public" returntype="struct" output="false"
    hint="Parse raw XML into ColdFusion structs and arrays and return it.">
      <cfargument name="xmlNode" type="string" required="true">
      <cfargument name="str" type="struct" required="true">

      <!--- setup local variables for recurse --->
      <cfset var i = 0>
      <cfset var iItem = 0>
      <cfset var axml = arguments.xmlNode>
      <cfset var astr = arguments.str>
      <cfset var n = "">
      <cfset var tmpContainer = "">
      <cfset var at_list = "">
      <cfset var attrib_list = "">
      <cfset var attrib = 0>
      <cfset var atr = 0>

      <cfif NOT len(trim(arguments.xmlNode))>
          <cfreturn astr>
      </cfif>

      <cftry>
          <cfset axml = xmlSearch( xmlParse(arguments.xmlNode), "/node()" )>

          <!--- log xmlparse errors --->
          <cfcatch>
              <cflog text="error in util.xml.xml.convertXmlToStruct()! Errromessage: #cfcatch.message#" file="contens_errors" type="Error">
              <cfreturn astr>
          </cfcatch>
      </cftry>

      <cfset axml = axml[1]>

      <!--- for each children of context node --->
      <cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
          <!--- read XML node name without namespace --->
          <cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "")>

          <!--- if key with that name exists within output struct ... --->
          <cfif structKeyExists(astr, n)>
              <!--- ... and is not an array... --->
              <cfif not isArray(astr[n])>
                  <!--- ... get this item into temp variable, ... --->
                  <cfset tmpContainer = astr[n]>
                  <!--- ... setup array for this item beacuse we have multiple items with same name, ... --->
                  <cfset astr[n] = []>
                  <!--- ... and reassing temp item as a first element of new array: --->
                  <cfset astr[n][1] = tmpContainer>
              <cfelse>
                  <!--- item is already an array --->
              </cfif>
              <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
                  <!--- recurse call: get complex item: --->
                  <cfset astr[n][arrayLen(astr[n])+1] = convertXmlToStruct(axml.XmlChildren[i], {})>
              <cfelse>
                  <!--- else: assign node value as last element of array: --->
                  <cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText>
              </cfif>
          <cfelse>
              <!---
                  this is not a struct. This may be first tag with some name.
                  this may also be one and only tag with this name.
              --->
              <!--- if context child node has child nodes (which means it will be complex type): --->
              <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
                  <!--- recurse call: get complex item: --->
                  <cfset astr[n] = convertXmlToStruct(axml.XmlChildren[i], {})>
              <cfelse>
                  <cfif IsStruct(aXml.XmlAttributes) AND structCount(aXml.XmlAttributes)>
                      <cfset at_list = structKeyList(aXml.XmlAttributes)>

                      <cfloop from="1" to="#listLen(at_list)#" index="atr">
                           <cfif listgetAt(at_list,atr) CONTAINS "xmlns:">
                               <!--- remove any namespace attributes--->
                              <cfset structdelete(axml.XmlAttributes, listgetAt(at_list,atr))>
                           </cfif>
                       </cfloop>

                       <!--- if there are any atributes left, append them to the response--->
                       <cfif structCount(axml.XmlAttributes) GT 0>
                          <cfset astr['_attributes'] = {}>
                           <cfloop collection="#axml.XmlAttributes#" item="iItem">
                               <cfset astr['_attributes'][iItem] = axml.XmlAttributes[iItem]>
                          </cfloop>
                      </cfif>
                  </cfif>

                  <!--- else: assign node value as last element of array --->
                  <!--- if there are any attributes on this element --->
                  <cfif IsStruct(aXml.XmlChildren[i].XmlAttributes) AND structCount(aXml.XmlChildren[i].XmlAttributes) GT 0>
                      <!--- assign the text --->
                      <cfset astr[n] = axml.XmlChildren[i].XmlText>
                          <!--- check if there are no attributes with xmlns: , we dont want namespaces to be in the response--->
                       <cfset attrib_list = structKeylist(axml.XmlChildren[i].XmlAttributes)>

                       <cfloop from="1" to="#listLen(attrib_list)#" index="attrib">
                           <cfif listgetAt(attrib_list,attrib) CONTAINS "xmlns:">
                               <!--- remove any namespace attributes--->
                              <cfset structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib))>
                           </cfif>
                       </cfloop>

                       <!--- if there are any atributes left, append them to the response--->
                       <cfif structCount(axml.XmlChildren[i].XmlAttributes) GT 0>
                          <cfset astr[n&'_attributes'] = {}>
                           <cfloop collection="#axml.XmlChildren[i].XmlAttributes#" item="iItem">
                               <cfset astr[n&'_attributes'][iItem] = axml.XmlChildren[i].XmlAttributes[iItem]>
                          </cfloop>
                      </cfif>
                  <cfelse>
                       <cfset astr[n] = axml.XmlChildren[i].XmlText>
                  </cfif>
              </cfif>
          </cfif>
      </cfloop>

      <cfreturn astr>
  </cffunction>


  <!--- Copying Children From One ColdFusion XML Document To Another, Author: Ben Nadel
      Blog Link: https://www.bennadel.com/blog/701-copying-children-from-one-coldfusion-xml-document-to-another.htm --->
  <cffunction name="XmlAppend" access="public" returntype="any" output="false" hint="Copies the children of one node to the node of another document.">
      <cfargument name="NodeA" type="any" required="true" hint="The node whose children will be added to.">
      <cfargument name="NodeB" type="any" required="true" hint="The node whose children will be copied to another document.">

      <cfset var local = {}>

      <!--- Get the child nodes of the originating XML node. This will return both tag nodes and text nodes. We only want the tag nodes. --->
      <cfset local.ChildNodes = arguments.NodeB.GetChildNodes()>

      <!--- Loop over child nodes. --->
      <cfloop index="local.ChildIndex" from="1" to="#local.ChildNodes.GetLength()#" step="1">
          <!---
              Get a short hand to the current node. Remember that the child nodes NodeList starts with index zero.
              Therefore, we must subtract one from out child node index.
          --->
          <cfset local.ChildNode = local.ChildNodes.Item(	JavaCast("int",	(local.ChildIndex - 1) ) )>

          <!---
              Import this noded into the target XML doc. If we do not do this first, then ColdFusion will throw
              an error about us using nodes that are owned by	another document.
              Importing will return a reference to the newly created xml node. The TRUE argument defines this import as DEEP copy.
          --->
          <cfset local.ChildNode = arguments.NodeA.GetOwnerDocument().ImportNode(
              local.ChildNode,
              JavaCast( "boolean", true ) )>

          <!--- Append the imported xml node to the child nodes of the target node. --->
          <cfset arguments.NodeA.AppendChild(	local.ChildNode	)>
      </cfloop>

      <cfreturn arguments.NodeA>
  </cffunction>



</cfcomponent>