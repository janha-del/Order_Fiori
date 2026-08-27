using OrderWorkbenchService as service from '../../srv/order-service';


/*
 * =========================================================
 * ORDERS
 * =========================================================
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
        ShipVia,
        OrderDate,
        RequiredDate,
        ShippingStatus
    ],


    /*
     * =====================================================
     * OBJECT PAGE ACTIONS
     * =====================================================
     */

    UI.Identification: [

        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'OrderWorkbenchService.markForReview',
            Label  : 'Mark for Review'
        },

        {
            $Type  : 'UI.DataFieldForAction',
            Action : 'OrderWorkbenchService.createTask',
            Label  : 'Create Task'
        }

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

        /*
         * SHIPPING STATUS WITH SEMANTIC COLOR
         *
         * 3 = Positive  -> Green
         * 1 = Negative  -> Red
         * 2 = Critical  -> Orange
         * 0 = Neutral
         */

        {
            $Type: 'UI.DataField',
            Value: ShippingStatus,
            Label: 'Shipping Status',

            Criticality: (
                ShippingStatus = 'Shipped'
                    ? 3
                    : (
                        ShippingStatus = 'Overdue'
                            ? 1
                            : (
                                ShippingStatus = 'Due Soon'
                                    ? 2
                                    : 0
                            )
                    )
            ),

            CriticalityRepresentation: #WithIcon
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
                Value: ShipVia,
                Label: 'Shipper'
            },

            /*
             * SHIPPING STATUS WITH SEMANTIC COLOR
             * ON OBJECT PAGE
             */

            {
                $Type: 'UI.DataField',
                Value: ShippingStatus,
                Label: 'Shipping Status',

                Criticality: (
                    ShippingStatus = 'Shipped'
                        ? 3
                        : (
                            ShippingStatus = 'Overdue'
                                ? 1
                                : (
                                    ShippingStatus = 'Due Soon'
                                        ? 2
                                        : 0
                                )
                        )
                ),

                CriticalityRepresentation: #WithIcon
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
     * CUSTOMER INFORMATION
     * =====================================================
     */

    UI.FieldGroup #Customer: {

        Data: [

            {
                $Type: 'UI.DataField',
                Value: Customer.CustomerID,
                Label: 'Customer ID'
            },

            {
                $Type: 'UI.DataField',
                Value: Customer.CompanyName,
                Label: 'Company Name'
            },

            {
                $Type: 'UI.DataField',
                Value: Customer.ContactName,
                Label: 'Contact Name'
            },

            {
                $Type: 'UI.DataField',
                Value: Customer.ContactTitle,
                Label: 'Contact Title'
            },

            {
                $Type: 'UI.DataField',
                Value: Customer.Phone,
                Label: 'Phone'
            },

            {
                $Type: 'UI.DataField',
                Value: Customer.City,
                Label: 'City'
            },

            {
                $Type: 'UI.DataField',
                Value: Customer.Country,
                Label: 'Country'
            }

        ]

    },


    /*
     * =====================================================
     * EMPLOYEE INFORMATION
     * =====================================================
     */

    UI.FieldGroup #Employee: {

        Data: [

            {
                $Type: 'UI.DataField',
                Value: Employee.EmployeeID,
                Label: 'Employee ID'
            },

            {
                $Type: 'UI.DataField',
                Value: Employee.FirstName,
                Label: 'First Name'
            },

            {
                $Type: 'UI.DataField',
                Value: Employee.LastName,
                Label: 'Last Name'
            },

            {
                $Type: 'UI.DataField',
                Value: Employee.Title,
                Label: 'Title'
            },

            {
                $Type: 'UI.DataField',
                Value: Employee.City,
                Label: 'City'
            },

            {
                $Type: 'UI.DataField',
                Value: Employee.Country,
                Label: 'Country'
            }

        ]

    },


    /*
     * =====================================================
     * SHIPPER INFORMATION
     * =====================================================
     */

    UI.FieldGroup #Shipper: {

        Data: [

            {
                $Type: 'UI.DataField',
                Value: Shipper.ShipperID,
                Label: 'Shipper ID'
            },

            {
                $Type: 'UI.DataField',
                Value: Shipper.CompanyName,
                Label: 'Company Name'
            },

            {
                $Type: 'UI.DataField',
                Value: Shipper.Phone,
                Label: 'Phone'
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
     * OBJECT PAGE SECTIONS
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
            ID: 'CustomerInformation',
            Label: 'Customer Information',
            Target: '@UI.FieldGroup#Customer'
        },

        {
            $Type: 'UI.ReferenceFacet',
            ID: 'EmployeeInformation',
            Label: 'Employee Information',
            Target: '@UI.FieldGroup#Employee'
        },

        {
            $Type: 'UI.ReferenceFacet',
            ID: 'ShipperInformation',
            Label: 'Shipper Information',
            Target: '@UI.FieldGroup#Shipper'
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
        },
        {
    $Type: 'UI.ReferenceFacet',
    ID: 'Tasks',
    Label: 'Tasks',
    Target: 'OrderTasks/@UI.LineItem'
}

    ]

);



