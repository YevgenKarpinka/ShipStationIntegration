codeunit 50001 "ShipStation Mgt."
{
    trigger OnRun()
    begin

    end;

    procedure SetTestMode(_testMode: Boolean)
    begin
        testMode := _testMode;
    end;

    procedure Connect2ShipStation(SPCode: Option " ",getOrder,createOrder,crateLabel; Body2Request: Text; newURL: Text): Text
    var
        TempBlob: Record TempBlob;
        SourceParameters: Record "Source Parameters";
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Client: HttpClient;
        JSText: Text;
        JSObject: JsonObject;
        errMessage: Text;
        errExceptionMessage: Text;
    begin
        if SPCode <> 0 then begin
            SourceParameters.SetRange("FSp Event", SPCode);
            if not SourceParameters.FindSet(false, false) then Error('Need valid Source Parameter Code.\Source Parameter Code = %1 not valid', Format(SPCode));
        end;

        RequestMessage.Method := Format(SourceParameters."FSp RestMethod");
        if newURL = '' then
            RequestMessage.SetRequestUri(newURL)
        else
            RequestMessage.SetRequestUri(SourceParameters."FSp URL");
        RequestMessage.GetHeaders(Headers);
        Headers.Add('Accept', SourceParameters."FSp Accept");
        if (SourceParameters."FSp AuthorizationFrameworkType" = SourceParameters."FSp AuthorizationFrameworkType"::OAuth2)
            and (SourceParameters."FSp AuthorizationToken" <> '') then begin
            TempBlob.WriteAsText(SourceParameters."FSp AuthorizationToken", TextEncoding::Windows);
            Headers.Add('Authorization', TempBlob.ReadTextLine);
        end else
            if SourceParameters."FSp UserName" <> '' then begin
                TempBlob.WriteAsText(StrSubstNo('%1:%2', SourceParameters."FSp UserName", SourceParameters."FSp Password"), TextEncoding::Windows);
                Headers.Add('Authorization', StrSubstNo('Basic %1', TempBlob.ToBase64String()));
            end;

        Headers.Add('If-Match', SourceParameters."FSp ETag");

        if SourceParameters."FSp RestMethod" = SourceParameters."FSp RestMethod"::POST then begin
            RequestMessage.Content.WriteFrom(Body2Request);
            RequestMessage.Content.GetHeaders(Headers);
            if SourceParameters."FSp ContentType" <> 0 then begin
                Headers.Remove('Content-Type');
                Headers.Add('Content-Type', Format(SourceParameters."FSp ContentType"));
            end;
        end;

        Client.Send(RequestMessage, ResponseMessage);
        If not ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content.ReadAs(JSText);
            JSObject.ReadFrom(JSText);
            errMessage := GetJSToken(JSObject, 'Message').AsValue().AsText();
            errExceptionMessage := GetJSToken(JSObject, 'ExceptionMessage').AsValue().AsText();
            Error('Web service returned error:\\Status code: %1\Description: %2\Message: %3\Exception Message: %4\Body Request:\%5',
                ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase(), errMessage, errExceptionMessage, Body2Request);
        end;

        ResponseMessage.Content().ReadAs(JSText);
        exit(JSText);
    end;

    procedure GetOrdersFromShipStation(): Text
    var
        JSText: Text;
        JSObject: JsonObject;
        OrdersJSArray: JsonArray;
        JSLabelText: Label '{"orders":[{"orderNumber":"Test-International-API-DOCS1"},{"orderNumber":"Test-International-API-DOCS2"},{"orderNumber":"Test-International-API-DOCS3"},{"orderNumber":"Test-International-API-DOCS4"}],"total":4,"page":1,"pages":1}';
        JSLabelText1: Label '{"orders":[{"orderId":987654321,"orderNumber":"Test-International-API-DOCS","orderKey":"Test-International-API-DOCS","orderDate":"2015-06-28T17:46:27.0000000","createDate":"2015-08-17T09:24:14.7800000","modifyDate":"2015-08-17T09:24:16.4800000","paymentDate":"2015-06-28T17:46:27.0000000","shipByDate":"2015-07-05T00:00:00.0000000","orderStatus":"awaiting_shipment","customerId":63310475,"customerUsername":"sholmes1854@methodsofdetection.com","customerEmail":"sholmes1854@methodsofdetection.com","billTo":{"name":"SherlockHolmes","company":null,"street1":null,"street2":null,"street3":null,"city":null,"state":null,"postalCode":null,"country":null,"phone":null,"residential":null,"addressVerified":null},"shipTo":{"name":"SherlockHolmes","company":"","street1":"221BBakerSt","street2":"","street3":null,"city":"London","state":"","postalCode":"NW16XE","country":"GB","phone":null,"residential":true,"addressVerified":"Addressnotyetvalidated"},"items":[{"orderItemId":136282568,"lineItemKey":null,"sku":"Ele-1234","name":"ElementaryDisguiseKit","imageUrl":null,"weight":{"value":12,"units":"ounces"},"quantity":2,"unitPrice":49.99,"taxAmount":null,"shippingAmount":null,"warehouseLocation":"Aisle1,Bin7","options":[],"productId":11780610,"fulfillmentSku":"Ele-1234","adjustment":false,"upc":null,"createDate":"2015-08-17T09:24:14.78","modifyDate":"2015-08-17T09:24:14.78"},{"orderItemId":136282569,"lineItemKey":null,"sku":"CN-9876","name":"FineWhiteOakCane","imageUrl":null,"weight":{"value":80,"units":"ounces"},"quantity":1,"unitPrice":225,"taxAmount":null,"shippingAmount":null,"warehouseLocation":"Aisle7,Bin34","options":[],"productId":11780609,"fulfillmentSku":null,"adjustment":false,"upc":null,"createDate":"2015-08-17T09:24:14.78","modifyDate":"2015-08-17T09:24:14.78"}],"orderTotal":387.97,"amountPaid":412.97,"taxAmount":27.99,"shippingAmount":35,"customerNotes":"Pleasebecarefulwhenpackingthedisguisekitsinwiththecane.","internalNotes":"Mr.Holmescalledtoupgradehisshippingtoexpedited","gift":false,"giftMessage":null,"paymentMethod":null,"requestedShippingService":"PriorityMailInt","carrierCode":"stamps_com","serviceCode":"usps_priority_mail_international","packageCode":"package","confirmation":"delivery","shipDate":"2015-04-25","holdUntilDate":null,"weight":{"value":104,"units":"ounces"},"dimensions":{"units":"inches","length":40,"width":7,"height":5},"insuranceOptions":{"provider":null,"insureShipment":false,"insuredValue":0},"internationalOptions":{"contents":"merchandise","customsItems":[{"customsItemId":11558268,"description":"FineWhiteOakCane","quantity":1,"value":225,"harmonizedTariffCode":null,"countryOfOrigin":"US"},{"customsItemId":11558267,"description":"ElementaryDisguiseKit","quantity":2,"value":49.99,"harmonizedTariffCode":null,"countryOfOrigin":"US"}],"nonDelivery":"return_to_sender"},"advancedOptions":{"warehouseId":98765,"nonMachinable":false,"saturdayDelivery":false,"containsAlcohol":false,"mergedOrSplit":false,"mergedIds":[],"parentId":null,"storeId":12345,"customField1":"SKU:CN-9876x1","customField2":"SKU:Ele-123x2","customField3":null,"source":null,"billToParty":null,"billToAccount":null,"billToPostalCode":null,"billToCountryCode":null},"tagIds":null,"userId":null,"externallyFulfilled":false,"externallyFulfilledBy":null},{"orderId":123456789,"orderNumber":"TEST-ORDER-API-DOCS","orderKey":"0f6bec18-9-4771-83aa-f392d84f4c74","orderDate":"2015-06-29T08:46:27.0000000","createDate":"2015-07-16T14:00:34.8230000","modifyDate":"2015-08-17T09:21:59.4430000","paymentDate":"2015-06-29T08:46:27.0000000","shipByDate":"2015-07-05T00:00:00.0000000","orderStatus":"awaiting_shipment","customerId":37701499,"customerUsername":"headhoncho@whitehouse.gov","customerEmail":"headhoncho@whitehouse.gov","billTo":{"name":"ThePresident","company":null,"street1":null,"street2":null,"street3":null,"city":null,"state":null,"postalCode":null,"country":null,"phone":null,"residential":null,"addressVerified":null},"shipTo":{"name":"ThePresident","company":"USGovt","street1":"1600PennsylvaniaAve","street2":"OvalOffice","street3":null,"city":"Washington","state":"DC","postalCode":"20500","country":"US","phone":"555-555-5555","residential":false,"addressVerified":"Addressvalidationwarning"},"items":[{"orderItemId":128836912,"lineItemKey":"vd08-MSLbtx","sku":"ABC123","name":"Testitem#1","imageUrl":null,"weight":{"value":24,"units":"ounces"},"quantity":2,"unitPrice":99.99,"taxAmount":null,"shippingAmount":null,"warehouseLocation":"Aisle1,Bin7","options":[{"name":"Size","value":"Large"}],"productId":7239919,"fulfillmentSku":null,"adjustment":false,"upc":null,"createDate":"2015-07-16T14:00:34.823","modifyDate":"2015-07-16T14:00:34.823"},{"orderItemId":128836913,"lineItemKey":null,"sku":"DISCOUNTCODE","name":"10%OFF","imageUrl":null,"weight":{"value":0,"units":"ounces"},"quantity":1,"unitPrice":-20.55,"taxAmount":null,"shippingAmount":null,"warehouseLocation":null,"options":[],"productId":null,"fulfillmentSku":null,"adjustment":true,"upc":null,"createDate":"2015-07-16T14:00:34.823","modifyDate":"2015-07-16T14:00:34.823"}],"orderTotal":194.43,"amountPaid":218.73,"taxAmount":5,"shippingAmount":10,"customerNotes":"Pleaseshipassoonaspossible!","internalNotes":"Customercalledandwouldliketoupgradeshipping","gift":true,"giftMessage":"Thankyou!","paymentMethod":"CreditCard","requestedShippingService":"PriorityMail","carrierCode":"fedex","serviceCode":"fedex_home_delivery","packageCode":"package","confirmation":"delivery","shipDate":"2015-07-02","holdUntilDate":null,"weight":{"value":48,"units":"ounces"},"dimensions":{"units":"inches","length":7,"width":5,"height":6},"insuranceOptions":{"provider":"carrier","insureShipment":true,"insuredValue":200},"internationalOptions":{"contents":null,"customsItems":null,"nonDelivery":null},"advancedOptions":{"warehouseId":98765,"nonMachinable":false,"saturdayDelivery":false,"containsAlcohol":false,"mergedOrSplit":false,"mergedIds":[],"parentId":null,"storeId":12345,"customField1":"Customdatathatyoucanaddtoanorder.SeeCustomField#2&#3formoreinfo!","customField2":"PerUIsettings,thisinformationcanappearonsomecarriersshippinglabels.Seelinkbelow","customField3":"https://help.shipstation.com/hc/en-us/articles/206639957","source":"Webstore","billToParty":null,"billToAccount":null,"billToPostalCode":null,"billToCountryCode":null},"tagIds":null,"userId":null,"externallyFulfilled":false,"externallyFulfilledBy":null}],"total":2,"page":1,"pages":0}';
        OrderJSToken: JsonToken;
        Counter: Integer;
        txtOrders: Text;
        txtCarrierCode: Text[50];
        txtServiceCode: Text[100];
        _SH: Record "Sales Header";
    begin
        JSText := Connect2ShipStation(1, '', '');
        if testMode then
            // JSText := JSLabelText; // for test
            JSText := JSLabelText1; // for test
        JSObject.ReadFrom(JSText);
        OrdersJSArray := GetJSToken(JSObject, 'orders').AsArray();

        for Counter := 0 to OrdersJSArray.Count - 1 do begin
            OrdersJSArray.Get(Counter, OrderJSToken);
            JSObject := OrderJSToken.AsObject();
            if _SH.Get(_SH."Document Type"::Order, GetJSToken(JSObject, 'orderNumber').AsValue().AsText()) then begin
                UpdateSalesHeaderFromShipStation(_SH."No.", JSObject);

                // txtCarrierCode := CopyStr(GetJSToken(JSObject, 'carrierCode').AsValue().AsText(), 1, MaxStrLen(txtCarrierCode));
                // txtServiceCode := CopyStr(GetJSToken(JSObject, 'serviceCode').AsValue().AsText(), 1, MaxStrLen(txtServiceCode));

                // _SH."ShipStation Order ID" := GetJSToken(JSObject, 'orderId').AsValue().AsInteger();
                // _SH."ShipStation Order Key" := GetJSToken(JSObject, 'orderKey').AsValue().AsText();
                // _SH."Shipping Agent Code" := GetShippingAgent(txtCarrierCode);
                // _SH."Shipping Agent Service Code" := GetShippingAgentService(txtServiceCode, txtCarrierCode);
                // _SH."ShipStation Order Status" := _SH."ShipStation Order Status"::Received;
                // _SH."ShipStation Status" := GetJSToken(JSObject, 'orderStatus').AsValue().AsText();
                _SH.Modify();

                if txtOrders = '' then
                    txtOrders := GetJSToken(JSObject, 'orderNumber').AsValue().AsText()
                else
                    txtOrders += '|' + GetJSToken(JSObject, 'orderNumber').AsValue().AsText();
            end;

        end;
        Message('List of Orders No:\ %1', txtOrders);

        exit(txtOrders);
    end;

    procedure GetOrderFromShipStation(): Text
    var
        JSText: Text;
        JSObject: JsonObject;
        OrdersJSArray: JsonArray;
        OrderJSToken: JsonToken;
        Counter: Integer;
        txtOrders: Text;
        txtCarrierCode: Text[50];
        txtServiceCode: Text[100];
        _SH: Record "Sales Header";
        SourceParameters: Record "Source Parameters";
        SP_Code_Get: Label 'GET';
    begin
        // Get Order from Shipstation to Fill Variables
        SourceParameters.Get(SP_Code_Get);
        JSText := Connect2ShipStation(1, '', StrSubstNo('%1/%2', SourceParameters."FSp URL", _SH."ShipStation Order ID"));

        JSObject.ReadFrom(JSText);

        txtOrders := GetJSToken(JSObject, 'orderNumber').AsValue().AsText();
        if _SH.Get(_SH."Document Type"::Order, GetJSToken(JSObject, 'orderNumber').AsValue().AsText()) then
            UpdateSalesHeaderFromShipStation(_SH."No.", JSObject);

    end;

    local procedure GetShippingAgentService(_ServiceCode: Text[100]; _CarrierCode: Text[50]): Code[10]
    var
        _SAS: Record "Shipping Agent Services";
    begin
        _SAS.SetRange("Shipping Agent Code", _CarrierCode);
        _SAS.SetRange(Description, _ServiceCode);
        if not _SAS.FindSet(false, false) then begin
            exit(CreateShippingAgentService(_ServiceCode, _CarrierCode))
        end else
            exit(_SAS.Code)
    end;

    local procedure CreateShippingAgentService(_ServiceCode: Text[100]; _CarrierCode: Text[50]): code[10]
    var
        _SAS: Record "Shipping Agent Services";
    begin
        with _SAS do begin
            Init();
            "Shipping Agent Code" := _CarrierCode;
            Code := IncStr(GetLastShippingAgentServiceCode);
            Description := _ServiceCode;
            Insert();
            exit(Code);
        end;
    end;

    local procedure GetLastShippingAgentServiceCode(): Code[10]
    var
        _SAS: Record "Shipping Agent Services";
        lblSASCode: Label 'SAS-001';
    begin
        if _SAS.IsEmpty then exit(lblSASCode);
        _SAS.FindLast();
        exit(_SAS.Code);
    end;

    local procedure GetShippingAgent(_CarrierName: Text[50]): Code[10]
    var
        _SA: Record "Shipping Agent";
    begin
        _SA.SetRange(Name, _CarrierName);
        if not _SA.FindSet(false, false) then
            exit(CreateShippingAgent(_CarrierName))
        else
            exit(_SA.Code)
    end;

    local procedure CreateShippingAgent(_CarrierName: Text[50]): code[10]
    var
        _SA: Record "Shipping Agent";
    begin
        with _SA do begin
            Init();
            _SA.Code := IncStr(GetLastShippingAgentCode);
            _SA.Name := _CarrierName;
            Insert();
            exit(Code);
        end;
    end;

    local procedure GetLastShippingAgentCode(): Code[10]
    var
        _SA: Record "Shipping Agent";
        lblSACode: Label 'SA-001';
    begin
        if _SA.IsEmpty then exit(lblSACode);
        _SA.FindLast();
        exit(_SA.Code);
    end;

    procedure CreateOrderInShipStation(DocNo: Code[20]): Boolean
    var
        _SH: Record "Sales Header";
        _Cust: Record Customer;
        JSText: Text;
        JSObjectHeader: JsonObject;
        OrdersJSArray: JsonArray;
        txtAwaitingShipment: Label 'awaiting_shipment';
        txtTest: Label '{"orderNumber":"TEST-ORDER-001","orderKey":"0f6bec18-3e89-4881-83aa-f392d84f4c74","orderDate":"2015-06-29T08:46:27.0000000","paymentDate":"2015-06-29T08:46:27.0000000","shipByDate":"2015-07-05T00:00:00.0000000","orderStatus":"awaiting_shipment","customerId":37701499,"customerUsername":"headhoncho@whitehouse.gov","customerEmail":"headhoncho@whitehouse.gov","billTo":{"name":"ThePresident","company":{},"street1":{},"street2":{},"street3":{},"city":{},"state":{},"postalCode":{},"country":{},"phone":{},"residential":{}},"shipTo":{"name":"ThePresident","company":"USGovt","street1":"1600PennsylvaniaAve","street2":"OvalOffice","street3":{},"city":"Washington","state":"DC","postalCode":"20500","country":"US","phone":"555-555-5555","residential":true},"items":[{"lineItemKey":"vd08-MSLbtx","sku":"ABC123","name":"Testitem#1","imageUrl":{},"weight":{"value":24,"units":"ounces"},"quantity":2,"unitPrice":99.99,"taxAmount":2.5,"shippingAmount":5,"warehouseLocation":"Aisle1,Bin7","options":[{"name":"Size","value":"Large"}],"productId":123456,"fulfillmentSku":{},"adjustment":false,"upc":"32-65-98"},{"lineItemKey":{},"sku":"DISCOUNTCODE","name":"10%OFF","imageUrl":{},"weight":{"value":0,"units":"ounces"},"quantity":1,"unitPrice":-20.55,"taxAmount":{},"shippingAmount":{},"warehouseLocation":{},"options":[],"productId":123456,"fulfillmentSku":"SKU-Discount","adjustment":true,"upc":{}}],"amountPaid":218.73,"taxAmount":5,"shippingAmount":10,"customerNotes":"Pleaseshipassoonaspossible!","internalNotes":"Customercalledandwouldliketoupgradeshipping","gift":true,"giftMessage":"Thankyou!","paymentMethod":"CreditCard","requestedShippingService":"PriorityMail","carrierCode":"fedex","serviceCode":"fedex_2day","packageCode":"package","confirmation":"delivery","shipDate":"2015-07-02","weight":{"value":25,"units":"ounces"},"dimensions":{"units":"inches","length":7,"width":5,"height":6},"insuranceOptions":{"provider":"carrier","insureShipment":true,"insuredValue":200},"internationalOptions":{"contents":{},"customsItems":{}},"advancedOptions":{"warehouseId":98765,"nonMachinable":false,"saturdayDelivery":false,"containsAlcohol":false,"mergedOrSplit":false,"mergedIds":[],"parentId":{},"storeId":12345,"customField1":"Customdatathatyoucanaddtoanorder.SeeCustomField#2&#3formoreinfo!","customField2":"PerUIsettings,thisinformationcanappearonsomecarriersshippinglabels.Seelinkbelow","customField3":"https://help.shipstation.com/hc/en-us/articles/206639957","source":"Webstore","billToParty":{},"billToAccount":{},"billToPostalCode":{},"billToCountryCode":{}},"tagIds":[53974]}';
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) then exit(false);

        _Cust.Get(_SH."Sell-to Customer No.");
        JSObjectHeader.Add('orderNumber', _SH."No.");
        JSObjectHeader.Add('orderDate', Date2Text4JSON(_SH."Posting Date"));
        JSObjectHeader.Add('orderStatus', txtAwaitingShipment);
        JSObjectHeader.Add('customerId', _Cust."No.");
        JSObjectHeader.Add('customerUsername', _Cust."E-Mail");
        JSObjectHeader.Add('customerEmail', _Cust."E-Mail");
        JSObjectHeader.Add('billTo', jsonBillToFromSH(_SH."No."));
        JSObjectHeader.Add('shipTo', jsonShipToFromSH(_SH."No."));
        JSObjectHeader.Add('items', jsonItemsFromSL(_SH."No."));
        Clear(OrdersJSArray);
        JSObjectHeader.Add('tagIds', OrdersJSArray);
        JSObjectHeader.WriteTo(JSText);

        if testMode then begin
            Message(JSText);
            // JSText := txtTest;
        end;

        JSText := Connect2ShipStation(2, JSText, '');
        // update Sales Header from ShipStation
        JSObjectHeader.ReadFrom(JSText);
        UpdateSalesHeaderFromShipStation(DocNo, JSObjectHeader);

    end;

    procedure UpdateSalesHeaderFromShipStation(DocNo: Code[20]; _jsonObject: JsonObject): Boolean
    var
        _SH: Record "Sales Header";
        txtCarrierCode: Text[50];
        txtServiceCode: Text[100];
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) then exit(false);
        // update Sales Header from ShipStation

        txtCarrierCode := CopyStr(GetJSToken(_jsonObject, 'carrierCode').AsValue().AsText(), 1, MaxStrLen(txtCarrierCode));
        txtServiceCode := CopyStr(GetJSToken(_jsonObject, 'serviceCode').AsValue().AsText(), 1, MaxStrLen(txtServiceCode));

        _SH."ShipStation Order ID" := GetJSToken(_jsonObject, 'orderId').AsValue().AsInteger();
        _SH."ShipStation Order Key" := GetJSToken(_jsonObject, 'orderKey').AsValue().AsText();
        _SH."Shipping Agent Code" := GetShippingAgent(txtCarrierCode);
        _SH."Shipping Agent Service Code" := GetShippingAgentService(txtServiceCode, txtCarrierCode);
        _SH."ShipStation Status" := CopyStr(GetJSToken(_jsonObject, 'orderStatus').AsValue().AsText(), 1, MaxStrLen(_SH."ShipStation Status"));
        _SH."ShipStation Order Status" := _SH."ShipStation Order Status"::Sent;
        _SH.Modify();
    end;

    procedure CreateLabel2OrderInShipStation(DocNo: Code[20]): Boolean
    var
        _SH: Record "Sales Header";
        SourceParameters: Record "Source Parameters";
        JSText: Text;
        txtOrderNo: Text;
        JSObject: JsonObject;
        jsLabelObject: JsonObject;
        OrdersJSArray: JsonArray;
        OrderJSToken: JsonToken;
        Counter: Integer;
        notExistOrdersList: Text;
        OrdersListCreateLabel: Text;
        OrdersCancelled: Text;
        txtLabel: Text;
        WhseShipDocNo: Code[20];
        txtTest: Label '{"orders":[{"orderId":987654321,"orderNumber":"TEST-INTERNATIONAL","orderKey":"Test-International-API-DOCS","orderDate":"2015-06-28T17:46:27.0000000","createDate":"2015-08-17T09:24:14.7800000","modifyDate":"2015-08-17T09:24:16.4800000","paymentDate":"2015-06-28T17:46:27.0000000","shipByDate":"2015-07-05T00:00:00.0000000","orderStatus":"awaiting_shipment","customerId":63310475,"customerUsername":"sholmes1854@methodsofdetection.com","customerEmail":"sholmes1854@methodsofdetection.com","billTo":{"name":"SherlockHolmes","company":{},"street1":{},"street2":{},"street3":{},"city":{},"state":{},"postalCode":{},"country":{},"phone":{},"residential":{},"addressVerified":{}},"shipTo":{"name":"SherlockHolmes","company":"","street1":"221BBakerSt","street2":"","street3":{},"city":"London","state":"","postalCode":"NW16XE","country":"GB","phone":{},"residential":true,"addressVerified":"Addressnotyetvalidated"},"items":[{"orderItemId":136282568,"lineItemKey":{},"sku":"Ele-1234","name":"ElementaryDisguiseKit","imageUrl":{},"weight":{"value":12,"units":"ounces"},"quantity":2,"unitPrice":49.99,"taxAmount":{},"shippingAmount":{},"warehouseLocation":"Aisle1,Bin7","options":[],"productId":11780610,"fulfillmentSku":"Ele-1234","adjustment":false,"upc":{},"createDate":"2015-08-17T09:24:14.78","modifyDate":"2015-08-17T09:24:14.78"},{"orderItemId":136282569,"lineItemKey":{},"sku":"CN-9876","name":"FineWhiteOakCane","imageUrl":{},"weight":{"value":80,"units":"ounces"},"quantity":1,"unitPrice":225,"taxAmount":{},"shippingAmount":{},"warehouseLocation":"Aisle7,Bin34","options":[],"productId":11780609,"fulfillmentSku":{},"adjustment":false,"upc":{},"createDate":"2015-08-17T09:24:14.78","modifyDate":"2015-08-17T09:24:14.78"}],"orderTotal":387.97,"amountPaid":412.97,"taxAmount":27.99,"shippingAmount":35,"customerNotes":"Pleasebecarefulwhenpackingthedisguisekitsinwiththecane.","internalNotes":"Mr.Holmescalledtoupgradehisshippingtoexpedited","gift":false,"giftMessage":{},"paymentMethod":{},"requestedShippingService":"PriorityMailInt","carrierCode":"stamps_com","serviceCode":"usps_priority_mail_international","packageCode":"package","confirmation":"delivery","shipDate":"2015-04-25","holdUntilDate":{},"weight":{"value":104,"units":"ounces"},"dimensions":{"units":"inches","length":40,"width":7,"height":5},"insuranceOptions":{"provider":{},"insureShipment":false,"insuredValue":0},"internationalOptions":{"contents":"merchandise","customsItems":[{"customsItemId":11558268,"description":"FineWhiteOakCane","quantity":1,"value":225,"harmonizedTariffCode":{},"countryOfOrigin":"US"},{"customsItemId":11558267,"description":"ElementaryDisguiseKit","quantity":2,"value":49.99,"harmonizedTariffCode":{},"countryOfOrigin":"US"}],"nonDelivery":"return_to_sender"},"advancedOptions":{"warehouseId":98765,"nonMachinable":false,"saturdayDelivery":false,"containsAlcohol":false,"mergedOrSplit":false,"mergedIds":[],"parentId":{},"storeId":12345,"customField1":"SKU:CN-9876x1","customField2":"SKU:Ele-123x2","customField3":{},"source":{},"billToParty":{},"billToAccount":{},"billToPostalCode":{},"billToCountryCode":{}},"tagIds":{},"userId":{},"externallyFulfilled":false,"externallyFulfilledBy":{}},{"orderId":123456789,"orderNumber":"TEST-ORDER-API-DOCS","orderKey":"0f6bec18-9-4771-83aa-f392d84f4c74","orderDate":"2015-06-29T08:46:27.0000000","createDate":"2015-07-16T14:00:34.8230000","modifyDate":"2015-08-17T09:21:59.4430000","paymentDate":"2015-06-29T08:46:27.0000000","shipByDate":"2015-07-05T00:00:00.0000000","orderStatus":"awaiting_shipment","customerId":37701499,"customerUsername":"headhoncho@whitehouse.gov","customerEmail":"headhoncho@whitehouse.gov","billTo":{"name":"ThePresident","company":{},"street1":{},"street2":{},"street3":{},"city":{},"state":{},"postalCode":{},"country":{},"phone":{},"residential":{},"addressVerified":{}},"shipTo":{"name":"ThePresident","company":"USGovt","street1":"1600PennsylvaniaAve","street2":"OvalOffice","street3":{},"city":"Washington","state":"DC","postalCode":"20500","country":"US","phone":"555-555-5555","residential":false,"addressVerified":"Addressvalidationwarning"},"items":[{"orderItemId":128836912,"lineItemKey":"vd08-MSLbtx","sku":"ABC123","name":"Testitem#1","imageUrl":{},"weight":{"value":24,"units":"ounces"},"quantity":2,"unitPrice":99.99,"taxAmount":{},"shippingAmount":{},"warehouseLocation":"Aisle1,Bin7","options":[{"name":"Size","value":"Large"}],"productId":7239919,"fulfillmentSku":{},"adjustment":false,"upc":{},"createDate":"2015-07-16T14:00:34.823","modifyDate":"2015-07-16T14:00:34.823"},{"orderItemId":128836913,"lineItemKey":{},"sku":"DISCOUNTCODE","name":"10%OFF","imageUrl":{},"weight":{"value":0,"units":"ounces"},"quantity":1,"unitPrice":-20.55,"taxAmount":{},"shippingAmount":{},"warehouseLocation":{},"options":[],"productId":{},"fulfillmentSku":{},"adjustment":true,"upc":{},"createDate":"2015-07-16T14:00:34.823","modifyDate":"2015-07-16T14:00:34.823"}],"orderTotal":194.43,"amountPaid":218.73,"taxAmount":5,"shippingAmount":10,"customerNotes":"Pleaseshipassoonaspossible!","internalNotes":"Customercalledandwouldliketoupgradeshipping","gift":true,"giftMessage":"Thankyou!","paymentMethod":"CreditCard","requestedShippingService":"PriorityMail","carrierCode":"fedex","serviceCode":"fedex_home_delivery","packageCode":"package","confirmation":"delivery","shipDate":"2015-07-02","holdUntilDate":{},"weight":{"value":48,"units":"ounces"},"dimensions":{"units":"inches","length":7,"width":5,"height":6},"insuranceOptions":{"provider":"carrier","insureShipment":true,"insuredValue":200},"internationalOptions":{"contents":{},"customsItems":{},"nonDelivery":{}},"advancedOptions":{"warehouseId":98765,"nonMachinable":false,"saturdayDelivery":false,"containsAlcohol":false,"mergedOrSplit":false,"mergedIds":[],"parentId":{},"storeId":12345,"customField1":"Customdatathatyoucanaddtoanorder.SeeCustomField#2&#3formoreinfo!","customField2":"PerUIsettings,thisinformationcanappearonsomecarriersshippinglabels.Seelinkbelow","customField3":"https://help.shipstation.com/hc/en-us/articles/206639957","source":"Webstore","billToParty":{},"billToAccount":{},"billToPostalCode":{},"billToCountryCode":{}},"tagIds":{},"userId":{},"externallyFulfilled":false,"externallyFulfilledBy":{}}],"total":2,"page":1,"pages":0}';
        txtTestLabel: Label '{"shipmentId":72513480,"shipmentCost":7.3,"insuranceCost":0,"trackingNumber":"248201115029520","labelData":"JVBERi0xLjQKJeLjz9MKMiAwIG9iago8PC9MZW5ndGggNjIvRmlsdGVyL0ZsYXRlRGVjb2RlPj5zdHJlYW0KeJwr5HIK4TI2UzC2NFMISeFyDeEK5CpUMFQwAEJDBV0jCz0LBV1jY0M9I4XkXAX9iDRDBZd8hUAuAEdGC7cKZW5kc3RyZWFtCmVuZG9iago0IDAgb2JqCjw8L1R5cGUvUGFnZS9NZWRpYUJveFswIDAgMjg4IDQzMl0vUmVzb3VyY2VzPDwvUHJvY1NldCBbL1BERiAvVGV4dCAvSW1hZ2VCIC9JbWFnZUMgL0ltYWdlSV0vWE9iamVjdDw8L1hmMSAxIDAgUj4+Pj4vQ29udGVudHMgMiAwIFIvUGFyZW50","formData":null}';
        txtLabelBase64: Label 'JVBERi0xLjQKJeLjz9MKMiAwIG9iago8PC9MZW5ndGggNjIvRmlsdGVyL0ZsYXRlRGVjb2RlPj5zdHJlYW0KeJwr5HIK4TI2UzC2NFMISeFyDeEK5CpUMFQwAEJDBV0jCz0LBV1jY0M9I4XkXAX9iDRDBZd8hUAuAEdGC7cKZW5kc3RyZWFtCmVuZG9iago0IDAgb2JqCjw8L1R5cGUvUGFnZS9NZWRpYUJveFswIDAgMjg4IDQzMl0vUmVzb3VyY2VzPDwvUHJvY1NldCBbL1BERiAvVGV4dCAvSW1hZ2VCIC9JbWFnZUMgL0ltYWdlSV0vWE9iamVjdDw8L1hmMSAxIDAgUj4+Pj4vQ29udGVudHMgMiAwIFIvUGFyZW50Li4uLg';
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) or (_SH."ShipStation Order ID" = 0) then exit(false);

        SourceParameters.SetRange("FSp Event", 1);
        SourceParameters.FindFirst();

        // Get Order from Shipstation to Fill Variables
        JSText := Connect2ShipStation(1, '', StrSubstNo('%1/%2', SourceParameters."FSp URL", _SH."ShipStation Order ID"));

        JSObject.ReadFrom(JSText);

        txtOrderNo := GetJSToken(JSObject, 'orderNumber').AsValue().AsText();

        // Fill Token from Order
        if testMode then begin
            Message('Counter - %1\JSText:\%2', Counter, FillValuesFromOrder(JSObject));
            JSText := txtTestLabel;
            jsLabelObject.ReadFrom(JSText);
            txtLabel := GetJSToken(jsLabelObject, 'labelData').AsValue().AsText();
            WhseShipDocNo := '111';
            txtLabel := txtLabelBase64;
            AddLabel2Shipment(txtLabel, WhseShipDocNo);
        end else begin
            // Create Label to Order
            JSText := Connect2ShipStation(3, FillValuesFromOrder(JSObject), '');
            if JSText <> '' then begin
                FindWarehouseSipment(DocNo, WhseShipDocNo);
                // Add Lable to Shipment
                jsLabelObject.ReadFrom(JSText);
                txtLabel := GetJSToken(jsLabelObject, 'labelData').AsValue().AsText();
                AddLabel2Shipment(txtLabel, WhseShipDocNo);
            end;
        end;
        Message('Label Created and Attached to Shipment!');
    end;

    local procedure FindWarehouseSipment(_DocNo: Code[20]; var _WhseShipDcoNo: Code[20])
    var
        WhseShipLine: Record "Warehouse Shipment Line";
    begin
        with WhseShipLine do begin
            SetRange("Source Type", Database::"Sales Header");
            SetRange("Source Subtype", 1);
            SetRange("Source No.", _DocNo);
            FindFirst();
            _WhseShipDcoNo := "No.";
        end;
    end;

    local procedure AddLabel2Shipment(_txtLabelBase64: Text; _WhseShipDocNo: Code[20])
    var
        TempBlob: Record TempBlob;
        WhseShipHeader: Record "Warehouse Shipment Header";
        lblOrder: TextConst ENU = 'labelWhseShmt', RUS = 'labelWhseShmt';
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileName: Text;
    begin
        WhseShipHeader.Get(_WhseShipDocNo);
        TempBlob.FromBase64String(_txtLabelBase64);
        FileName := StrSubstNo('%1-%2-%3.pdf', lblOrder, WhseShipHeader."No.", WhseShipHeader."Posting Date");
        with IncomingDocumentAttachment do begin
            SetRange("Incoming Document Entry No.", GetLastIncomingDocumentEntryNo);
            SetRange("Document No.", WhseShipHeader."No.");
            SetRange("Posting Date", WhseShipHeader."Posting Date");
            Content := TempBlob.Blob;
        end;
        ImportAttachment(IncomingDocumentAttachment, FileName, TempBlob);
    end;

    local procedure GetLastIncomingDocumentEntryNo(): Integer
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.FindLast();
        exit(IncomingDocumentAttachment."Incoming Document Entry No." + 1);
    end;

    local procedure ImportAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; FileName: Text; _TempBlob: Record TempBlob): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        WhseShipHeader: Record "Warehouse Shipment Header";
        FileManagement: Codeunit "File Management";
        PostingDate: Date;
        DocNo: Code[20];
    begin
        WITH IncomingDocumentAttachment DO BEGIN
            DocNo := GetFilter("Document No.");

            WhseShipHeader.Get(DocNo);
            WhseShipHeader.SetRange("No.", DocNo);
            WhseShipHeader.SetRange("Posting Date", WhseShipHeader."Posting Date");

            CreateIncomingDocument(IncomingDocumentAttachment, IncomingDocument, PostingDate, DocNo, WhseShipHeader.RecordId);
            IF IncomingDocument.Status IN [IncomingDocument.Status::"Pending Approval", IncomingDocument.Status::Failed] THEN
                IncomingDocument.TESTFIELD(Status, IncomingDocument.Status::New);
            "Incoming Document Entry No." := IncomingDocument."Entry No.";
            "Line No." := GetIncomingDocumentNextLineNo(IncomingDocument);
            Content := _TempBlob.Blob;

            VALIDATE("File Extension", LOWERCASE(COPYSTR(FileManagement.GetExtension(FileName), 1, MAXSTRLEN("File Extension"))));
            IF Name = '' THEN
                Name := COPYSTR(FileManagement.GetFileNameWithoutExtension(FileName), 1, MAXSTRLEN(Name));

            "Document No." := IncomingDocument."Document No.";
            "Posting Date" := IncomingDocument."Posting Date";
            IF IncomingDocument.Description = '' THEN BEGIN
                IncomingDocument.Description := COPYSTR(Name, 1, MAXSTRLEN(IncomingDocument.Description));
                IncomingDocument.MODIFY;
            END;

            INSERT(TRUE);

            // IF Type IN [Type::Image, Type::PDF] THEN
            //     OnAttachBinaryFile;
        END;
        EXIT(TRUE);
    end;

    local procedure CreateIncomingDocument(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"; PostingDate: Date; DocNo: Code[20]; RelatedRecordID: RecordID)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RelatedRecordRef: RecordRef;
        RelatedRecord: Variant;
    begin
        IncomingDocument.CreateIncomingDocument('', '');
        IncomingDocument."Document Type" := IncomingDocument."Document Type"::Journal;
        if RelatedRecordID.TableNo = 0 then
            if IncomingDocument.GetRecord(RelatedRecord) then
                if DataTypeManagement.GetRecordRef(RelatedRecord, RelatedRecordRef) then
                    RelatedRecordID := RelatedRecordRef.RecordId;
        IncomingDocument."Related Record ID" := RelatedRecordID;
        if IncomingDocument."Document Type" <> IncomingDocument."Document Type"::" " then begin
            if IncomingDocument.Posted then
                IncomingDocument.Status := IncomingDocument.Status::Posted
            else
                IncomingDocument.Status := IncomingDocument.Status::Created;
            IncomingDocument.Released := true;
            IncomingDocument."Released Date-Time" := CurrentDateTime;
            IncomingDocument."Released By User ID" := UserSecurityId;
            IncomingDocument."Document No." := IncomingDocumentAttachment.GetRangeMin("Document No.");
            IncomingDocument."Posting Date" := IncomingDocumentAttachment.GetRangeMin("Posting Date");
        end;
        IncomingDocument.Modify;
    end;

    local procedure GetIncomingDocumentNextLineNo(IncomingDocument: Record "Incoming Document"): Integer
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        with IncomingDocumentAttachment do begin
            SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
            if FindLast then;
            exit("Line No." + LineIncrement);
        end;
    end;

    local procedure LineIncrement(): Integer
    begin
        exit(10000);
    end;

    local procedure CreateListAsFilter(var _List: Text; _subString: Text)
    begin
        if _List = '' then
            _List += _subString
        else
            _List += '|' + _subString;
    end;

    local procedure FillValuesFromOrder(_JSObject: JsonObject): Text
    var
        JSObjectHeader: JsonObject;
        JSText: Text;
    begin
        JSObjectHeader.Add('orderId', GetJSToken(_JSObject, 'orderId').AsValue().AsInteger());
        JSObjectHeader.Add('carrierCode', GetJSToken(_JSObject, 'carrierCode').AsValue().AsText());
        JSObjectHeader.Add('serviceCode', GetJSToken(_JSObject, 'serviceCode').AsValue().AsText());
        JSObjectHeader.Add('packageCode', GetJSToken(_JSObject, 'packageCode').AsValue().AsText());
        JSObjectHeader.Add('confirmation', GetJSToken(_JSObject, 'confirmation').AsValue().AsText());
        JSObjectHeader.Add('shipDate', GetJSToken(_JSObject, 'shipDate').AsValue().AsText());
        JSObjectHeader.Add('weight', GetJSToken(_JSObject, 'weight').AsObject());
        JSObjectHeader.Add('dimensions', GetJSToken(_JSObject, 'dimensions').AsObject());
        JSObjectHeader.Add('insuranceOptions', GetJSToken(_JSObject, 'insuranceOptions').AsObject());
        JSObjectHeader.Add('internationalOptions', GetJSToken(_JSObject, 'internationalOptions').AsObject());
        JSObjectHeader.Add('advancedOptions', GetJSToken(_JSObject, 'advancedOptions').AsObject());
        JSObjectHeader.Add('testLabel', true); // only for testing
        JSObjectHeader.WriteTo(JSText);
        Message(JSText);
        exit(JSText);
    end;

    procedure jsonBillToFromSH(DocNo: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        txtBillTo: Text;
        _SH: Record "Sales Header";
        _Cust: Record Customer;
    begin
        _SH.Get(_SH."Document Type"::Order, DocNo);
        _Cust.Get(_SH."Bill-to Customer No.");
        JSObjectLine.Add('name', _Cust.Name);
        JSObjectLine.Add('company', '');
        JSObjectLine.Add('street1', '');
        JSObjectLine.Add('street2', '');
        JSObjectLine.Add('street3', '');
        JSObjectLine.Add('city', '');
        JSObjectLine.Add('state', '');
        JSObjectLine.Add('postalCode', '');
        JSObjectLine.Add('country', '');
        JSObjectLine.Add('phone', '');
        JSObjectLine.Add('residential', '');
        exit(JSObjectLine);
    end;

    procedure jsonShipToFromSH(DocNo: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        txtShipTo: Text;
        _SH: Record "Sales Header";
        _Cust: Record Customer;
    begin
        _SH.Get(_SH."Document Type"::Order, DocNo);
        _Cust.Get(_SH."Sell-to Customer No.");
        JSObjectLine.Add('name', _SH."Sell-to Customer Name");
        JSObjectLine.Add('company', '');
        JSObjectLine.Add('street1', _SH."Ship-to Address");
        JSObjectLine.Add('street2', '');
        JSObjectLine.Add('street3', '');
        JSObjectLine.Add('city', _SH."Ship-to City");
        JSObjectLine.Add('state', '');
        JSObjectLine.Add('postalCode', _SH."Ship-to Post Code");
        JSObjectLine.Add('country', _SH."Ship-to Country/Region Code");
        JSObjectLine.Add('phone', _Cust."Phone No.");
        JSObjectLine.Add('residential', false);
        exit(JSObjectLine);
    end;

    procedure jsonItemsFromSL(DocNo: Code[20]): JsonArray
    var
        JSObjectLine: JsonObject;
        JSObjectArray: JsonArray;
        txtItem: Text;
        _SL: Record "Sales Line";
    begin
        _SL.SetRange("Document Type", _SL."Document Type"::Order);
        _SL.SetRange("Document No.", DocNo);
        _SL.SetRange(Type, _SL.Type::Item);
        _SL.SetFilter(Quantity, '<>%1', 0);
        if _SL.FindSet(false, false) then
            repeat
                Clear(JSObjectLine);
                JSObjectLine.Add('lineItemKey', _SL."Line No.");
                JSObjectLine.Add('sku', _SL."No.");
                JSObjectLine.Add('name', _SL.Description);
                JSObjectLine.Add('imageUrl', '');
                JSObjectLine.Add('weight', jsonWeightFromItem(_SL."No."));
                JSObjectLine.Add('quantity', Decimal2Integer(_SL.Quantity));
                JSObjectLine.Add('unitPrice', Round(_SL."Amount Including VAT" / _SL.Quantity, 0.01));
                JSObjectLine.Add('taxAmount', Round((_SL."Amount Including VAT" - _SL.Amount) / _SL.Quantity, 0.01));
                // JSObjectLine.Add('shippingAmount', 0);
                JSObjectLine.Add('warehouseLocation', _SL."Location Code");
                JSObjectLine.Add('productId', _SL."Line No.");
                JSObjectLine.Add('fulfillmentSku', '');
                JSObjectLine.Add('adjustment', false);
                JSObjectArray.Add(JSObjectLine);
            until _SL.Next() = 0;
        exit(JSObjectArray);
    end;

    local procedure Decimal2Integer(_Decimal: Decimal): Integer
    begin
        exit(Round(_Decimal, 1));
    end;

    procedure jsonWeightFromItem(ItemNo: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        txtWeight: Text;
        _Item: Record Item;
    begin
        _Item.Get(ItemNo);
        JSObjectLine.Add('value', _Item."Gross Weight");
        JSObjectLine.Add('units', 'grams');
        exit(JSObjectLine);
    end;

    procedure GetJSToken(_JSONObject: JsonObject; TokenKey: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.Get(TokenKey, _JSONToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    procedure SelectJSToken(_JSONObject: JsonObject; Path: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.SelectToken(Path, _JSONToken) then
            Error('Could not find a token with path %1', Path);
    end;

    local procedure GetDateFromJsonText(_DateText: Text): Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        EVALUATE(Year, COPYSTR(_DateText, 1, 4));
        EVALUATE(Month, COPYSTR(_DateText, 6, 2));
        EVALUATE(Day, COPYSTR(_DateText, 9, 2));
        EXIT(DMY2DATE(Day, Month, Year));
    end;

    local procedure Date2Text4JSON(_Date: Date): Text
    var
        _Year: Text[4];
        _Month: Text[2];
        _Day: Text[2];
    begin
        EVALUATE(_Day, Format(Date2DMY(_Date, 1)));
        AddZero2String(_Day, 2);
        EVALUATE(_Month, Format(Date2DMY(_Date, 2)));
        AddZero2String(_Month, 2);
        EVALUATE(_Year, Format(Date2DMY(_Date, 3)));
        EXIT(_Year + '-' + _Month + '-' + _Day + 'T00:00:00.0000000');
    end;

    local procedure AddZero2String(var _String: Text; _maxLenght: Integer)
    begin
        while _maxLenght > StrLen(_String) do
            _String := StrSubstNo('%1%2', '0', _String);
    end;

    var
        testMode: Boolean;
}