const cds = require("@sap/cds");

module.exports = cds.service.impl(async function () {

    const northwind = await cds.connect.to("Northwind");

   this.on("READ", "Orders", async (req) => {

    const result = await northwind.run(req.query);

    const rows = Array.isArray(result) ? result : [result];

    for (const row of rows) {
        row.ShippingStatus = deriveShippingStatus(row);
    }

    return result;
});

    this.on("READ", "OrderDetails", async (req) => {
        return northwind.run(req.query);
    });

    this.on("READ", "Customers", async (req) => {
        return northwind.run(req.query);
    });

    this.on("READ", "Employees", async (req) => {
        return northwind.run(req.query);
    });

    this.on("READ", "Shippers", async (req) => {
        return northwind.run(req.query);
    });

});


function deriveShippingStatus(order) {

    if (order.ShippedDate) {
        return "Shipped";
    }

    const today = new Date();
    const requiredDate = order.RequiredDate
        ? new Date(order.RequiredDate)
        : null;

    if (requiredDate && requiredDate < today) {
        return "Overdue";
    }

    if (requiredDate) {
        const dueSoonDate = new Date();
        dueSoonDate.setDate(dueSoonDate.getDate() + 7);

        if (requiredDate <= dueSoonDate) {
            return "Due Soon";
        }
    }

    return "Open";
}