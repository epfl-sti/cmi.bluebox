var express = require('express');
var router = express.Router();
var VPNModel = require("../model/vpn.js");

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', {
      title: 'BlueBoxNOC',
      VPNTitleValidator: String(VPNModel.validName) });
});

module.exports = router;