/*
 * =========================================================
 * CUSTOMER / EMPLOYEE / SHIPPER VALUE HELPS
 * =========================================================
 */

annotate service.Orders with {


    /*
     * =====================================================
     * CUSTOMER VALUE HELP
     * =====================================================
     */

    CustomerID
        @title: 'Customer'
        @Common: {

            Text: Customer.CompanyName,

            TextArrangement: #TextOnly,

            ValueList: {

                Label: 'Customers',

                CollectionPath: 'Customers',

                Parameters: [

                    {
                        $Type:
                            'Common.ValueListParameterInOut',

                        LocalDataProperty:
                            CustomerID,

                        ValueListProperty:
                            'CustomerID'
                    },

                    {
                        $Type:
                            'Common.ValueListParameterDisplayOnly',

                        ValueListProperty:
                            'CompanyName'
                    },

                    {
                        $Type:
                            'Common.ValueListParameterDisplayOnly',

                        ValueListProperty:
                            'ContactName'
                    },

                    {
                        $Type:
                            'Common.ValueListParameterDisplayOnly',

                        ValueListProperty:
                            'City'
                    },

                    {
                        $Type:
                            'Common.ValueListParameterDisplayOnly',

                        ValueListProperty:
                            'Country'
                    }

                ]

            }

        };


    /*
     * =====================================================
     * EMPLOYEE VALUE HELP
     * =====================================================
     */

    EmployeeID
        @title: 'Employee'
        @Common: {

            Text: Employee.LastName,

            TextArrangement: #TextOnly,

            ValueList: {

                Label: 'Employees',

                CollectionPath: 'Employees',

                Parameters: [

                    {
                        $Type:
                            'Common.ValueListParameterInOut',

                        LocalDataProperty:
                            EmployeeID,

                        ValueListProperty:
                            'EmployeeID'
                    },

                    {
                        $Type:
                            'Common.ValueListParameterDisplayOnly',

                        ValueListProperty:
                            'FirstName'
                    },

                    {
                        $Type:
                            'Common.ValueListParameterDisplayOnly',

                        ValueListProperty:
                            'LastName'
                    },

                    {
                        $Type:
                            'Common.ValueListParameterDisplayOnly',

                        ValueListProperty:
                            'Title'
                    }

                ]

            }

        };


    /*
     * =====================================================
     * SHIPPER VALUE HELP
     * =====================================================
     */

    ShipVia
        @title: 'Shipper'
        @Common: {

            Text: Shipper.CompanyName,

            TextArrangement: #TextOnly,

            ValueList: {

                Label: 'Shippers',

                CollectionPath: 'Shippers',

                Parameters: [

                    {
                        $Type:
                            'Common.ValueListParameterInOut',

                        LocalDataProperty:
                            ShipVia,

                        ValueListProperty:
                            'ShipperID'
                    },

                    {
                        $Type:
                            'Common.ValueListParameterDisplayOnly',

                        ValueListProperty:
                            'CompanyName'
                    },

                    {
                        $Type:
                            'Common.ValueListParameterDisplayOnly',

                        ValueListProperty:
                            'Phone'
                    }

                ]

            }

        };

};



/*
 * =========================================================
 * ORDER DETAILS
 * =========================================================
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