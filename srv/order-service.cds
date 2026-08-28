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
            // Order 10248
            //      ↓
            // Tasks with OrderID = 10248
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
        //
        // Only Coordinator can execute this action.
        //
        // =================================================

        @requires: 'ZNW_ORD_COORD'
        @Core.OperationAvailable: (:in.CanMarkForReview)
        action markForReview(

            in : $self

        ) returns String;


        // =================================================
        // CREATE TASK
        // =================================================
        //
        // Only Coordinator can create a Task from an Order.
        //
        // After creation, refresh OrderTasks automatically.
        //
        // =================================================

        @requires: 'ZNW_ORD_COORD'
        @Core.OperationAvailable: (:in.CanMarkForReview)
        @Common.SideEffects: {
            TargetEntities: [
                'in/OrderTasks'
            ]
        }
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
    // TASKS AUTHORIZATION
    // =====================================================
    //
    // DISPLAY:
    //     READ only
    //
    // COORD:
    //     READ
    //     CREATE
    //     UPDATE
    //     DELETE
    //
    // ANALYST:
    //     READ only
    //
    // =====================================================

    @restrict: [

        // -------------------------------------------------
        // ALL THREE ROLES CAN READ TASKS
        // -------------------------------------------------

        {
            grant: 'READ',

            to: [
                'ZNW_ORD_DISPLAY',
                'ZNW_ORD_COORD',
                'ZNW_ORD_ANALYST'
            ]
        },


        // -------------------------------------------------
        // ONLY COORDINATOR CAN MODIFY TASKS
        // -------------------------------------------------

        {
            grant: [
                'CREATE',
                'UPDATE',
                'DELETE'
            ],

            to: 'ZNW_ORD_COORD'
        }

    ]


    // =====================================================
    // TASKS
    // =====================================================

    entity Tasks
        as projection on db.Tasks

        actions {


            // =============================================
            // UPDATE TASK
            // =============================================
            //
            // Only Coordinator.
            //
            // Existing Task values are automatically
            // populated into the Edit Task dialog.
            //
            // =============================================

            @requires: 'ZNW_ORD_COORD'

            @Common.SideEffects: {
                TargetEntities: [
                    'in',
                    '/OrderWorkbenchService.EntityContainer/Tasks'
                ]
            }

            action updateTask(

                in : $self,


                // -----------------------------------------
                // TITLE
                // -----------------------------------------

                @title: 'Title'
                @UI.ParameterDefaultValue: in.Title
                Title : String(120),


                // -----------------------------------------
                // DESCRIPTION
                // -----------------------------------------

                @title: 'Description'
                @UI.ParameterDefaultValue: in.Description
                Description : String(500),


                // -----------------------------------------
                // STATUS
                // -----------------------------------------

                @title: 'Status'
                @UI.ParameterDefaultValue: in.Status
                Status : String(20),


                // -----------------------------------------
                // PRIORITY
                // -----------------------------------------

                @title: 'Priority'
                @UI.ParameterDefaultValue: in.Priority
                Priority : String(20),


                // -----------------------------------------
                // ASSIGNED TO
                // -----------------------------------------

                @title: 'Assigned To'
                @UI.ParameterDefaultValue: in.AssignedTo
                AssignedTo : String(255),


                // -----------------------------------------
                // DUE DATE
                // -----------------------------------------

                @title: 'Due Date'
                @UI.ParameterDefaultValue: in.DueDate
                DueDate : Date

            ) returns String;


            // =============================================
            // DELETE TASK
            // =============================================
            //
            // Only Coordinator.
            //
            // Critical action causes Fiori to request
            // confirmation before deleting.
            //
            // =============================================

            @requires: 'ZNW_ORD_COORD'

            @Common.IsActionCritical: true

            @Common.SideEffects: {
                TargetEntities: [
                    '/OrderWorkbenchService.EntityContainer/Tasks'
                ]
            }

            action deleteTask(

                in : $self

            ) returns String;


        };


}