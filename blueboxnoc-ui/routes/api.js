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
    {name:"Foo", desc:"Foofoo", bbxs:["bboo", "bbar"]},
    {name:"Bar", desc:"Foobar", bbxs:["bboo2"]},
    {name:"Bax", desc:"Foobaz", bbxs:["bbax"]},
    {name:"Bay", desc:"Foobay", bbxs:["bbay"]},
    {name:"Baz", desc:"Foobaz", bbxs:["bbaz"]}
];
router.get('/vpn', function(req, res, next) {
    res.json(VPNModel.sort(vpn_data, req.query._sortField, req.query._sortDir));
});

router.get('/vpn/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    VPNModel.validName(stem);
    vpn_data.forEach(function (value, index) {
        if (vpn_data[index].name == stem) {
            return res.json(vpn_data[index]);
        }
    });
});


// fake bbx data
var bbx_data = [
    {name:"bboo", vpn:"Foo", desc:"Booboo"},
    {name:"bboo2", vpn:"Bar", desc:"Booboo2"},
    {name:"bbar", vpn:"Foo", desc:"Boobar2"},
    {name:"bbax", vpn:"Bax", desc:"Boobax"},
    {name:"bbay", vpn:"Bay", desc:"Boobay"},
    {name:"bbaz", vpn:"Baz", desc:"Boobaz"}
];
router.get('/bbx', function(req, res, next) {
    res.json(BBXModel.sort(bbx_data, req.query._sortField, req.query._sortDir));
});

router.get('/bbx/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    BBXModel.validName(stem);
    bbx_data.forEach(function (value, index) {
        if (bbx_data[index].name == stem) {
            return res.json(bbx_data[index]);
        }
    });
});


// fake vnc data
var vnc_data = [
    {name:"vnc1", ip:"192.168.10.10", port:"5900", vpn:"Foo", desc:"detail of my first vnc", token:"jiy1Wiebo7fa6Taaweesh4nae"},
    {name:"vnc2", ip:"192.168.20.20", port:"5900", vpn:"Bar", desc:"detail of my second vnc", token:"queexahnohyahch3AhceiwooR"},
    {name:"vnc3", ip:"192.168.30.30", port:"5900", vpn:"Bax", desc:"detail of my third vnc", token:"Ahd7heeshoni8phanohB2Siey"},
    {name:"vnc4", ip:"192.168.40.40", port:"5901", vpn:"Bay", desc:"detail of my fourth vnc", token:"saeMohkaec7ax1aichohdoo6u"},
    {name:"vnc5", ip:"192.168.50.50", port:"5901", vpn:"Baz", desc:"detail of my fifth vnc", token:"ooJee6ohwaevooQuoSu3chahk"}
];
router.get('/vnc', function(req, res, next) {
    res.json(VNCModel.sort(vnc_data, req.query._sortField, req.query._sortDir));
});

router.get('/vnc/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    VNCModel.validName(stem);
    vnc_data.forEach(function (value, index) {
        if (vnc_data[index].name == stem) {
            return res.json(vnc_data[index]);
        }
    });
});


// fake users data
var users_data = [
    //{name:"user1", sciper:"100100", email:"foo.bar@epfl.ch", group: ["Foo", "Bar", "Baz"], desc:"detail of my first users"},
    // @todo check map function to get group in an array (https://github.com/marmelab/ng-admin/)
    {name:"user1", sciper:"100100", email:"foo.bar@epfl.ch", group:"BlueBoxNoc_admins", desc:"detail of my first users"},
    {name:"user2", sciper:"200200", email:"james.kilroy@epfl.ch", group:"BlueBoxNoc_admins", desc:"detail of my second users"},
    {name:"user3", sciper:"300300", email:"andre.roussimoff@epfl.ch", group:"BlueBoxNoc_vncers", desc:"detail of my third users"}
];

router.get('/user', function(req, res, next) {
    res.json(USERModel.sort(users_data, req.query._sortField, req.query._sortDir));
});

router.get('/user/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    users_data.forEach(function (value, index) {
        if (users_data[index].name == stem) {
            return res.json(users_data[index]);
        }
    });
});

module.exports = router;
