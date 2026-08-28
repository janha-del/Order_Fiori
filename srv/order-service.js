const cds = require("@sap/cds");
const {
    SELECT,
    INSERT,
    UPDATE
} = cds.ql;

const registerTaskHandlers =
    require("./task-handler");


module.exports = cds.service.impl(async function () {

    // =====================================================
    // CONNECT TO NORTHWIND
    // =====================================================

    const northwind =
        await cds.connect.to("Northwind");


    // Register existing Task handlers
    registerTaskHandlers(this);


    // =====================================================
    // ORDERS
    // =====================================================

    this.on(
        "READ",
        "Orders",
        async function (req) {


            // =================================================
            // CURRENT LOGGED-IN USER
            // =================================================

            console.log(
                "Logged-in user:",
                req.user.id,
                "| DISPLAY:",
                req.user.is("ZNW_ORD_DISPLAY"),
                "| COORD:",
                req.user.is("ZNW_ORD_COORD"),
                "| ANALYST:",
                req.user.is("ZNW_ORD_ANALYST")
            );


            // =================================================
            // COPY QUERY
            // =================================================

            const query =
                structuredClone(
                    req.query
                );


            // =================================================
            // SHIPPING STATUS FILTER
            // =================================================

            rewriteShippingStatusFilter(
                query,
                req
            );


            // =================================================
            // LIMIT LIST TO 100 ORDERS
            // =================================================

            if (
                !query.SELECT.one &&
                !query.SELECT.limit
            ) {

                query.SELECT.limit = {

                    rows: {
                        val: 100
                    }

                };
            }


            // =================================================
            // REMOVE VIRTUAL FIELDS BEFORE NORTHWIND CALL
            // =================================================

            if (
                query.SELECT.columns
            ) {

                const newColumns = [];

                let shippingStatusRequested =
                    false;


                for (
                    const column
                    of query.SELECT.columns
                ) {


                    // -----------------------------------------
                    // Non-field column
                    // -----------------------------------------

                    if (!column.ref) {

                        newColumns.push(
                            column
                        );

                        continue;
                    }


                    const fieldName =
                        column.ref[0];


                    // -----------------------------------------
                    // SHIPPING STATUS
                    // -----------------------------------------

                    if (
                        fieldName ===
                        "ShippingStatus"
                    ) {

                        shippingStatusRequested =
                            true;

                        continue;
                    }


                    // -----------------------------------------
                    // LOCAL / VIRTUAL FIELDS
                    // -----------------------------------------

                    const localVirtualFields = [

                        "TotalQuantity",

                        "NetOrderValue",

                        "CanMarkForReview",

                        "ReviewStatus",

                        "ReviewReason",

                        "MarkedBy",

                        "MarkedAt",

                        "AnalystComment",

                        "ReviewedBy",

                        "ReviewedAt",

                        "CanCompleteReview",

                        "CanRejectReview"

                    ];


                    if (
                        !localVirtualFields.includes(
                            fieldName
                        )
                    ) {

                        newColumns.push(
                            column
                        );
                    }
                }


                // -----------------------------------------
                // ShippingStatus needs these fields
                // -----------------------------------------

                if (
                    shippingStatusRequested
                ) {

                    addFieldIfMissing(
                        newColumns,
                        "ShippedDate"
                    );


                    addFieldIfMissing(
                        newColumns,
                        "RequiredDate"
                    );
                }


                query.SELECT.columns =
                    newColumns;
            }


            // =================================================
            // CALL NORTHWIND
            // =================================================

            const result =
                await northwind.run(
                    query
                );


            const rows =
                Array.isArray(result)
                    ? result
                    : [result];


            // =================================================
            // PROCESS ORDERS
            // =================================================

            for (
                const row
                of rows
            ) {

                if (!row) {

                    continue;
                }


                // -----------------------------------------
                // SHIPPING STATUS
                // -----------------------------------------

                row.ShippingStatus =
                    deriveShippingStatus(
                        row
                    );


                // -----------------------------------------
                // DEFAULT ACTION AVAILABILITY
                // -----------------------------------------

                row.CanMarkForReview =
                    req.user.is(
                        "ZNW_ORD_COORD"
                    );


                row.CanCompleteReview =
                    false;


                row.CanRejectReview =
                    false;


                // -----------------------------------------
                // Totals calculated only on Object Page
                // -----------------------------------------

                row.TotalQuantity =
                    null;


                row.NetOrderValue =
                    null;


                // -----------------------------------------
                // ORDER DETAILS LINE TOTAL
                // -----------------------------------------

                if (
                    row.Order_Details
                ) {

                    for (
                        const item
                        of row.Order_Details
                    ) {

                        const price =
                            Number(
                                item.UnitPrice ||
                                0
                            );


                        const quantity =
                            Number(
                                item.Quantity ||
                                0
                            );


                        const discount =
                            Number(
                                item.Discount ||
                                0
                            );


                        const lineTotal =
                            price *
                            quantity *
                            (
                                1 -
                                discount
                            );


                        item.LineTotal =
                            Number(
                                lineTotal.toFixed(
                                    2
                                )
                            );
                    }
                }
            }


            // =================================================
            // SINGLE ORDER OBJECT PAGE
            // =================================================

            if (
                query.SELECT.one &&
                rows[0]
            ) {

                const order =
                    rows[0];


                const orderID =
                    order.OrderID;


                // =============================================
                // ORDER TOTALS
                // =============================================

                const totals =
                    await calculateOrderTotals(
                        orderID,
                        northwind
                    );


                order.TotalQuantity =
                    totals.TotalQuantity;


                order.NetOrderValue =
                    totals.NetOrderValue;


                // =============================================
                // LOAD REVIEW FROM LOCAL HANA
                // =============================================

                const dbReviews =
                    cds.entities(
                        "project1.db"
                    ).OrderReviews;


                const review =
                    await SELECT
                        .one
                        .from(
                            dbReviews
                        )
                        .where({

                            OrderID:
                                orderID

                        });


                // =============================================
                // REVIEW EXISTS
                // =============================================

                if (review) {

                    order.ReviewStatus =
                        review.ReviewStatus;


                    order.ReviewReason =
                        review.ReviewReason;


                    order.MarkedBy =
                        review.MarkedBy;


                    order.MarkedAt =
                        review.MarkedAt;


                    order.AnalystComment =
                        review.AnalystComment;


                    order.ReviewedBy =
                        review.ReviewedBy;


                    order.ReviewedAt =
                        review.ReviewedAt;

                } else {


                    // =========================================
                    // NO REVIEW YET
                    // =========================================

                    order.ReviewStatus =
                        "Not Reviewed";


                    order.ReviewReason =
                        null;


                    order.MarkedBy =
                        null;


                    order.MarkedAt =
                        null;


                    order.AnalystComment =
                        null;


                    order.ReviewedBy =
                        null;


                    order.ReviewedAt =
                        null;
                }


                // =============================================
                // COORDINATOR ACTION
                // =============================================
                //
                // Coordinator can:
                //
                // Not Reviewed -> Mark for Review
                //
                // Rejected -> Mark again
                //
                // =============================================

                order.CanMarkForReview =

                    req.user.is(
                        "ZNW_ORD_COORD"
                    )

                    &&

                    (
                        order.ReviewStatus ===
                            "Not Reviewed"

                        ||

                        order.ReviewStatus ===
                            "Rejected"
                    );


                // =============================================
                // ANALYST - COMPLETE
                // =============================================

                order.CanCompleteReview =

                    req.user.is(
                        "ZNW_ORD_ANALYST"
                    )

                    &&

                    order.ReviewStatus ===
                        "Pending Review";


                // =============================================
                // ANALYST - REJECT
                // =============================================

                order.CanRejectReview =

                    req.user.is(
                        "ZNW_ORD_ANALYST"
                    )

                    &&

                    order.ReviewStatus ===
                        "Pending Review";


                // =============================================
                // TEMPORARY DEBUG LOG
                // =============================================

                console.log(

                    "Order:",
                    order.OrderID,

                    "| ReviewStatus:",
                    order.ReviewStatus,

                    "| CanMarkForReview:",
                    order.CanMarkForReview,

                    "| CanCompleteReview:",
                    order.CanCompleteReview,

                    "| CanRejectReview:",
                    order.CanRejectReview

                );
            }


            return result;
        }
    );


    // =====================================================
    // ORDER DETAILS
    // =====================================================

    this.on(
        "READ",
        "OrderDetails",
        async function (req) {

            const query =
                structuredClone(
                    req.query
                );


            // =================================================
            // REMOVE VIRTUAL LINETOTAL
            // =================================================

            if (
                query.SELECT.columns
            ) {

                const newColumns = [];

                let lineTotalRequested =
                    false;


                for (
                    const column
                    of query.SELECT.columns
                ) {


                    if (
                        column.ref &&
                        column.ref[0] ===
                            "LineTotal"
                    ) {

                        lineTotalRequested =
                            true;

                    } else {

                        newColumns.push(
                            column
                        );
                    }
                }


                // -----------------------------------------
                // Required for LineTotal
                // -----------------------------------------

                if (
                    lineTotalRequested
                ) {

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


            // =================================================
            // NORTHWIND CALL
            // =================================================

            const result =
                await northwind.run(
                    query
                );


            const rows =
                Array.isArray(result)
                    ? result
                    : [result];


            // =================================================
            // CALCULATE LINE TOTAL
            // =================================================

            for (
                const row
                of rows
            ) {

                if (!row) {

                    continue;
                }


                const price =
                    Number(
                        row.UnitPrice ||
                        0
                    );


                const quantity =
                    Number(
                        row.Quantity ||
                        0
                    );


                const discount =
                    Number(
                        row.Discount ||
                        0
                    );


                const lineTotal =
                    price *
                    quantity *
                    (
                        1 -
                        discount
                    );


                row.LineTotal =
                    Number(
                        lineTotal.toFixed(
                            2
                        )
                    );
            }


            return result;
        }
    );


    // =====================================================
    // CUSTOMERS
    // =====================================================

    this.on(
        "READ",
        "Customers",
        function (req) {

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
        function (req) {

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
        function (req) {

            return northwind.run(
                req.query
            );
        }
    );


    // =====================================================
    // MARK FOR REVIEW
    // =====================================================
    //
    // COORDINATOR
    //
    // =====================================================

    this.on(
        "markForReview",
        "Orders",
        async function (req) {

            const orderID =
                req.params[0].OrderID;


            // =============================================
            // REVIEW REASON REQUIRED
            // =============================================

            if (
                typeof req.data.ReviewReason !==
                    "string"

                ||

                !req.data.ReviewReason.trim()
            ) {

                return req.error(
                    400,
                    "Review Reason is required"
                );
            }


            const dbReviews =
                cds.entities(
                    "project1.db"
                ).OrderReviews;


            // =============================================
            // CHECK EXISTING REVIEW
            // =============================================

            const existing =
                await SELECT
                    .one
                    .from(
                        dbReviews
                    )
                    .where({

                        OrderID:
                            orderID

                    });


            // =============================================
            // ALREADY PENDING
            // =============================================

            if (
                existing &&
                existing.ReviewStatus ===
                    "Pending Review"
            ) {

                return req.error(
                    400,
                    "Order is already pending review"
                );
            }


            // =============================================
            // ALREADY COMPLETED
            // =============================================

            if (
                existing &&
                existing.ReviewStatus ===
                    "Reviewed"
            ) {

                return req.error(
                    400,
                    "Order review is already completed"
                );
            }


            // =============================================
            // REVIEW DATA
            // =============================================

            const reviewData = {

                ReviewStatus:
                    "Pending Review",

                ReviewReason:
                    req.data.ReviewReason.trim(),

                MarkedBy:
                    req.user.id,

                MarkedAt:
                    new Date(),

                AnalystComment:
                    null,

                ReviewedBy:
                    null,

                ReviewedAt:
                    null

            };


            // =============================================
            // UPDATE EXISTING REVIEW
            // =============================================

            if (existing) {

                await UPDATE(
                    dbReviews
                )
                    .set(
                        reviewData
                    )
                    .where({

                        OrderID:
                            orderID

                    });

            } else {


                // =========================================
                // CREATE NEW REVIEW
                // =========================================

                await INSERT
                    .into(
                        dbReviews
                    )
                    .entries({

                        OrderID:
                            orderID,

                        ...reviewData

                    });
            }


            const message =
                "Order " +
                orderID +
                " marked for review";


            req.notify(
                message
            );


            return message;
        }
    );


    // =====================================================
    // COMPLETE REVIEW
    // =====================================================
    //
    // ANALYST
    //
    // =====================================================

    this.on(
        "completeReview",
        "Orders",
        async function (req) {

            const orderID =
                req.params[0].OrderID;


            const dbReviews =
                cds.entities(
                    "project1.db"
                ).OrderReviews;


            // =============================================
            // GET REVIEW
            // =============================================

            const review =
                await SELECT
                    .one
                    .from(
                        dbReviews
                    )
                    .where({

                        OrderID:
                            orderID

                    });


            if (!review) {

                return req.error(
                    404,
                    "Review record not found"
                );
            }


            // =============================================
            // MUST BE PENDING
            // =============================================

            if (
                review.ReviewStatus !==
                    "Pending Review"
            ) {

                return req.error(
                    400,
                    "Order is not pending review"
                );
            }


            // =============================================
            // ANALYST COMMENT
            // =============================================

            let analystComment =
                req.data.AnalystComment;


            if (
                typeof analystComment ===
                    "string"
            ) {

                analystComment =
                    analystComment.trim();
            }


            // =============================================
            // COMPLETE REVIEW
            // =============================================

            await UPDATE(
                dbReviews
            )
                .set({

                    ReviewStatus:
                        "Reviewed",

                    AnalystComment:
                        analystComment ||
                        null,

                    ReviewedBy:
                        req.user.id,

                    ReviewedAt:
                        new Date()

                })
                .where({

                    OrderID:
                        orderID

                });


            const message =
                "Order " +
                orderID +
                " review completed";


            req.notify(
                message
            );


            return message;
        }
    );


    // =====================================================
    // REJECT REVIEW
    // =====================================================
    //
    // ANALYST
    //
    // =====================================================

    this.on(
        "rejectReview",
        "Orders",
        async function (req) {

            const orderID =
                req.params[0].OrderID;


            // =============================================
            // REJECTION REASON REQUIRED
            // =============================================

            if (
                typeof req.data.AnalystComment !==
                    "string"

                ||

                !req.data.AnalystComment.trim()
            ) {

                return req.error(
                    400,
                    "Rejection Reason is required"
                );
            }


            const dbReviews =
                cds.entities(
                    "project1.db"
                ).OrderReviews;


            // =============================================
            // GET REVIEW
            // =============================================

            const review =
                await SELECT
                    .one
                    .from(
                        dbReviews
                    )
                    .where({

                        OrderID:
                            orderID

                    });


            if (!review) {

                return req.error(
                    404,
                    "Review record not found"
                );
            }


            // =============================================
            // MUST BE PENDING
            // =============================================

            if (
                review.ReviewStatus !==
                    "Pending Review"
            ) {

                return req.error(
                    400,
                    "Order is not pending review"
                );
            }


            // =============================================
            // REJECT
            // =============================================

            await UPDATE(
                dbReviews
            )
                .set({

                    ReviewStatus:
                        "Rejected",

                    AnalystComment:
                        req.data.AnalystComment.trim(),

                    ReviewedBy:
                        req.user.id,

                    ReviewedAt:
                        new Date()

                })
                .where({

                    OrderID:
                        orderID

                });


            const message =
                "Order " +
                orderID +
                " review rejected";


            req.notify(
                message
            );


            return message;
        }
    );

});


// =========================================================
// DERIVE SHIPPING STATUS
// =========================================================

function deriveShippingStatus(
    order
) {


    // =====================================================
    // SHIPPED
    // =====================================================

    if (
        order.ShippedDate
    ) {

        return "Shipped";
    }


    const today =
        new Date();


    today.setHours(
        0,
        0,
        0,
        0
    );


    // =====================================================
    // NO REQUIRED DATE
    // =====================================================

    if (
        !order.RequiredDate
    ) {

        return "Open";
    }


    const requiredDate =
        new Date(
            order.RequiredDate
        );


    requiredDate.setHours(
        0,
        0,
        0,
        0
    );


    // =====================================================
    // OVERDUE
    // =====================================================

    if (
        requiredDate <
        today
    ) {

        return "Overdue";
    }


    // =====================================================
    // DUE SOON
    // =====================================================

    const dueSoonDate =
        new Date(
            today
        );


    dueSoonDate.setDate(

        dueSoonDate.getDate() +
        7

    );


    if (
        requiredDate <=
        dueSoonDate
    ) {

        return "Due Soon";
    }


    // =====================================================
    // OPEN
    // =====================================================

    return "Open";
}


// =========================================================
// SHIPPING STATUS FILTER
// =========================================================

function rewriteShippingStatusFilter(
    query,
    req
) {

    if (
        !query.SELECT.where
    ) {

        return;
    }


    query.SELECT.where =
        rewriteFilterParts(
            query.SELECT.where,
            req
        );
}


// =========================================================
// REWRITE FILTER PARTS
// =========================================================

function rewriteFilterParts(
    parts,
    req
) {

    const newParts = [];


    for (
        let i = 0;
        i < parts.length;
        i++
    ) {

        const part =
            parts[i];


        // =================================================
        // PARENTHESES
        // =================================================

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


        // =================================================
        // SHIPPING STATUS FILTER
        // =================================================

        if (
            part &&
            part.ref &&
            part.ref[0] ===
                "ShippingStatus" &&
            parts[i + 1] ===
                "=" &&
            parts[i + 2]
        ) {

            const status =
                parts[i + 2].val;


            newParts.push({

                xpr:
                    createShippingStatusCondition(
                        status,
                        req
                    )

            });


            i =
                i +
                2;


            continue;
        }


        newParts.push(
            part
        );
    }


    return newParts;
}


// =========================================================
// CREATE SHIPPING STATUS CONDITION
// =========================================================

function createShippingStatusCondition(
    status,
    req
) {

    const today =
        new Date();


    today.setHours(
        0,
        0,
        0,
        0
    );


    const dueSoonDate =
        new Date(
            today
        );


    dueSoonDate.setDate(

        dueSoonDate.getDate() +
        7

    );


    const todayText =
        today.toISOString();


    const dueSoonText =
        dueSoonDate.toISOString();


    // =====================================================
    // SHIPPED
    // =====================================================

    if (
        status ===
        "Shipped"
    ) {

        return [

            {
                ref: [
                    "ShippedDate"
                ]
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

    if (
        status ===
        "Overdue"
    ) {

        return [

            {
                ref: [
                    "ShippedDate"
                ]
            },

            "=",

            {
                val: null
            },

            "and",

            {
                ref: [
                    "RequiredDate"
                ]
            },

            "<",

            {
                val:
                    todayText
            }

        ];
    }


    // =====================================================
    // DUE SOON
    // =====================================================

    if (
        status ===
        "Due Soon"
    ) {

        return [

            {
                ref: [
                    "ShippedDate"
                ]
            },

            "=",

            {
                val: null
            },

            "and",

            {
                ref: [
                    "RequiredDate"
                ]
            },

            ">=",

            {
                val:
                    todayText
            },

            "and",

            {
                ref: [
                    "RequiredDate"
                ]
            },

            "<=",

            {
                val:
                    dueSoonText
            }

        ];
    }


    // =====================================================
    // OPEN
    // =====================================================

    if (
        status ===
        "Open"
    ) {

        return [

            {
                ref: [
                    "ShippedDate"
                ]
            },

            "=",

            {
                val: null
            },

            "and",

            {
                ref: [
                    "RequiredDate"
                ]
            },

            ">",

            {
                val:
                    dueSoonText
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
// CALCULATE ORDER TOTALS
// =========================================================

async function calculateOrderTotals(
    orderID,
    northwind
) {

    const items =
        await northwind.run(

            SELECT
                .from(
                    "Northwind.Order_Details"
                )
                .where({

                    OrderID:
                        orderID

                })

        );


    let totalQuantity =
        0;


    let netOrderValue =
        0;


    for (
        const item
        of items
    ) {

        const price =
            Number(
                item.UnitPrice ||
                0
            );


        const quantity =
            Number(
                item.Quantity ||
                0
            );


        const discount =
            Number(
                item.Discount ||
                0
            );


        totalQuantity =
            totalQuantity +
            quantity;


        netOrderValue =
            netOrderValue +
            (
                price *
                quantity *
                (
                    1 -
                    discount
                )
            );
    }


    return {

        TotalQuantity:
            totalQuantity,


        NetOrderValue:
            Number(
                netOrderValue.toFixed(
                    2
                )
            )

    };
}


// =========================================================
// ADD FIELD IF MISSING
// =========================================================

function addFieldIfMissing(
    columns,
    fieldName
) {

    const found =
        columns.some(

            function (
                column
            ) {

                return (

                    column.ref &&

                    column.ref[0] ===
                        fieldName

                );
            }

        );


    if (!found) {

        columns.push({

            ref: [
                fieldName
            ]

        });
    }
}