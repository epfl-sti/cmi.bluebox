var express = require('express');
var router = express.Router();
var VPNModel = require("../model/vpn.js");
var BBXModel = require("../model/bbx.js");

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', {
      title: 'BlueBoxNOC',
      VPNTitleValidator: String(VPNModel.validName),
      BBXTitleValidator: String(BBXModel.validName)});
});

module.exports = router;
