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

            OrderTasks : Association to many Tasks
                on OrderTasks.OrderID = $self.OrderID,


            // =============================================
            // VIRTUAL ORDER FIELDS
            // =============================================

            virtual ShippingStatus : String(20),

            virtual TotalQuantity : Integer,

            virtual NetOrderValue : Decimal(15,2),


            // =============================================
            // REVIEW INFORMATION
            // =============================================

            virtual ReviewStatus : String(30),

            virtual ReviewReason : String(500),

            virtual MarkedBy : String(255),

            virtual MarkedAt : Timestamp,

            virtual AnalystComment : String(500),

            virtual ReviewedBy : String(255),

            virtual ReviewedAt : Timestamp,


            // =============================================
            // ACTION AVAILABILITY
            // =============================================

            virtual CanMarkForReview : Boolean,

            virtual CanCompleteReview : Boolean,

            virtual CanRejectReview : Boolean


    } actions {


        // =================================================
        // MARK FOR REVIEW
        // =================================================
        //
        // Coordinator only
        //
        // =================================================

        @requires: 'ZNW_ORD_COORD'
        @Core.OperationAvailable: (:in.CanMarkForReview)
        @Common.SideEffects: {
            TargetEntities: [
                'in'
            ]
        }
        action markForReview(

            in : $self,

            @title: 'Review Reason'
            ReviewReason : String(500)

        ) returns String;


        // =================================================
        // COMPLETE REVIEW
        // =================================================
        //
        // Analyst only
        //
        // =================================================

        @requires: 'ZNW_ORD_ANALYST'
        @Core.OperationAvailable: (:in.CanCompleteReview)
        @Common.SideEffects: {
            TargetEntities: [
                'in'
            ]
        }
        action completeReview(

            in : $self,

            @title: 'Analyst Comment'
            AnalystComment : String(500)

        ) returns String;


        // =================================================
        // REJECT REVIEW
        // =================================================
        //
        // Analyst only
        //
        // =================================================

        @requires: 'ZNW_ORD_ANALYST'
        @Core.OperationAvailable: (:in.CanRejectReview)
        @Common.IsActionCritical: true
        @Common.SideEffects: {
            TargetEntities: [
                'in'
            ]
        }
        action rejectReview(

            in : $self,

            @title: 'Rejection Reason'
            AnalystComment : String(500)

        ) returns String;


        // =================================================
        // CREATE TASK
        // =================================================
        //
        // Coordinator only
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

            @requires: 'ZNW_ORD_COORD'

            @Common.SideEffects: {
                TargetEntities: [
                    'in',
                    '/OrderWorkbenchService.EntityContainer/Tasks'
                ]
            }

            action updateTask(

                in : $self,


                @title: 'Title'
                @UI.ParameterDefaultValue: in.Title
                Title : String(120),


                @title: 'Description'
                @UI.ParameterDefaultValue: in.Description
                Description : String(500),


                @title: 'Status'
                @UI.ParameterDefaultValue: in.Status
                Status : String(20),


                @title: 'Priority'
                @UI.ParameterDefaultValue: in.Priority
                Priority : String(20),


                @title: 'Assigned To'
                @UI.ParameterDefaultValue: in.AssignedTo
                AssignedTo : String(255),


                @title: 'Due Date'
                @UI.ParameterDefaultValue: in.DueDate
                DueDate : Date

            ) returns String;


            // =============================================
            // DELETE TASK
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