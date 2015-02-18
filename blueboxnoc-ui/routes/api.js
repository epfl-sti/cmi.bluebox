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
var GROUPModel = require("../model/group.js");

/* TODO: de-bogosify */

// fake vpn data
var vpn_data =  [
    {title:"Foo", detail:"Foofoo", bbxs:["bboo", "bbar"], group:"BlueBoxNOC_Admins"},
    {title:"Bar", detail:"Foobar", bbxs:["bboo2"], group:"BlueBoxNOX_Admins"},
    {title:"Bax", detail:"Foobaz", bbxs:["bbax"], group:"BlueBoxNOX_Admins"},
    {title:"Bay", detail:"Foobay", bbxs:["bbay"], group:"BlueBoxNOX_Admins"},
    {title:"Baz", detail:"Foobaz", bbxs:["bbaz"], group:"BlueBoxNOX_Admins"}
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
    {title:"bboo", vpn:"Foo", detail:"Booboo", status:"INIT"},
    {title:"bboo2", vpn:"Bar", detail:"Booboo2", status:"INIT"},
    {title:"bbar", vpn:"Foo", detail:"Boobar2", status:"DOWNLOADED"},
    {title:"bbax", vpn:"Bax", detail:"Boobax", status:"NEEDS_UPDATE"},
    {title:"bbay", vpn:"Bay", detail:"Boobay", status:"NEEDS_UPDATE"},
    {title:"bbaz", vpn:"Baz", detail:"Boobaz", status:"ACTIVE"}
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
    {title:"vnc5", ip:"localhost", port:"6080", vpn:"Baz", detail:"My local VNC for test", token:"ooJee6ohwaevooQuoSu3chahk"}
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
    {username:"user1", sciper:"100100", email:"foo.bar@epfl.ch", group:"ABlueBoxNoc_admins", detail:"detail of my first users"},
    {username:"user2", sciper:"200200", email:"james.kilroy@epfl.ch", group:"BBlueBoxNoc_admins", detail:"detail of my second users"},
    {username:"user3", sciper:"300300", email:"andre.roussimoff@epfl.ch", group:"CBlueBoxNoc_vncers", detail:"detail of my third users"}
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

// Groups data
// Should be linked to groups on http://groups.epfl.ch and used for authentication purpose.
var groups_data = [
    {groupname:"BlueBoxNOC_Admins", id:"73347", group_email:"BlueBoxNOC_Admins@groupes.epfl.ch", detail:"Admin group of BlueBoxNOC"},
    {groupname:"BlueBoxNOC_VNCers", id:"73348", group_email:"BlueBoxNOC_VNCers@groupes.epfl.ch", detail:"VNCers group of BlueBOxNOC"}
];

router.get('/group', function(req, res, next) {
    res.json(GROUPModel.sort(groups_data, req.query._sortField, req.query._sortDir));
});

router.get('/group/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    groups_data.forEach(function (value, index) {
        if (groups_data[index].groupname == stem) {
            return res.json(groups_data[index]);
        }
    });
});
module.exports = router;
