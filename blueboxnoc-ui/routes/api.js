/**
 * Routes for the RESTful API
 */

var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/vpn', function(req, res, next) {
    res.json([{id: "Foo"}]);
});

module.exports = router;
