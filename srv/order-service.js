const cds = require("@sap/cds");
const { SELECT } = cds.ql;


module.exports = cds.service.impl(async function () {

    // Connect to Northwind
    var northwind = await cds.connect.to("Northwind");


    // =====================================================
    // ORDERS
    // =====================================================
    this.on("READ", "Orders", async function (req) {

        // Copy the incoming request
        var query = structuredClone(req.query);


        // -------------------------------------------------
        // Rewrite ShippingStatus filter
        // -------------------------------------------------
        rewriteShippingStatusFilter(query, req);


        // -------------------------------------------------
        // Limit Orders LIST to 100
        // -------------------------------------------------
        //
        // Do not add the limit when requesting one Order:
        // Orders(10250)
        //
        if (!query.SELECT.one && !query.SELECT.limit) {

            query.SELECT.limit = {
                rows: {
                    val: 100
                }
            };
        }


        // -------------------------------------------------
        // Remove virtual fields
        // -------------------------------------------------
        //
        // Northwind does not contain:
        //
        // ShippingStatus
        // TotalQuantity
        // NetOrderValue
        //
        if (query.SELECT.columns) {

            var newColumns = [];

            var shippingStatusRequested = false;


            for (var i = 0; i < query.SELECT.columns.length; i++) {

                var column = query.SELECT.columns[i];


                if (column.ref) {

                    var fieldName = column.ref[0];


                    if (fieldName === "ShippingStatus") {

                        shippingStatusRequested = true;

                    } else if (
                        fieldName !== "TotalQuantity" &&
                        fieldName !== "NetOrderValue"
                    ) {

                        newColumns.push(column);
                    }

                } else {

                    newColumns.push(column);
                }
            }


            // ShippingStatus calculation needs
            // ShippedDate and RequiredDate
            if (shippingStatusRequested) {

                addFieldIfMissing(
                    newColumns,
                    "ShippedDate"
                );

                addFieldIfMissing(
                    newColumns,
                    "RequiredDate"
                );
            }


            query.SELECT.columns = newColumns;
        }


        // -------------------------------------------------
        // Call Northwind
        // -------------------------------------------------
        var result = await northwind.run(query);


        // -------------------------------------------------
        // Convert result into an array
        // -------------------------------------------------
        var rows;

        if (Array.isArray(result)) {

            rows = result;

        } else {

            rows = [result];
        }


        // -------------------------------------------------
        // Calculate ShippingStatus
        // -------------------------------------------------
        for (var j = 0; j < rows.length; j++) {

            if (rows[j]) {

                rows[j].ShippingStatus =
                    deriveShippingStatus(rows[j]);


                // List page should not calculate totals
                rows[j].TotalQuantity = null;

                rows[j].NetOrderValue = null;
            }
        }


        // -------------------------------------------------
        // Calculate totals for ONE Order only
        // -------------------------------------------------
        //
        // Example:
        //
        // /Orders(10250)
        //
        if (query.SELECT.one && rows[0]) {

            var orderID =
                rows[0].OrderID;


            var totals =
                await calculateOrderTotals(
                    orderID,
                    northwind
                );


            rows[0].TotalQuantity =
                totals.TotalQuantity;


            rows[0].NetOrderValue =
                totals.NetOrderValue;
        }


        return result;
    });



    // =====================================================
    // ORDER DETAILS
    // =====================================================
    this.on("READ", "OrderDetails", async function (req) {

        var query =
            structuredClone(req.query);


        // -------------------------------------------------
        // Remove LineTotal
        // -------------------------------------------------
        //
        // Northwind does not contain LineTotal.
        //
        if (query.SELECT.columns) {

            var newColumns = [];

            var lineTotalRequested = false;


            for (var i = 0; i < query.SELECT.columns.length; i++) {

                var column =
                    query.SELECT.columns[i];


                if (column.ref) {

                    var fieldName =
                        column.ref[0];


                    if (fieldName === "LineTotal") {

                        lineTotalRequested = true;

                    } else {

                        newColumns.push(column);
                    }

                } else {

                    newColumns.push(column);
                }
            }


            // LineTotal needs these fields
            if (lineTotalRequested) {

                addFieldIfMissing(
                    newColumns,
                    "UnitPrice"
                );

                addFieldIfMissing(
                    newColumns,
                    "Quantity"
                );

                addFieldIfMissing(
                    newColumns,
                    "Discount"
                );
            }


            query.SELECT.columns =
                newColumns;
        }


        // -------------------------------------------------
        // Call Northwind
        // -------------------------------------------------
        var result =
            await northwind.run(query);


        var rows;

        if (Array.isArray(result)) {

            rows = result;

        } else {

            rows = [result];
        }


        // -------------------------------------------------
        // Calculate LineTotal
        // -------------------------------------------------
        for (var j = 0; j < rows.length; j++) {

            var row =
                rows[j];


            if (row) {

                var price =
                    Number(row.UnitPrice || 0);


                var quantity =
                    Number(row.Quantity || 0);


                var discount =
                    Number(row.Discount || 0);


                var lineTotal =
                    price *
                    quantity *
                    (1 - discount);


                row.LineTotal =
                    Number(
                        lineTotal.toFixed(2)
                    );
            }
        }


        return result;
    });



    // =====================================================
    // CUSTOMERS
    // =====================================================
    this.on(
        "READ",
        "Customers",
        async function (req) {

            return northwind.run(
                req.query
            );
        }
    );



    // =====================================================
    // EMPLOYEES
    // =====================================================
    this.on(
        "READ",
        "Employees",
        async function (req) {

            return northwind.run(
                req.query
            );
        }
    );



    // =====================================================
    // SHIPPERS
    // =====================================================
    this.on(
        "READ",
        "Shippers",
        async function (req) {

            return northwind.run(
                req.query
            );
        }
    );



    // =====================================================
    // MARK FOR REVIEW
    // =====================================================
    //
    // This action does NOT update Northwind.
    //
    // It only returns a message for Phase 1.
    //
    this.on(
        "markForReview",
        "Orders",
        async function (req) {

            var orderID =
                req.params[0].OrderID;


            var message =
                "Order " +
                orderID +
                " marked for review (prototype only)";


            console.log(message);


            return message;
        }
    );

});



