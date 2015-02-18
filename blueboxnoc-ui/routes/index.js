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
      title: 'BlueBoxNOC' });
});
router.get('/js/validations.js', function(req, res, next) {
    res.writeHead(200, {"Content-Type": "text/javascript"});
    res.end(   "var VPNTitleValidator = " + String(VPNModel.validName)+";"+
                    "var BBXTitleValidator = " + String(BBXModel.validName)+";"+
                    "var VNCTitleValidator = " + String(VNCModel.validName)+";"+
                    "var USERTitleValidator = " + String(USERModel.validName)+";");
});
module.exports = router;
