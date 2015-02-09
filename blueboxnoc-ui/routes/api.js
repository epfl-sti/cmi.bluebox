/**
 * Routes for the RESTful API
 */

var express = require('express');
var router = express.Router();

/* TODO: de-bogosify */
router.get('/vpn', function(req, res, next) {
    res.json([{title: "Foo", detail: "Foofoo"}, {title: "Bar", detail: "Foobar"}, {title: "Baz", detail: "Foobaz"}]);
});

router.get('/vpn/*', function(req, res, next) {
    var urlparts = req.url.split("/");
    var stem = urlparts.pop();
    res.json({title: stem, detail: "Foo" + stem});
});

module.exports = router;
