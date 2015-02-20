var express = require('express'),
    router = express.Router(),
    VPNModel = require("../model/vpn.js"),
    BBXModel = require("../model/bbx.js"),
    VNCModel = require("../model/vnc.js"),
    USERModel = require("../model/user.js"),
    GROUPModel = require("../model/group.js");

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', {
      title: 'BlueBoxNOC'
  });
});

/* Helper JS for client-side validations */
router.get('/js/validations.js', function(req, res, next) {
    res.writeHead(200, {"Content-Type": "text/javascript"});
    res.end(   "var VPNNameValidator = " + String(VPNModel.primaryKey.validate)+";"+
                    "var BBXNameValidator = " + String(BBXModel.primaryKey.validate)+";"+
                    "var VNCNameValidator = " + String(VNCModel.validName)+";"+
                    "var USERNameValidator = " + String(USERModel.primaryKey.validate)+";");
});
module.exports = router;
