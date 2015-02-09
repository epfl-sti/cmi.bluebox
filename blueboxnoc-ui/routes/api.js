/**
 * Routes for the RESTful API
 */

var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/vpn', function(req, res, next) {
    res.json([{id: 1, title: "Foo"}, {id: 1, title: "Bar"}, {id: 2, title: "Baz"}]);
});

module.exports = router;
