/**
 * Routes for the RESTful API
 */
// @todo: check the http://expressjs.com/api.html#app.param to regexp the route without validator
var router = require('express').Router(),
    Model = require("../model"),
    perl = require("../lib/perl");

/**
 * Configure the router object to serve the API for a model class.
 * @param router The express.Router object
 * @param api_path The URI sub-path to the API, e.g. "/vpn"
 * @param model One of the model.Foo classes
 */
function configure_API_subdir(router, api_path, model) {
    /* Serve e.g. /vpn */
    router.get(api_path, function(req, res, next) {
        model.all(function (all, error) {
            if (error) {
                return next(error);
            }
            res.json(Model.sort(all, req.query._sortField, req.query._sortDir));
        });
    });

    /* Serve e.g. /vpn/foo */
    router.get(api_path + '/*', function(req, res, next) {
        var urlparts = req.url.split("/");
        var stem = urlparts.pop();
        if (model.primaryKey.validate) {
            model.primaryKey.validate(stem);
        }
        /* There has to be a better way than an exhaustive search here. */
        model.all(function(all, error) {
            if (error) {
                return next(error);
            }
            var done;
            all.forEach(function (value, index) {
                if (! done && value[model.primaryKey.name] == stem) {
                    res.json(value);
                    done = true;
                }
            });
            if (! done) {
                next({message: "Unknown resource " + req.url});
            }
        });
    });

    if (model.perlControllerPackage) {
        router.post(api_path, function(req, res, next) {
            perl.talkJSONToPerl(
                "use " + model.perlControllerPackage + "; "
                    + model.perlControllerPackage + "->post_from_stdin;",
                req.body,
                function (result, err) {
                    if (err) {
                        return next(err);
                    }
                    res.json(result);
                }
            )
        });
        router.delete(api_path, function(req, res, next) {
            perl.talkJSONToPerl(
                "use " + model.perlControllerPackage + "; "
                + model.perlControllerPackage + "->delete_from_stdin;",
                req.body,
                function (result, err) {
                    if (err) {
                        return next(err);
                    }
                    res.json(result);
                }
            )
        });
    }
}

configure_API_subdir(router, "/vpn", Model.VPN);
configure_API_subdir(router, "/vnc", Model.VNCTarget);
configure_API_subdir(router, "/bbx", Model.BBox);
configure_API_subdir(router, "/user", Model.User);
configure_API_subdir(router, "/group", Model.Group);
configure_API_subdir(router, "/status", Model.Status);

module.exports = router;
