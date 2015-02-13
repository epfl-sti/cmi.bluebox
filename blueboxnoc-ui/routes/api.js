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
    {title:"Foo", detail:"Foofoo", bbxs:["bboo", "bbar"]},
    {title:"Bar", detail:"Foobar", bbxs:["bboo2"]},
    {title:"Bax", detail:"Foobaz", bbxs:["bbax"]},
    {title:"Bay", detail:"Foobay", bbxs:["bbay"]},
    {title:"Baz", detail:"Foobaz", bbxs:["bbaz"]}
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
    {title:"bboo", vpn:"Foo", detail:"Booboo"},
    {title:"bboo2", vpn:"Bar", detail:"Booboo2"},
    {title:"bbar", vpn:"Foo", detail:"Boobar2"},
    {title:"bbax", vpn:"Bax", detail:"Boobax"},
    {title:"bbay", vpn:"Bay", detail:"Boobay"},
    {title:"bbaz", vpn:"Baz", detail:"Boobaz"}
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
    {title:"vnc1", ip:"192.168.10.10", port:"5900", vpn:"Foo", detail:"detail of my first vnc", token:"jiy1Wiebo7fa6Taaweesh4nae"},
    {title:"vnc2", ip:"192.168.20.20", port:"5900", vpn:"Bar", detail:"detail of my second vnc", token:"queexahnohyahch3AhceiwooR"},
    {title:"vnc3", ip:"192.168.30.30", port:"5900", vpn:"Bax", detail:"detail of my third vnc", token:"Ahd7heeshoni8phanohB2Siey"},
    {title:"vnc4", ip:"192.168.40.40", port:"5901", vpn:"Bay", detail:"detail of my fourth vnc", token:"saeMohkaec7ax1aichohdoo6u"},
    {title:"vnc5", ip:"192.168.50.50", port:"5901", vpn:"Baz", detail:"detail of my fifth vnc", token:"ooJee6ohwaevooQuoSu3chahk"}
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
    //{username:"user1", sciper:"100100", email:"foo.bar@epfl.ch", group: ["Foo", "Bar", "Baz"], detail:"detail of my first users"},
    // @todo check map function to get group in an array (https://github.com/marmelab/ng-admin/)
    {username:"user1", sciper:"100100", email:"foo.bar@epfl.ch", group:"BlueBoxNoc_admins", detail:"detail of my first users"},
    {username:"user2", sciper:"200200", email:"james.kilroy@epfl.ch", group:"BlueBoxNoc_admins", detail:"detail of my second users"},
    {username:"user3", sciper:"300300", email:"andre.roussimoff@epfl.ch", group:"BlueBoxNoc_vncers", detail:"detail of my third users"}
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
