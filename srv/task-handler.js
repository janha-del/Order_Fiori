const cds = require("@sap/cds");

const {
    SELECT,
    INSERT,
    UPDATE,
    DELETE
} = cds.ql;


module.exports = function (service) {


    // =====================================================
    // READ TASKS FOR CURRENT ORDER
    // =====================================================
    //
    // Handles:
    //
    // /Orders(10248)/OrderTasks
    //
    service.on(
        "READ",
        "Tasks",
        async function (req, next) {


            var select =
                req.query &&
                req.query.SELECT;


            if (!select) {

                return next();
            }


            var from =
                select.from;


            var ref =
                from &&
                from.ref;


            // -------------------------------------------------
            // Check whether this request came through:
            //
            // Orders(...)/OrderTasks
            //
            // -------------------------------------------------
            var isOrderTaskNavigation =
                false;


            if (Array.isArray(ref)) {

                for (
                    var i = 0;
                    i < ref.length;
                    i++
                ) {

                    var part =
                        ref[i];


                    var name;


                    if (
                        typeof part ===
                        "string"
                    ) {

                        name = part;

                    } else if (
                        part &&
                        part.id
                    ) {

                        name = part.id;
                    }


                    if (
                        name ===
                        "OrderTasks"
                    ) {

                        isOrderTaskNavigation =
                            true;
                    }
                }
            }


            // -------------------------------------------------
            // Normal /Tasks request
            //
            // Let CAP handle normally.
            // -------------------------------------------------
            if (
                !isOrderTaskNavigation
            ) {

                return next();
            }


            // -------------------------------------------------
            // Get OrderID
            // -------------------------------------------------

            var orderID;


            if (
                req.params &&
                req.params.length > 0 &&
                req.params[0] &&
                req.params[0].OrderID
            ) {

                orderID =
                    req.params[0].OrderID;
            }


            if (!orderID) {

                return [];
            }


            // -------------------------------------------------
            // Physical/local Tasks entity
            // -------------------------------------------------

            var dbTasks =
                cds.entities(
                    "project1.db"
                ).Tasks;


            // -------------------------------------------------
            // Copy original Fiori query
            // -------------------------------------------------

            var query =
                structuredClone(
                    req.query
                );


            // -------------------------------------------------
            // IMPORTANT
            //
            // Remove:
            //
            // Orders(...)/OrderTasks
            //
            // and query HANA Tasks directly.
            // -------------------------------------------------

            query.SELECT.from = {

                ref: [
                    dbTasks.name
                ]

            };


            // -------------------------------------------------
            // Force current OrderID
            // -------------------------------------------------

            var oldWhere =
                query.SELECT.where;


            query.SELECT.where = [

                {
                    ref: [
                        "OrderID"
                    ]
                },

                "=",

                {
                    val:
                        Number(
                            orderID
                        )
                }

            ];


            // Preserve any additional Fiori filter
            if (
                oldWhere &&
                oldWhere.length > 0
            ) {

                query.SELECT.where.push(
                    "and"
                );

                query.SELECT.where.push({

                    xpr:
                        oldWhere

                });
            }


            // -------------------------------------------------
            // Execute DIRECTLY against HANA
            // -------------------------------------------------

            return cds.db.run(
                query
            );
        }
    );


    // =====================================================
    // NORMAL CREATE TASK
    // =====================================================

    service.before(
        "CREATE",
        "Tasks",
        function (req) {

            req.data.Status =
                "Open";

            req.data.CreatedBy =
                req.user.id;

            req.data.CreatedAt =
                new Date();


            if (!req.data.Priority) {

                req.data.Priority =
                    "Medium";
            }
        }
    );


    // =====================================================
    // CREATE TASK FROM ORDER
    // =====================================================

    service.on(
        "createTask",
        "Orders",
        async function (req) {


            var orderID =
                req.params[0].OrderID;


            if (!req.data.Title) {

                return req.error(
                    400,
                    "Task Title is required"
                );
            }


            var priority =
                req.data.Priority ||
                "Medium";


            var dbTasks =
                cds.entities(
                    "project1.db"
                ).Tasks;


            await INSERT
                .into(
                    dbTasks
                )
                .entries({

                    ID:
                        cds.utils.uuid(),

                    OrderID:
                        orderID,

                    Title:
                        req.data.Title,

                    Description:
                        req.data.Description,

                    Status:
                        "Open",

                    Priority:
                        priority,

                    AssignedTo:
                        req.data.AssignedTo,

                    DueDate:
                        req.data.DueDate,

                    CreatedBy:
                        req.user.id,

                    CreatedAt:
                        new Date(),

                    CompletedAt:
                        null

                });


            var message =
                "Task created successfully for Order " +
                orderID;


            req.notify(
                message
            );


            return message;
        }
    );


    // =====================================================
    // UPDATE TASK
    // =====================================================

    service.on(
        "updateTask",
        "Tasks",
        async function (req) {


            var taskID =
                req.params[
                    req.params.length - 1
                ].ID;


            if (!taskID) {

                return req.error(
                    400,
                    "Task ID not found"
                );
            }


            var dbTasks =
                cds.entities(
                    "project1.db"
                ).Tasks;


            var changes = {};


            if (req.data.Title) {

                changes.Title =
                    req.data.Title;
            }


            if (
                req.data.Description !==
                undefined
            ) {

                changes.Description =
                    req.data.Description;
            }


            if (req.data.Priority) {

                changes.Priority =
                    req.data.Priority;
            }


            if (
                req.data.AssignedTo !==
                undefined
            ) {

                changes.AssignedTo =
                    req.data.AssignedTo;
            }


            if (
                req.data.DueDate !==
                undefined
            ) {

                changes.DueDate =
                    req.data.DueDate;
            }


            if (req.data.Status) {

                changes.Status =
                    req.data.Status;


                if (
                    req.data.Status ===
                    "Completed"
                ) {

                    changes.CompletedAt =
                        new Date();

                } else {

                    changes.CompletedAt =
                        null;
                }
            }


            await UPDATE(
                dbTasks
            )
                .set(
                    changes
                )
                .where({

                    ID:
                        taskID

                });


            var message =
                "Task updated successfully";


            req.notify(
                message
            );


            return message;
        }
    );


    // =====================================================
    // DELETE TASK
    // =====================================================

    service.on(
        "deleteTask",
        "Tasks",
        async function (req) {


            var taskID =
                req.params[
                    req.params.length - 1
                ].ID;


            if (!taskID) {

                return req.error(
                    400,
                    "Task ID not found"
                );
            }


            var dbTasks =
                cds.entities(
                    "project1.db"
                ).Tasks;


            await DELETE
                .from(
                    dbTasks
                )
                .where({

                    ID:
                        taskID

                });


            var message =
                "Task deleted successfully";


            req.notify(
                message
            );


            return message;
        }
    );


};