// =========================================================
// SHIPPING STATUS CALCULATION
// =========================================================
function deriveShippingStatus(order) {


    // -----------------------------------------------------
    // SHIPPED
    // -----------------------------------------------------
    if (order.ShippedDate) {

        return "Shipped";
    }


    var today =
        new Date();


    today.setHours(
        0,
        0,
        0,
        0
    );


    // -----------------------------------------------------
    // No RequiredDate
    // -----------------------------------------------------
    if (!order.RequiredDate) {

        return "Open";
    }


    var requiredDate =
        new Date(
            order.RequiredDate
        );


    requiredDate.setHours(
        0,
        0,
        0,
        0
    );


    // -----------------------------------------------------
    // OVERDUE
    // -----------------------------------------------------
    if (requiredDate < today) {

        return "Overdue";
    }


    // -----------------------------------------------------
    // Today + 7 days
    // -----------------------------------------------------
    var dueSoonDate =
        new Date(today);


    dueSoonDate.setDate(
        dueSoonDate.getDate() + 7
    );


    // -----------------------------------------------------
    // DUE SOON
    // -----------------------------------------------------
    if (requiredDate <= dueSoonDate) {

        return "Due Soon";
    }


    // -----------------------------------------------------
    // OPEN
    // -----------------------------------------------------
    return "Open";
}



// =========================================================
// SHIPPING STATUS FILTER
// =========================================================
function rewriteShippingStatusFilter(query, req) {

    var where =
        query.SELECT.where;


    // No filter
    if (!where) {

        return;
    }


    // Rewrite the filter
    query.SELECT.where =
        rewriteFilterParts(
            where,
            req
        );
}



// =========================================================
// REWRITE FILTER PARTS
// =========================================================
//
// This allows combinations like:
//
// CustomerID eq 'ERNSH'
// AND
// ShippingStatus eq 'Overdue'
//
function rewriteFilterParts(parts, req) {

    var newParts = [];


    for (var i = 0; i < parts.length; i++) {

        var part =
            parts[i];


        // -------------------------------------------------
        // Handle filters inside parentheses
        // -------------------------------------------------
        if (
            part &&
            part.xpr
        ) {

            newParts.push({

                xpr:
                    rewriteFilterParts(
                        part.xpr,
                        req
                    )
            });


            continue;
        }


        // -------------------------------------------------
        // Check for ShippingStatus
        // -------------------------------------------------
        if (
            part &&
            part.ref &&
            part.ref[0] === "ShippingStatus" &&
            parts[i + 1] === "=" &&
            parts[i + 2]
        ) {

            var status =
                parts[i + 2].val;


            var condition =
                createShippingStatusCondition(
                    status,
                    req
                );


            newParts.push({
                xpr: condition
            });


            // Skip:
            //
            // ShippingStatus
            // =
            // value
            //
            i = i + 2;


            continue;
        }


        // Normal filter
        newParts.push(part);
    }


    return newParts;
}



