/**
 * Routes for the RESTful API
 */
// @todo: check the http://expressjs.com/api.html#app.param to regexp the route without validator
var express = require('express');
var router = express.Router();

var Model = require("../model");

router.get('/vpn', function(req, res, next) {
    res.json(Model.sort(Model.VPN.all(),
                        req.query._sortField, req.query._sortDir));
});

router.get('/vpn/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    Model.VPN.validName(stem);
    Model.VPN.all().forEach(function (value, index) {
        if (value.name == stem) {
            return res.json(value);
        }
    });
});

router.get('/bbx', function(req, res, next) {
    res.json(Model.sort(Model.BBox.all(), req.query._sortField, req.query._sortDir));
});

router.get('/bbx/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    Model.BBox.validName(stem);
    Model.BBox.all().forEach(function (value, index) {
        if (value.name == stem) {
            return res.json(value);
        }
    });
});

router.get('/vnc', function(req, res, next) {
    res.json(Model.sort(Model.VNCTarget.all(), req.query._sortField, req.query._sortDir));
});

router.get('/vnc/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    Model.VNCTarget.validName(stem);
    Model.VNCTarget.all().forEach(function (value, index) {
        if (value.name == stem) {
            return res.json(value);
        }
    });
});


router.get('/user', function(req, res, next) {
    res.json(Model.sort(Model.User.all(), req.query._sortField, req.query._sortDir));
});

router.get('/user/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    Model.User.all().forEach(function (value, index) {
        if (value == stem) {
            return res.json(value);
        }
    });
});

module.exports = router;
