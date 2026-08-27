using OrderWorkbenchService from './order-service';


/*
 * =========================================================
 * TASKS
 * =========================================================
 */
annotate OrderWorkbenchService.Tasks with @(


    /*
     * =====================================================
     * TASK OBJECT PAGE HEADER
     * =====================================================
     */
    UI.HeaderInfo: {

        TypeName: 'Task',

        TypeNamePlural: 'Tasks',

        Title: {
            $Type: 'UI.DataField',
            Value: Title
        },

        Description: {
            $Type: 'UI.DataField',
            Value: Status
        }

    },


    /*
     * =====================================================
     * FILTER BAR
     * =====================================================
     */
    UI.SelectionFields: [

        OrderID,

        Status,

        Priority,

        AssignedTo,

        DueDate

    ],


    /*
     * =====================================================
     * TASK LIST REPORT
     * =====================================================
     */
    UI.LineItem: [

        {
            $Type: 'UI.DataField',
            Label: 'Order ID',
            Value: OrderID
        },

        {
            $Type: 'UI.DataField',
            Label: 'Title',
            Value: Title
        },

        {
            $Type: 'UI.DataField',
            Label: 'Status',
            Value: Status,

            Criticality: (
                Status = 'Completed'
                    ? 3
                    : (
                        Status = 'Open'
                            ? 2
                            : 0
                    )
            ),

            CriticalityRepresentation: #WithIcon
        },

        {
            $Type: 'UI.DataField',
            Label: 'Priority',
            Value: Priority,

            Criticality: (
                Priority = 'High'
                    ? 1
                    : (
                        Priority = 'Medium'
                            ? 2
                            : 0
                    )
            ),

            CriticalityRepresentation: #WithIcon
        },

        {
            $Type: 'UI.DataField',
            Label: 'Assigned To',
            Value: AssignedTo
        },

        {
            $Type: 'UI.DataField',
            Label: 'Due Date',
            Value: DueDate
        },

        {
            $Type: 'UI.DataField',
            Label: 'Created By',
            Value: CreatedBy
        },

        {
            $Type: 'UI.DataField',
            Label: 'Created At',
            Value: CreatedAt
        }

    ],


    /*
     * =====================================================
     * GENERAL TASK INFORMATION
     * =====================================================
     */
    UI.FieldGroup #General: {

        Data: [

            {
                $Type: 'UI.DataField',
                Label: 'Order ID',
                Value: OrderID
            },

            {
                $Type: 'UI.DataField',
                Label: 'Title',
                Value: Title
            },

            {
                $Type: 'UI.DataField',
                Label: 'Description',
                Value: Description
            },

            {
                $Type: 'UI.DataField',
                Label: 'Status',
                Value: Status,

                Criticality: (
                    Status = 'Completed'
                        ? 3
                        : (
                            Status = 'Open'
                                ? 2
                                : 0
                        )
                ),

                CriticalityRepresentation: #WithIcon
            },

            {
                $Type: 'UI.DataField',
                Label: 'Priority',
                Value: Priority,

                Criticality: (
                    Priority = 'High'
                        ? 1
                        : (
                            Priority = 'Medium'
                                ? 2
                                : 0
                        )
                ),

                CriticalityRepresentation: #WithIcon
            },

            {
                $Type: 'UI.DataField',
                Label: 'Assigned To',
                Value: AssignedTo
            },

            {
                $Type: 'UI.DataField',
                Label: 'Due Date',
                Value: DueDate
            },

            {
                $Type: 'UI.DataField',
                Label: 'Created By',
                Value: CreatedBy
            },

            {
                $Type: 'UI.DataField',
                Label: 'Created At',
                Value: CreatedAt
            },

            {
                $Type: 'UI.DataField',
                Label: 'Completed At',
                Value: CompletedAt
            },
    {
        $Type  : 'UI.DataFieldForAction',
        Action : 'OrderWorkbenchService.updateTask',
        Label  : 'Edit Task',
        Inline : true
    },

    {
        $Type  : 'UI.DataFieldForAction',
        Action : 'OrderWorkbenchService.deleteTask',
        Label  : 'Delete Task',
        Inline : true
    }

        ]

    },


    /*
     * =====================================================
     * TASK OBJECT PAGE SECTIONS
     * =====================================================
     */
    UI.Facets: [

        {
            $Type: 'UI.ReferenceFacet',
            ID: 'TaskGeneralInformation',
            Label: 'Task Details',
            Target: '@UI.FieldGroup#General'
        }

    ]

);


/*
 * =========================================================
 * FIELD LABELS
 * =========================================================
 */
annotate OrderWorkbenchService.Tasks with {

    OrderID
        @title: 'Order ID';

    Title
        @title: 'Title';

    Description
        @title: 'Description';

    Status
        @title: 'Status';

    Priority
        @title: 'Priority';

    AssignedTo
        @title: 'Assigned To';

    DueDate
        @title: 'Due Date';

    CreatedBy
        @title: 'Created By';

    CreatedAt
        @title: 'Created At';

    CompletedAt
        @title: 'Completed At';

};