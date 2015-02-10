/**
 * Routes for the RESTful API
 */

var express = require('express');
var router = express.Router();

var VPNModel = require("../model/vpn.js");

/* TODO: de-bogosify */
router.get('/vpn', function(req, res, next) {
    res.json([{title: "Foo", detail: "Foofoo"}, {title: "Bar", detail: "Foobar"}, {title: "Baz", detail: "Foobaz"}]);
});

router.get('/vpn/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    VPNModel.validName(stem);
    res.json({title: stem, detail: "Foo" + stem});
});

router.get('/bbx', function(req, res, next) {
    res.json([
        {title: "bboo", vpn: "Foo", detail: "Booboo"},
        {title: "bbar", vpn: "Foo", detail: "Boobar"},
        {title: "bbar2", vpn: "Bar", detail: "Boobar2"},
        {title: "bbaz", vpn: "Bazz", detail: "Boobaz"}
    ]);
});

router.get('/bbx/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    VPNModel.validName(stem);
    res.json({title: stem, detail: "Foo" + stem});
});

module.exports = router;
