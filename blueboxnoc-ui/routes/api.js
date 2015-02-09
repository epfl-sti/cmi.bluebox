/**
 * Routes for the RESTful API
 */

var express = require('express');
var router = express.Router();

/* TODO: de-bogosify */
router.get('/vpn', function(req, res, next) {
    res.json([{title: "Foo", detail: "Foofoo"}, {title: "Bar", detail: "Foobar"}, {title: "Baz", detail: "Foobaz"}]);
});

router.get('/vpn/Foo', function(req, res, next) {
    res.json({title: "Foo", detail: "Foofoo"});
});

router.get('/vpn/Bar', function(req, res, next) {
    res.json({title: "Bar", detail: "Foobar"});
});

router.get('/vpn/Baz', function(req, res, next) {
    res.json({title: "Baz", detail: "Foobaz"});
});

module.exports = router;
