using { Northwind as nw } from './external/Northwind';


@(path: '/order-workbench')
@requires: [
    'ZNW_ORD_DISPLAY',
    'ZNW_ORD_COORD',
    'ZNW_ORD_ANALYST'
]
service OrderWorkbenchService {


    // =====================================================
    // ORDERS
    // =====================================================

    @readonly
    entity Orders as projection on nw.Orders {

        key OrderID,

            CustomerID,

            EmployeeID,

            OrderDate,

            RequiredDate,

            ShippedDate,

            ShipVia,

            Freight,

            ShipName,

            ShipAddress,

            ShipCity,

            ShipRegion,

            ShipPostalCode,

            ShipCountry,


            // =============================================
            // ASSOCIATIONS
            // =============================================

            Customer,

            Employee,

            Shipper,

            Order_Details,


            // =============================================
            // VIRTUAL FIELDS
            // =============================================

            virtual ShippingStatus : String(20),

            virtual TotalQuantity : Integer,

            virtual NetOrderValue : Decimal(15,2)


    } actions {


        // =============================================
        // ONLY COORDINATOR CAN EXECUTE THIS
        // =============================================

        @requires: 'ZNW_ORD_COORD'
        action markForReview() returns String;


    };



    // =====================================================
    // ORDER DETAILS
    // =====================================================

    @readonly
    entity OrderDetails as projection on nw.Order_Details {

        key OrderID,

        key ProductID,

            UnitPrice,

            Quantity,

            Discount,

            virtual LineTotal : Decimal(15,2)

    };



    // =====================================================
    // CUSTOMERS
    // =====================================================

    @readonly
    entity Customers
        as projection on nw.Customers;



    // =====================================================
    // EMPLOYEES
    // =====================================================

    @readonly
    entity Employees
        as projection on nw.Employees;



    // =====================================================
    // SHIPPERS
    // =====================================================

    @readonly
    entity Shippers
        as projection on nw.Shippers;


}