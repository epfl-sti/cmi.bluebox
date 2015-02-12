/**
 * Routes for the RESTful API
 */

var express = require('express');
var router = express.Router();

var VPNModel = require("../model/vpn.js");
var BBXModel = require("../model/bbx.js");

/* TODO: de-bogosify */
router.get('/vpn', function(req, res, next) {
    res.json([
        {title: "Foo", detail: "Foofoo", bbxs:["bboo", "bbar"]},
        {title: "Bar", detail: "Foobar", bbxs:["bbar2"]},
        {title: "Baz", detail: "Foobaz", bbxs:["bbaz"]}]);
});

router.get('/vpn/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    VPNModel.validName(stem);
    res.json({title: stem, detail: "Foo" + stem});
});

router.get('/bbx', function(req, res, next) {
    var filters =  req.query._filters;
    console.log(filters);
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
    BBXModel.validName(stem);
    res.json({title: stem, vpn: "Bazz", detail: "Foo" + stem});
});

module.exports = router;
