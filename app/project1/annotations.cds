using OrderWorkbenchService as service from '../../srv/order-service';


/*
 * =========================================================
 * ORDERS
 * =========================================================
 *
 * This annotation controls:
 *
 * 1. List Report filters
 * 2. List Report columns
 * 3. Object Page header
 * 4. Object Page sections
 * 5. Order totals
 * 6. Order Items section
 *
 */

annotate service.Orders with @(


    /*
     * =====================================================
     * FILTER BAR
     * =====================================================
     */

    UI.SelectionFields: [

        CustomerID,

        EmployeeID,

        OrderDate,

        RequiredDate,

        ShippingStatus

    ],


    /*
     * =====================================================
     * LIST REPORT TABLE
     * =====================================================
     */

    UI.LineItem: [

        {
            $Type: 'UI.DataField',
            Value: OrderID,
            Label: 'Order ID'
        },

        {
            $Type: 'UI.DataField',
            Value: CustomerID,
            Label: 'Customer'
        },

        {
            $Type: 'UI.DataField',
            Value: EmployeeID,
            Label: 'Employee'
        },

        {
            $Type: 'UI.DataField',
            Value: OrderDate,
            Label: 'Order Date'
        },

        {
            $Type: 'UI.DataField',
            Value: RequiredDate,
            Label: 'Required Date'
        },

        {
            $Type: 'UI.DataField',
            Value: ShippedDate,
            Label: 'Shipped Date'
        },

        {
            $Type: 'UI.DataField',
            Value: ShippingStatus,
            Label: 'Shipping Status'
        },

        {
            $Type: 'UI.DataField',
            Value: Freight,
            Label: 'Freight'
        }

    ],


    /*
     * =====================================================
     * OBJECT PAGE HEADER
     * =====================================================
     */

    UI.HeaderInfo: {

        TypeName: 'Order',

        TypeNamePlural: 'Orders',

        Title: {
            $Type: 'UI.DataField',
            Value: OrderID
        },

        Description: {
            $Type: 'UI.DataField',
            Value: ShipName
        }

    },


    /*
     * =====================================================
     * GENERAL INFORMATION
     * =====================================================
     */

    UI.FieldGroup #General: {

        Data: [

            {
                $Type: 'UI.DataField',
                Value: OrderID,
                Label: 'Order ID'
            },

            {
                $Type: 'UI.DataField',
                Value: CustomerID,
                Label: 'Customer'
            },

            {
                $Type: 'UI.DataField',
                Value: EmployeeID,
                Label: 'Employee'
            },

            {
                $Type: 'UI.DataField',
                Value: ShippingStatus,
                Label: 'Shipping Status'
            },

            {
                $Type: 'UI.DataField',
                Value: OrderDate,
                Label: 'Order Date'
            },

            {
                $Type: 'UI.DataField',
                Value: RequiredDate,
                Label: 'Required Date'
            },

            {
                $Type: 'UI.DataField',
                Value: ShippedDate,
                Label: 'Shipped Date'
            },

            {
                $Type: 'UI.DataField',
                Value: Freight,
                Label: 'Freight'
            }

        ]

    },


    /*
     * =====================================================
     * SHIPPING INFORMATION
     * =====================================================
     */

    UI.FieldGroup #Shipping: {

        Data: [

            {
                $Type: 'UI.DataField',
                Value: ShipName,
                Label: 'Ship Name'
            },

            {
                $Type: 'UI.DataField',
                Value: ShipAddress,
                Label: 'Address'
            },

            {
                $Type: 'UI.DataField',
                Value: ShipCity,
                Label: 'City'
            },

            {
                $Type: 'UI.DataField',
                Value: ShipRegion,
                Label: 'Region'
            },

            {
                $Type: 'UI.DataField',
                Value: ShipPostalCode,
                Label: 'Postal Code'
            },

            {
                $Type: 'UI.DataField',
                Value: ShipCountry,
                Label: 'Country'
            }

        ]

    },


    /*
     * =====================================================
     * ORDER TOTALS
     * =====================================================
     */

    UI.FieldGroup #Totals: {

        Data: [

            {
                $Type: 'UI.DataField',
                Value: TotalQuantity,
                Label: 'Total Quantity'
            },

            {
                $Type: 'UI.DataField',
                Value: NetOrderValue,
                Label: 'Net Order Value'
            }

        ]

    },


    /*
     * =====================================================
     * OBJECT PAGE SECTIONS / FACETS
     * =====================================================
     */

    UI.Facets: [

        {
            $Type: 'UI.ReferenceFacet',
            ID: 'GeneralInformation',
            Label: 'General Information',
            Target: '@UI.FieldGroup#General'
        },

        {
            $Type: 'UI.ReferenceFacet',
            ID: 'ShippingInformation',
            Label: 'Shipping Information',
            Target: '@UI.FieldGroup#Shipping'
        },

        {
            $Type: 'UI.ReferenceFacet',
            ID: 'OrderTotals',
            Label: 'Order Totals',
            Target: '@UI.FieldGroup#Totals'
        },

        {
            $Type: 'UI.ReferenceFacet',
            ID: 'OrderItems',
            Label: 'Order Items',
            Target: 'Order_Details/@UI.LineItem'
        }

    ]

);



/*
 * =========================================================
 * ORDER DETAILS
 * =========================================================
 *
 * This becomes the Order Items table
 * inside the Order Object Page.
 *
 */

annotate service.OrderDetails with @(

    UI.LineItem: [

        {
            $Type: 'UI.DataField',
            Value: ProductID,
            Label: 'Product ID'
        },

        {
            $Type: 'UI.DataField',
            Value: UnitPrice,
            Label: 'Unit Price'
        },

        {
            $Type: 'UI.DataField',
            Value: Quantity,
            Label: 'Quantity'
        },

        {
            $Type: 'UI.DataField',
            Value: Discount,
            Label: 'Discount'
        },

        {
            $Type: 'UI.DataField',
            Value: LineTotal,
            Label: 'Line Total'
        }

    ]

);