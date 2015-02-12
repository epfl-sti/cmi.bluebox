/**
 * Routes for the RESTful API
 */

var express = require('express');
var router = express.Router();

var VPNModel = require("../model/vpn.js");
var BBXModel = require("../model/bbx.js");

/* TODO: de-bogosify */
router.get('/vpn', function(req, res, next) {
    var vpn_data =  [
        {title: "Foo", detail: "Foofoo", bbxs:["bboo", "bbar"]},
        {title: "Bar", detail: "Foobar", bbxs:["bbar2"]},
        {title: "Baz", detail: "Foobaz", bbxs:["bbaz"]}
    ];
    res.json(VPNModel.sort(vpn_data, req.query._sortField, req.query._sortDir));
});

router.get('/vpn/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    VPNModel.validName(stem);
    res.json({title: stem, detail: "Foo" + stem});
});

router.get('/bbx', function(req, res, next) {
    var bbx_data = [
        {title: "bboo", vpn: "Foo", detail: "Booboo"},
        {title: "bbar", vpn: "Foo", detail: "Boobar"},
        {title: "bbar2", vpn: "Bar", detail: "Boobar2"},
        {title: "bbaz", vpn: "Bazz", detail: "Boobaz"}
    ];
    res.json(BBXModel.sort(bbx_data, req.query._sortField, req.query._sortDir));
});

router.get('/bbx/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    BBXModel.validName(stem);
    res.json({title: stem, vpn: "Bazz", detail: "Foo" + stem});
});

module.exports = router;
