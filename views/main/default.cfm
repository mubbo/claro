
<cfoutput>

        <div class="card w-50 mx-auto">
            <div class="card-header">
                <h5>Shopify App - Session lost</h5>
            </div>

            <div class="card-body">
                <div class="js-embedded" hidden>
                    <p  >Your are no longer logged into the app please. Please reload the browser window</p>
                </div>
                <div class="js-not-embedded" hidden>
                    <p>This app is designed to run within shopify please install it through the Shopify <a href="https://apps.shopify.com/official-swiss-post-app" target="_blank">App Store</a> </p>
                </div>
            </div>
        </div>
        <script>
            $(document).ready(function () {
                if (window.isShopifyEmbedded()){
                    $('.js-embedded').removeAttr("hidden");
                }else{
                    $('.js-not-embedded').removeAttr("hidden");
                }
            });
        </script>

    </cfoutput>
<!--- 
    <cfelse>
        <!--- this is the main welcome area when a customer has sucessfully logged in and has set up their subscription --->
        <cfif request.security.getHasMessage()>
            <div class="card w-75 mx-auto  mt-5">
                <div class="card-body">
                    <div class="row align-items-center">
                    #view( 'main/fragment/messages')#
                    </div>
                </div>
            </div>
        </cfif>
        <cfif structKeyExists(rc,"subscription")>
            <div class="card w-75 mx-auto mt-5">
                <div class="card-body">
                    <div class="card-text">
                        <h3 class="text-center">#rc._("subscriptionactivated")#</h3>
                        <p class="lead text-center">#rc._("sub1")#</p>
                    </div>
                </div>
            </div>
        </cfif>
        <div class="card w-75 mx-auto mt-5">
            <div class="card-body">
                <h3 class="text-center">#rc._("gettowork")#</h3>

                <cfif NOT isNull(request.security.getDateUntilTrialEnd()) AND datediff('d',now(),request.security.getDateUntilTrialEnd()) GTE 0>
                    <p class="text-center pt-5">
                        #replaceNoCase(rc._("trialendsdate"),"%date%",lsDateFormat(request.security.getDateUntilTrialEnd(),"medium"))#
                    </p>
                </cfif>
                <p class="text-center pt-5">
                    #rc._("gettowork1")#
                    <cfif request.security.getHasFrankingLicense()>
                    #rc._("gettowork2")#
                    </cfif>
                </p>
            </div>
        </div>

        <cfif (
            not request.security.getHasspidentifier() OR
            not request.security.getHasspSecret())>

            <div class="card w-75 mx-auto mt-5">
                <div class="card-body">
                    <h3 class="text-center">#rc._("completesetup")#</h3>
                    <p class="pt-5">
                        #rc._("completeprofile")#
                        <ul>
                            <cfif not request.security.getHasspidentifier()>
                                <li>#rc._("enterspidentifier")#</li>
                            </cfif>
                            <cfif not request.security.getHasspSecret()>
                                <li>#rc._("enterspsecret")#</li>
                            </cfif>
                            <cfif not request.security.getHasFrankingLicense()>
                                <li>#rc._("frankinglicense")#  (#rc._("requiredforlabels")#)</li>
                            </cfif>
                        </ul>
                    </p>
                    <h3 class="text-center">#rc._("swisspostaccount")#</h3>
                    <p class="pt-5">
                        #rc._("swisspostaccountinfo")#
                    </p>
                </div>
            </div>
        <cfelse>
            <div class="card w-75 mx-auto mt-5">
                <div class="card-body">
                    <h3 class="text-center">#rc._("quicktips")#</h3>
                    <div id="quicktips" class="carousel slide" data-ride="carousel" data-interval="false" data-keyboard="true">
                        <ol class="carousel-indicators">
                            <li data-target="##quicktips" data-slide-to="0" class="active"></li>
                            <li data-target="##quicktips" data-slide-to="1"></li>
                            <li data-target="##quicktips" data-slide-to="2"></li>
                          </ol>
                        <div class="carousel-inner d-flex align-items-center">
                        <div class="carousel-item active">
                            <div class="mx-auto">
                                #rc._("quicktip1")#<Br>
                                <cfoutput><code >#encodeForHTML('<img src="#APPLICATION.general.rootURL#label/get/id/{{id}}/shop/#request.merchant.getShop()#">')#</code><button type="button" class="btn btn-small copyclipboard-btn" data-toggle="tooltip" title="#rc._('copytoclipboard')#"><i class="fa fa-copy"></i></button></cfoutput>
                            </div>
                        </div>
                        <div class="carousel-item">
                            <p>
                                #rc._("quicktip2")#<Br>
                                <cfoutput><code >#encodeForHTML('<img src="#APPLICATION.general.rootURL#return/get/id/{{id}}/shop/#request.merchant.getShop()#">')#</code><button type="button" class="btn btn-small copyclipboard-btn" data-toggle="tooltip" title="#rc._('copytoclipboard')#"><i class="fa fa-copy"></i></button></cfoutput>
                            </p>
                        </div>
                        <div class="carousel-item">
                            <p>
                                #rc._("quicktip3")#<Br>
                            </p>
                        </div>
                        </div>
                        <a class="carousel-control-prev" href="##quicktips" role="button" data-slide="prev">
                            <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                            <span class="sr-only">Previous</span>
                        </a>
                        <a class="carousel-control-next" href="##quicktips" role="button" data-slide="next">
                            <span class="carousel-control-next-icon" aria-hidden="true"></span>
                            <span class="sr-only">Next</span>
                        </a>
                    </div>
                    </div>
            </div>

        </cfif>



    </cfif>

<script>
    <cfoutput>
    $(document).ready(function () {
          $('.copyclipboard-btn').click(function(e){
            copyTextToClipboard($(e.currentTarget).prev().text());
            $(e.currentTarget).tooltip('hide').attr("data-original-title", '#rc._("copiedtoclipboard")#').tooltip('show');
          });
      });
    </cfoutput>
</script> --->