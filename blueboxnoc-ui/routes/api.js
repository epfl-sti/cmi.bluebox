/**
 * Routes for the RESTful API
 */

var express = require('express');
var router = express.Router();

/* TODO: de-bogosify */
router.get('/vpn', function(req, res, next) {
    res.json([{id: 1, title: "Foo"}, {id: 2, title: "Bar"}, {id: 3, title: "Baz"}]);
});

router.get('/vpn/1', function(req, res, next) {
    res.json({id: 1, title: "Foo"});
});

router.get('/vpn/2', function(req, res, next) {
    res.json({id: 2, title: "Bar"});
});

router.get('/vpn/3', function(req, res, next) {
    res.json({id: 3, title: "Baz"});
});

module.exports = router;
