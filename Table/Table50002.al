table 50002 "Source Parameters"
{
    DataClassification = ToBeClassified;
    CaptionML = ENU = 'Source Parameters', RUS = 'Параметры подключения';

    fields
    {
        field(1; Code; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Code', RUS = 'Код';
        }
        field(2; "FSp RestMethod"; Option)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'FSp RestMethod', RUS = 'FSp RestMethod';
            OptionMembers = GET,POST;
            OptionCaptionML = ENU = 'GET,POST', RUS = 'GET,POST';
        }
        field(3; "FSp URL"; Text[200])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'FSp URL', RUS = 'FSp URL';
        }
        field(4; "FSp Accept"; Code[20])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'FSp Accept', RUS = 'FSp Accept';
        }
        field(5; "FSp AuthorizationFrameworkType"; Option)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'FSp Authorization Framework Type', RUS = 'FSp Authorization Framework Type';
            OptionMembers = " ",BasicHTTP,OAuth2;
            OptionCaptionML = ENU = ' ,Basic HTTP,OAuth2', RUS = ' ,Basic HTTP,OAuth2';
        }
        field(6; "FSp AuthorizationToken"; Text[200])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'FSp Authorization Token', RUS = 'FSp Authorization Token';
        }
        field(7; "FSp UserName"; Text[100])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'FSp UserName', RUS = 'FSp UserName';
        }
        field(8; "FSp Password"; Text[100])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'FSp Password', RUS = 'FSp Password';
        }
        field(9; "FSp ContentType"; Option)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'FSp ContentType', RUS = 'FSp ContentType';
            OptionMembers = " ","application/json";
            OptionCaptionML = ENU = ' ,application/json', RUS = ' ,application/json';
        }
        field(10; "FSp ETag"; Text[100])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'FSp E-Tag', RUS = 'FSp E-Tag';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

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
            Rec.Get(SPCode);

        SourceParameters := Rec;
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

        if "FSp RestMethod" = "FSp RestMethod"::POST then begin
            Content.WriteFrom(TextForRequest);
            RequestMessage.Content := Content;

            Content.GetHeaders(Headers);
            if "FSp ContentType" <> 0 then begin
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
        JSObjectLine: JsonObject;
        OrdersJSArray: JsonArray;
        txtBillTo: Text;
        txtAwaitingShipment: Label 'awaiting_shipment';
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) then exit(false);

        JSObjectLine.Add('billTo', _SH."Sell-to Customer Name");
        JSObjectLine.WriteTo(txtBillTo);
        Clear(JSObjectLine);

        JSObjectHeader.Add('orderNumber', _SH."No.");
        JSObjectHeader.Add('orderDate', Date2Text4JSON(_SH."Posting Date"));
        JSObjectHeader.Add('orderStatus', txtAwaitingShipment);
        JSObjectHeader.Add('billTo', txtBillTo);


    end;

    procedure GetJSToken(_JSONObject: JsonObject; TokenKey: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.Get(TokenKey, _JSONToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    procedure SelectJSToken(_JSONObject: JsonObject; Path: Text) _JSONToken: JsonToken;
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
}