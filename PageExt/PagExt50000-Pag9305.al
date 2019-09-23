pageextension 50000 "Sales Order List Ext." extends "Sales Order List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(Warehouse)
        {
            group(ShipStation)
            {
                action("Get Orders")
                {
                    trigger OnAction()
                    var
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                    begin
                        ShipStationMgt.GetOrdersFromShipStation();
                    end;
                }
                action("Create Orders")
                {
                    trigger OnAction()
                    var
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _SH: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(_SH);
                        if _SH.FindSet(false, false) then
                            repeat
                                ShipStationMgt.CreateOrderInShipStation(_SH."No.");
                            until _SH.Next() = 0;
                    end;
                }
                action("Create Label to Orders")
                {
                    trigger OnAction()
                    var
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _SH: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(_SH);
                        if _SH.FindSet(false, false) then
                            repeat
                            // ShipStationMgt.CreateLabel2OrderInShipStation(_SH."No.");
                            until _SH.Next() = 0;
                    end;
                }
            }
        }

    }

    var
        myInt: Integer;
}