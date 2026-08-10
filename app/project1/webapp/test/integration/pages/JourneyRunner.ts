import JourneyRunner from "sap/fe/test/JourneyRunner";
import ListReport from "sap/fe/test/ListReport";
import ObjectPage from "sap/fe/test/ObjectPage";
import CustomOrdersListGenerated from "./OrdersList.gen";
import CustomOrdersObjectPageGenerated from "./OrdersObjectPage.gen";
import CustomOrderDetailsObjectPageGenerated from "./OrderDetailsObjectPage.gen";

const runner = new JourneyRunner({
    launchUrl: sap.ui.require.toUrl("project1") + "/test/flp.html#app-preview",
    pages: {
        onTheOrdersListGenerated: new ListReport(
            {
                appId: "project1",
                componentId: "OrdersList",
                entitySet: "",
                contextPath: "/Orders"
            },
            CustomOrdersListGenerated
        ),
        onTheOrdersObjectPageGenerated: new ObjectPage(
            {
                appId: "project1",
                componentId: "OrdersObjectPage",
                entitySet: "",
                contextPath: "/Orders"
            },
            CustomOrdersObjectPageGenerated
        ),
        onTheOrderDetailsObjectPageGenerated: new ObjectPage(
            {
                appId: "project1",
                componentId: "OrderDetailsObjectPage",
                entitySet: "",
                contextPath: "/Orders/Order_Details"
            },
            CustomOrderDetailsObjectPageGenerated
        )
    },
    async: true
});

export default runner;
