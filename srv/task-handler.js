module.exports = function (service) {

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
        }
    );
};