// =========================================================
// CREATE SHIPPING STATUS CONDITION
// =========================================================
function createShippingStatusCondition(status, req) {


    var today =
        new Date();


    today.setHours(
        0,
        0,
        0,
        0
    );


    var dueSoonDate =
        new Date(today);


    dueSoonDate.setDate(
        dueSoonDate.getDate() + 7
    );


    var todayText =
        today.toISOString();


    var dueSoonText =
        dueSoonDate.toISOString();



    // =====================================================
    // SHIPPED
    // =====================================================
    if (status === "Shipped") {

        return [

            {
                ref: ["ShippedDate"]
            },

            "!=",

            {
                val: null
            }

        ];
    }



    // =====================================================
    // OVERDUE
    // =====================================================
    if (status === "Overdue") {

        return [

            {
                ref: ["ShippedDate"]
            },

            "=",

            {
                val: null
            },

            "and",

            {
                ref: ["RequiredDate"]
            },

            "<",

            {
                val: todayText
            }

        ];
    }



    // =====================================================
    // DUE SOON
    // =====================================================
    if (status === "Due Soon") {

        return [

            {
                ref: ["ShippedDate"]
            },

            "=",

            {
                val: null
            },

            "and",

            {
                ref: ["RequiredDate"]
            },

            ">=",

            {
                val: todayText
            },

            "and",

            {
                ref: ["RequiredDate"]
            },

            "<=",

            {
                val: dueSoonText
            }

        ];
    }



    // =====================================================
    // OPEN
    // =====================================================
    if (status === "Open") {

        return [

            {
                ref: ["ShippedDate"]
            },

            "=",

            {
                val: null
            },

            "and",

            {
                ref: ["RequiredDate"]
            },

            ">",

            {
                val: dueSoonText
            }

        ];
    }



    // =====================================================
    // INVALID STATUS
    // =====================================================
    req.reject(
        400,
        "ShippingStatus must be Shipped, Overdue, Due Soon, or Open"
    );
}



// =========================================================
// ORDER TOTAL CALCULATION
// =========================================================
async function calculateOrderTotals(
    orderID,
    northwind
) {


    // -----------------------------------------------------
    // Get OrderDetails for this Order
    // -----------------------------------------------------
    var items =
        await northwind.run(

            SELECT
                .from(
                    "Northwind.Order_Details"
                )
                .where({
                    OrderID: orderID
                })

        );


    var totalQuantity = 0;

    var netOrderValue = 0;


    // -----------------------------------------------------
    // Loop through all OrderDetails
    // -----------------------------------------------------
    for (var i = 0; i < items.length; i++) {


        var price =
            Number(
                items[i].UnitPrice || 0
            );


        var quantity =
            Number(
                items[i].Quantity || 0
            );


        var discount =
            Number(
                items[i].Discount || 0
            );


        // LineTotal
        var lineTotal =
            price *
            quantity *
            (1 - discount);


        // Total Quantity
        totalQuantity =
            totalQuantity +
            quantity;


        // Net Order Value
        netOrderValue =
            netOrderValue +
            lineTotal;
    }


    return {

        TotalQuantity:
            totalQuantity,


        NetOrderValue:
            Number(
                netOrderValue.toFixed(2)
            )
    };
}



// =========================================================
// ADD FIELD IF MISSING
// =========================================================
//
// Used when a calculated field requires
// another Northwind field.
//
function addFieldIfMissing(columns, fieldName) {


    var found = false;


    for (var i = 0; i < columns.length; i++) {

        if (
            columns[i].ref &&
            columns[i].ref[0] === fieldName
        ) {

            found = true;

            break;
        }
    }


    if (!found) {

        columns.push({

            ref: [fieldName]

        });
    }
}