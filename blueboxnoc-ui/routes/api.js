/**
 * Routes for the RESTful API
 */
// @todo: check the http://expressjs.com/api.html#app.param to regexp the route without validator
var express = require('express');
var router = express.Router();

var VPNModel = require("../model/vpn.js");
var BBXModel = require("../model/bbx.js");
var VNCModel = require("../model/vnc.js");
var USERModel = require("../model/user.js");

/* TODO: de-bogosify */

// fake vpn data
var vpn_data =  [
    {title: "Foo", detail: "Foofoo", bbxs:["bboo", "bbar"]},
    {title: "Bar", detail: "Foobar", bbxs:["bbar2"]},
    {title: "Baz", detail: "Foobaz", bbxs:["bbaz"]},
    {title: "Bax", detail: "Foobax", bbxs:["bboo", "bbaz"]}
];
router.get('/vpn', function(req, res, next) {
    res.json(VPNModel.sort(vpn_data, req.query._sortField, req.query._sortDir));
});

router.get('/vpn/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    VPNModel.validName(stem);
    vpn_data.forEach(function (value, index) {
        if (vpn_data[index].title == stem) {
            return res.json(vpn_data[index]);
        }
    });
});


// fake bbx data
var bbx_data = [
    {title: "bboo", vpn: "Foo", detail: "Booboo"},
    {title: "bbar", vpn: "Foo", detail: "Boobar"},
    {title: "bbar2", vpn: "Bar", detail: "Boobar2"},
    {title: "bbaz", vpn: "Baz", detail: "Boobaz"}
];
router.get('/bbx', function(req, res, next) {
    res.json(BBXModel.sort(bbx_data, req.query._sortField, req.query._sortDir));
});

router.get('/bbx/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    BBXModel.validName(stem);
    bbx_data.forEach(function (value, index) {
        if (bbx_data[index].title == stem) {
            return res.json(bbx_data[index]);
        }
    });
});


// fake vnc data
var vnc_data = [
    {title: "vnc1", ip:"192.168.10.10", port:"5900", vpn: "Foo", detail: "detail of my first vnc"},
    {title: "vnc1", ip:"192.168.20.20", port:"5900", vpn: "Bar", detail: "detail of my second vnc"},
    {title: "vnc3", ip:"192.168.30.30", port:"5900", vpn: "Bar", detail: "detail of my third vnc"},
    {title: "vnc4", ip:"192.168.40.40", port:"5901", vpn: "Baz", detail: "detail of my fourth vnc"},
    {title: "vnc5", ip:"192.168.50.50", port:"5901", vpn: "Bax", detail: "detail of my fifth vnc"}
];
router.get('/vnc', function(req, res, next) {
    res.json(VNCModel.sort(vnc_data, req.query._sortField, req.query._sortDir));
});

router.get('/vnc/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    VNCModel.validName(stem);
    vnc_data.forEach(function (value, index) {
        if (vnc_data[index].title == stem) {
            return res.json(vnc_data[index]);
        }
    });
});


// fake users data
var users_data = [
    //{username: "user1", sciper:"100100", email:"foo.bar@epfl.ch", group: ["Foo", "Bar", "Baz"], detail: "detail of my first users"},
    // @todo check map function to get group in an array (https://github.com/marmelab/ng-admin/)
    {username: "user1", sciper:"100100", email:"foo.bar@epfl.ch", group: "Foo", detail: "detail of my first users"},
    {username: "user2", sciper:"200200", email:"james.kilroy@epfl.ch", group: "Bar", detail: "detail of my second users"},
    {username: "user3", sciper:"300300", email:"andre.roussimoff@epfl.ch", group: "Foo", detail: "detail of my third users"}
];

router.get('/user', function(req, res, next) {
    res.json(USERModel.sort(users_data, req.query._sortField, req.query._sortDir));
});

router.get('/user/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    users_data.forEach(function (value, index) {
        if (users_data[index].username == stem) {
            return res.json(users_data[index]);
        }
    });
});

module.exports = router;
