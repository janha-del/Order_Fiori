using { Northwind as nw } from './external/Northwind';

@(path: '/order-workbench')
service OrderWorkbenchService {

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

            virtual ShippingStatus : String(20),
            virtual TotalQuantity  : Integer,
            virtual NetOrderValue  : Decimal(15,2)

    } actions {

        action markForReview() returns String;

    };


    @readonly
    entity OrderDetails as projection on nw.Order_Details {
        key OrderID,
        key ProductID,
            UnitPrice,
            Quantity,
            Discount,

            virtual LineTotal : Decimal(15,2)
    };


    @readonly
    entity Customers as projection on nw.Customers;

    @readonly
    entity Employees as projection on nw.Employees;

    @readonly
    entity Shippers as projection on nw.Shippers;

}