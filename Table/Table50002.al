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

    procedure Connect2ShipStation(): Boolean;
    var
        TempBlob: Record TempBlob;
        SourceParameters: Record "Source Parameters";
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        Client: HttpClient;
        ResponseText: Text;
    begin
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
            Content.WriteFrom('** TextForRequest **');
            RequestMessage.Content := Content;
        end;

        Content.GetHeaders(Headers);
        if "FSp ContentType" <> 0 then begin
            Headers.Remove('Content-Type');
            Headers.Add('Content-Type', Format(SourceParameters."FSp ContentType"));
        end;


        Client.Send(RequestMessage, ResponseMessage);
        Content := ResponseMessage.Content;
        if Content.ReadAs(ResponseText) then
            Message('Response Text - %1', ResponseText);

        Message('Total Orders - %2\Orders Nos - %1', GetJSValueFromJSToken(ResponseText, 'total'), GetJSValueFromJSToken(ResponseText, 'orders'));

        exit(true);
    end;

    procedure GetJSValueFromJSToken(JSasText: Text; JSToken: Text): Text;
    var
        JSMgt: Codeunit "Json Text Reader/Writer";
        tempJSBuffer: Record "JSON Buffer";
    begin
        JSMgt.ReadJSonToJSonBuffer(JSasText, tempJSBuffer);
    end;

}