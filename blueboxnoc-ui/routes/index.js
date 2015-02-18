var express = require('express');
var router = express.Router();
var VPNModel = require("../model/vpn.js");
var BBXModel = require("../model/bbx.js");
var VNCModel = require("../model/vnc.js");
var USERModel = require("../model/user.js");

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', {
      title: 'BlueBoxNOC'
  });
});
router.get('/js/validations.js', function(req, res, next) {
    res.writeHead(200, {"Content-Type": "text/javascript"});
    res.end(   "var VPNNameValidator = " + String(VPNModel.validName)+";"+
                    "var BBXNameValidator = " + String(BBXModel.validName)+";"+
                    "var VNCNameValidator = " + String(VNCModel.validName)+";"+
                    "var USERNameValidator = " + String(USERModel.validName)+";");
});
module.exports = router;
