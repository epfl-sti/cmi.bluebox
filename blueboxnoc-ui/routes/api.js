/**
 * Routes for the RESTful API
 */
// @todo: check the http://expressjs.com/api.html#app.param to regexp the route without validator
var express = require('express');
var router = express.Router();

var Model = require("../model");

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

    /* Serve e.g. /vpn/* */
    router.get(api_path + '/*', function(req, res, next) {
        var urlparts = req.url.split("/");
        var stem = urlparts.pop();
        if (model.validName) {
            model.validName(stem);
        }
        /* There has to be a better way than an exhaustive search here. */
        model.all(function(all, error) {
            if (error) {
                return next(error);
            }
            var done;
            all.forEach(function (value, index) {
                if (! done && value.name == stem) {
                    res.json(value);
                    done = true;
                }
            });
            if (! done) {
                next({message: "Unknown resource " + req.url});
            }
        });
    });
}

configure_API_subdir(router, "/vpn", Model.VPN);
configure_API_subdir(router, "/vnc", Model.VNCTarget);
configure_API_subdir(router, "/bbx", Model.BBox);
configure_API_subdir(router, "/user", Model.User);
configure_API_subdir(router, "/group", Model.Group);
configure_API_subdir(router, "/status", Model.Status);

module.exports = router;
