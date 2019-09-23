codeunit 50001 "ShipStation Mgt."
{
    trigger OnRun()
    begin

    end;

    procedure SetTestMode(_testMode: Boolean)
    begin
        testMode := _testMode;
    end;

    procedure Connect2ShipStation(SPCode: code[20]; TextForRequest: Text): Text
    var
        TempBlob: Record TempBlob;
        SourceParameters: Record "Source Parameters";
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        Client: HttpClient;
        JSText: Text;
    begin
        if SPCode <> '' then
            if not SourceParameters.Get(SPCode) then Error('Need valid Source Parameter Code.\Source Parameter Code = % not valid', SPCode);

        RequestMessage.Method := Format(SourceParameters."FSp RestMethod");
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
            Content.WriteFrom(TextForRequest);
            RequestMessage.Content := Content;

            Content.GetHeaders(Headers);
            if SourceParameters."FSp ContentType" <> 0 then begin
                Headers.Remove('Content-Type');
                Headers.Add('Content-Type', Format(SourceParameters."FSp ContentType"));
            end;
        end;

        Client.Send(RequestMessage, ResponseMessage);
        Content := ResponseMessage.Content;
        if Content.ReadAs(JSText) then
            exit(JSText);

        exit('');
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
    begin
        JSText := Connect2ShipStation('GETORDERS', '');
        if JSText = '' then Error('Connection to ShipStation API failed');
        Message('Response Text - %1', JSText);

        // JSText := JSLabelText; // for test
        JSText := JSLabelText1; // for test

        JSObject.ReadFrom(JSText);
        // Message('Total Orders - %1', GetJSToken(JSObject, 'total').AsValue().AsText());

        OrdersJSArray := GetJSToken(JSObject, 'orders').AsArray();
        // Message('Orders No - %1', OrdersJSArray.Count);

        for Counter := 0 to OrdersJSArray.Count - 1 do begin
            OrdersJSArray.Get(Counter, OrderJSToken);
            JSObject := OrderJSToken.AsObject();
            if txtOrders = '' then
                txtOrders := GetJSToken(JSObject, 'orderNumber').AsValue().AsText()
            else
                txtOrders += '|' + GetJSToken(JSObject, 'orderNumber').AsValue().AsText();
        end;
        Message('List of Orders No:\ %1', txtOrders);

        exit(txtOrders);
    end;

    procedure CreateOrderInShipStation(DocNo: Code[20]): Boolean
    var
        _SH: Record "Sales Header";
        JSText: Text;
        JSObjectHeader: JsonObject;
        OrdersJSArray: JsonArray;
        txtAwaitingShipment: Label 'awaiting_shipment';
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) then exit(false);

        JSObjectHeader.Add('orderNumber', _SH."No.");
        JSObjectHeader.Add('orderDate', Date2Text4JSON(_SH."Posting Date"));
        JSObjectHeader.Add('orderStatus', txtAwaitingShipment);
        JSObjectHeader.Add('billTo', jsonBillToFromSH(_SH."No."));
        JSObjectHeader.Add('shipTo', jsonShipToFromSH(_SH."No."));
        JSObjectHeader.Add('items', jsonItemsFromSL(_SH."No."));
        JSObjectHeader.Add('tagIds', '');
        JSObjectHeader.Add('userId', '');
        JSObjectHeader.Add('externallyFulfilled', false);
        JSObjectHeader.Add('externallyFulfilledBy', '');
        JSObjectHeader.WriteTo(JSText);
        if testMode then
            Message(JSText)
        else
            Connect2ShipStation('', JSText);

    end;

    procedure CreateLabel2OrderInShipStation(DocNo: Code[20]): Boolean
    var
        _SH: Record "Sales Header";
        JSText: Text;
        txtOrders: Text;
        JSObject: JsonObject;
        JSObjectHeader: JsonObject;
        OrdersJSArray: JsonArray;
        OrderJSToken: JsonToken;
        Counter: Integer;
        txtTest: Label '{"orders":[{"orderId":987654321,"orderNumber":"Test-International-API-DOCS","orderKey":"Test-International-API-DOCS","orderDate":"2015-06-28T17:46:27.0000000","createDate":"2015-08-17T09:24:14.7800000","modifyDate":"2015-08-17T09:24:16.4800000","paymentDate":"2015-06-28T17:46:27.0000000","shipByDate":"2015-07-05T00:00:00.0000000","orderStatus":"awaiting_shipment","customerId":63310475,"customerUsername":"sholmes1854@methodsofdetection.com","customerEmail":"sholmes1854@methodsofdetection.com","billTo":{"name":"SherlockHolmes","company":{},"street1":{},"street2":{},"street3":{},"city":{},"state":{},"postalCode":{},"country":{},"phone":{},"residential":{},"addressVerified":{}},"shipTo":{"name":"SherlockHolmes","company":"","street1":"221BBakerSt","street2":"","street3":{},"city":"London","state":"","postalCode":"NW16XE","country":"GB","phone":{},"residential":true,"addressVerified":"Addressnotyetvalidated"},"items":[{"orderItemId":136282568,"lineItemKey":{},"sku":"Ele-1234","name":"ElementaryDisguiseKit","imageUrl":{},"weight":{"value":12,"units":"ounces"},"quantity":2,"unitPrice":49.99,"taxAmount":{},"shippingAmount":{},"warehouseLocation":"Aisle1,Bin7","options":[],"productId":11780610,"fulfillmentSku":"Ele-1234","adjustment":false,"upc":{},"createDate":"2015-08-17T09:24:14.78","modifyDate":"2015-08-17T09:24:14.78"},{"orderItemId":136282569,"lineItemKey":{},"sku":"CN-9876","name":"FineWhiteOakCane","imageUrl":{},"weight":{"value":80,"units":"ounces"},"quantity":1,"unitPrice":225,"taxAmount":{},"shippingAmount":{},"warehouseLocation":"Aisle7,Bin34","options":[],"productId":11780609,"fulfillmentSku":{},"adjustment":false,"upc":{},"createDate":"2015-08-17T09:24:14.78","modifyDate":"2015-08-17T09:24:14.78"}],"orderTotal":387.97,"amountPaid":412.97,"taxAmount":27.99,"shippingAmount":35,"customerNotes":"Pleasebecarefulwhenpackingthedisguisekitsinwiththecane.","internalNotes":"Mr.Holmescalledtoupgradehisshippingtoexpedited","gift":false,"giftMessage":{},"paymentMethod":{},"requestedShippingService":"PriorityMailInt","carrierCode":"stamps_com","serviceCode":"usps_priority_mail_international","packageCode":"package","confirmation":"delivery","shipDate":"2015-04-25","holdUntilDate":{},"weight":{"value":104,"units":"ounces"},"dimensions":{"units":"inches","length":40,"width":7,"height":5},"insuranceOptions":{"provider":{},"insureShipment":false,"insuredValue":0},"internationalOptions":{"contents":"merchandise","customsItems":[{"customsItemId":11558268,"description":"FineWhiteOakCane","quantity":1,"value":225,"harmonizedTariffCode":{},"countryOfOrigin":"US"},{"customsItemId":11558267,"description":"ElementaryDisguiseKit","quantity":2,"value":49.99,"harmonizedTariffCode":{},"countryOfOrigin":"US"}],"nonDelivery":"return_to_sender"},"advancedOptions":{"warehouseId":98765,"nonMachinable":false,"saturdayDelivery":false,"containsAlcohol":false,"mergedOrSplit":false,"mergedIds":[],"parentId":{},"storeId":12345,"customField1":"SKU:CN-9876x1","customField2":"SKU:Ele-123x2","customField3":{},"source":{},"billToParty":{},"billToAccount":{},"billToPostalCode":{},"billToCountryCode":{}},"tagIds":{},"userId":{},"externallyFulfilled":false,"externallyFulfilledBy":{}},{"orderId":123456789,"orderNumber":"TEST-ORDER-API-DOCS","orderKey":"0f6bec18-9-4771-83aa-f392d84f4c74","orderDate":"2015-06-29T08:46:27.0000000","createDate":"2015-07-16T14:00:34.8230000","modifyDate":"2015-08-17T09:21:59.4430000","paymentDate":"2015-06-29T08:46:27.0000000","shipByDate":"2015-07-05T00:00:00.0000000","orderStatus":"awaiting_shipment","customerId":37701499,"customerUsername":"headhoncho@whitehouse.gov","customerEmail":"headhoncho@whitehouse.gov","billTo":{"name":"ThePresident","company":{},"street1":{},"street2":{},"street3":{},"city":{},"state":{},"postalCode":{},"country":{},"phone":{},"residential":{},"addressVerified":{}},"shipTo":{"name":"ThePresident","company":"USGovt","street1":"1600PennsylvaniaAve","street2":"OvalOffice","street3":{},"city":"Washington","state":"DC","postalCode":"20500","country":"US","phone":"555-555-5555","residential":false,"addressVerified":"Addressvalidationwarning"},"items":[{"orderItemId":128836912,"lineItemKey":"vd08-MSLbtx","sku":"ABC123","name":"Testitem#1","imageUrl":{},"weight":{"value":24,"units":"ounces"},"quantity":2,"unitPrice":99.99,"taxAmount":{},"shippingAmount":{},"warehouseLocation":"Aisle1,Bin7","options":[{"name":"Size","value":"Large"}],"productId":7239919,"fulfillmentSku":{},"adjustment":false,"upc":{},"createDate":"2015-07-16T14:00:34.823","modifyDate":"2015-07-16T14:00:34.823"},{"orderItemId":128836913,"lineItemKey":{},"sku":"DISCOUNTCODE","name":"10%OFF","imageUrl":{},"weight":{"value":0,"units":"ounces"},"quantity":1,"unitPrice":-20.55,"taxAmount":{},"shippingAmount":{},"warehouseLocation":{},"options":[],"productId":{},"fulfillmentSku":{},"adjustment":true,"upc":{},"createDate":"2015-07-16T14:00:34.823","modifyDate":"2015-07-16T14:00:34.823"}],"orderTotal":194.43,"amountPaid":218.73,"taxAmount":5,"shippingAmount":10,"customerNotes":"Pleaseshipassoonaspossible!","internalNotes":"Customercalledandwouldliketoupgradeshipping","gift":true,"giftMessage":"Thankyou!","paymentMethod":"CreditCard","requestedShippingService":"PriorityMail","carrierCode":"fedex","serviceCode":"fedex_home_delivery","packageCode":"package","confirmation":"delivery","shipDate":"2015-07-02","holdUntilDate":{},"weight":{"value":48,"units":"ounces"},"dimensions":{"units":"inches","length":7,"width":5,"height":6},"insuranceOptions":{"provider":"carrier","insureShipment":true,"insuredValue":200},"internationalOptions":{"contents":{},"customsItems":{},"nonDelivery":{}},"advancedOptions":{"warehouseId":98765,"nonMachinable":false,"saturdayDelivery":false,"containsAlcohol":false,"mergedOrSplit":false,"mergedIds":[],"parentId":{},"storeId":12345,"customField1":"Customdatathatyoucanaddtoanorder.SeeCustomField#2&#3formoreinfo!","customField2":"PerUIsettings,thisinformationcanappearonsomecarriersshippinglabels.Seelinkbelow","customField3":"https://help.shipstation.com/hc/en-us/articles/206639957","source":"Webstore","billToParty":{},"billToAccount":{},"billToPostalCode":{},"billToCountryCode":{}},"tagIds":{},"userId":{},"externallyFulfilled":false,"externallyFulfilledBy":{}}],"total":2,"page":1,"pages":0}';
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) then exit(false);

        // Get Order from Shipstation to Fill Variables
        JSText := Connect2ShipStation('GETORDERS', '');
        JSObject.ReadFrom(JSText);
        OrdersJSArray := GetJSToken(JSObject, 'orders').AsArray();
        for Counter := 0 to OrdersJSArray.Count - 1 do begin
            OrdersJSArray.Get(Counter, OrderJSToken);
            JSObject := OrderJSToken.AsObject();
            txtOrders := GetJSToken(JSObject, 'orderNumber').AsValue().AsText();
            if txtOrders = DocNo then begin
                // Fill Token from Order
                JSObjectHeader.Add('orderId', GetJSToken(JSObject, 'orderId').AsValue().AsText());
                JSObjectHeader.Add('carrierCode', GetJSToken(JSObject, 'carrierCode').AsValue().AsText());
                JSObjectHeader.Add('serviceCode', GetJSToken(JSObject, 'serviceCode').AsValue().AsText());
                JSObjectHeader.Add('packageCode', GetJSToken(JSObject, 'packageCode').AsValue().AsText());
                JSObjectHeader.Add('confirmation', GetJSToken(JSObject, 'confirmation').AsValue().AsToken());
                JSObjectHeader.Add('shipDate', GetJSToken(JSObject, 'shipDate').AsValue().AsText());
                JSObjectHeader.Add('weight', GetJSToken(JSObject, 'weight').AsValue().AsToken());
                JSObjectHeader.Add('dimensions', GetJSToken(JSObject, 'dimensions').AsValue().AsToken());
                JSObjectHeader.Add('insuranceOptions', GetJSToken(JSObject, 'insuranceOptions').AsValue().AsToken());
                JSObjectHeader.Add('internationalOptions', GetJSToken(JSObject, 'internationalOptions').AsValue().AsToken());
                JSObjectHeader.Add('advancedOptions', GetJSToken(JSObject, 'advancedOptions').AsValue().AsToken());
                JSObjectHeader.Add('testLabel', false);
                JSObjectHeader.WriteTo(JSText);
                if testMode then
                    Message(JSText)
                else
                    // Create Label to Order
                    Connect2ShipStation('CREATELABEL', JSText);
            end;

        end;

        JSObjectHeader.Add('externallyFulfilledBy', '');
        JSObjectHeader.WriteTo(JSText);
        if testMode then
            Message(JSText)
        else
            Connect2ShipStation('', JSText);

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
        JSObjectLine.Add('billTo', _Cust.Name);
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
        // JSObjectLine.WriteTo(txtBillTo);
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
        JSObjectLine.Add('billTo', _SH."Sell-to Customer Name");
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
        // JSObjectLine.WriteTo(txtShipTo);
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
                JSObjectLine.Add('orderItemId', _SL."Line No.");
                JSObjectLine.Add('lineItemKey', _SL."No.");
                JSObjectLine.Add('sku', '');
                JSObjectLine.Add('name', _SL.Description);
                JSObjectLine.Add('imageUrl', '');
                JSObjectLine.Add('weight', jsonWeightFromItem(_SL."No."));
                JSObjectLine.Add('quantity', _SL.Quantity);
                JSObjectLine.Add('unitPrice', _SL."Unit Price");
                JSObjectLine.Add('taxAmount', _SL."Amount Including VAT" - _SL.Amount);
                JSObjectLine.Add('shippingAmount', 0);
                JSObjectLine.Add('warehouseLocation', _SL."Location Code");
                JSObjectLine.Add('productId', _SL."No.");
                JSObjectLine.Add('fulfillmentSku', '');
                JSObjectLine.Add('adjustment', '');
                JSObjectArray.Add(JSObjectLine);
            until _SL.Next() = 0;
        // JSObjectArray.WriteTo(txtItem);
        exit(JSObjectArray);
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
        // JSObjectLine.WriteTo(txtWeight);
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

    local procedure GetDateFromText(DateText: Text): Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        EVALUATE(Year, COPYSTR(DateText, 1, 4));
        EVALUATE(Month, COPYSTR(DateText, 6, 2));
        EVALUATE(Day, COPYSTR(DateText, 9, 2));
        EXIT(DMY2DATE(Day, Month, Year));
    end;

    local procedure Date2Text4JSON(_Date: Date): Text
    var
        Year: Text[4];
        Month: Text[2];
        Day: Text[2];
    begin
        EVALUATE(Day, PadStr(Format(Date2DMY(_Date, 1)), 2, '0'));
        EVALUATE(Month, PadStr(Format(Date2DMY(_Date, 2)), 2, '0'));
        EVALUATE(Year, Format(Date2DMY(_Date, 3)));
        EXIT(Year + '-' + Month + '-' + Day + 'T00:00:00.0000000');
    end;

    var
        testMode: Boolean;
}