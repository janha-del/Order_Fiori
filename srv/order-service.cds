using { Northwind as nw } from './external/Northwind';
using { project1.db as db } from '../db/schema';


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
            // NORTHWIND ASSOCIATIONS
            // =============================================

            Customer,

            Employee,

            Shipper,

            Order_Details,


            // =============================================
            // LOCAL TASK ASSOCIATION
            // =============================================
            //
            // Connects:
            //
            // Order 10248
            //      ↓
            // Tasks where OrderID = 10248
            //
            // Tasks are stored in HANA.
            //
            OrderTasks : Association to many Tasks
                on OrderTasks.OrderID = $self.OrderID,


            // =============================================
            // VIRTUAL FIELDS
            // =============================================

            virtual ShippingStatus : String(20),

            virtual TotalQuantity : Integer,

            virtual NetOrderValue : Decimal(15,2),

            virtual CanMarkForReview : Boolean


    } actions {


        // =================================================
        // MARK FOR REVIEW
        // =================================================

        @requires: 'ZNW_ORD_COORD'
        @Core.OperationAvailable: (:in.CanMarkForReview)
        action markForReview(

            in : $self

        ) returns String;


        // =================================================
        // CREATE TASK
        // =================================================

        @requires: 'ZNW_ORD_COORD'
        @Core.OperationAvailable: (:in.CanMarkForReview)
        action createTask(

            in : $self,

            @title: 'Title'
            Title : String(120),

            @title: 'Description'
            Description : String(500),

            @title: 'Priority'
            Priority : String(20),

            @title: 'Assigned To'
            AssignedTo : String(255),

            @title: 'Due Date'
            DueDate : Date

        ) returns String;


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


    // =====================================================
    // TASKS
    // =====================================================
    //
    // Tasks are stored in our own HANA database.
    //
    // They do NOT come from Northwind.
    //
    // OrderID links a Task to its Order.
    //
    // Example:
    //
    // OrderID = 10248
    //
    // can have:
    //
    // Task 1
    // Task 2
    // Task 3
    //
    // =====================================================

  entity Tasks
    as projection on db.Tasks

    actions {

        // =================================================
        // UPDATE TASK
        // =================================================

        @requires: 'ZNW_ORD_COORD'
        action updateTask(

            in : $self,

            @title: 'Title'
            Title : String(120),

            @title: 'Description'
            Description : String(500),

            @title: 'Status'
            Status : String(20),

            @title: 'Priority'
            Priority : String(20),

            @title: 'Assigned To'
            AssignedTo : String(255),

            @title: 'Due Date'
            DueDate : Date

        ) returns String;


        // =================================================
        // DELETE TASK
        // =================================================

        @requires: 'ZNW_ORD_COORD'
        @Common.IsActionCritical: true
        action deleteTask(

            in : $self

        ) returns String;

    };

}