var debug = require('debug')('testlib'),
    http = require('http'),
    path = require('path'),
    temp = require('temp'),
    URL = require('url'),
    runtime = require("../lib/runtime");

    /**
 * Start a Web server on a random port then call done().
 * @param app An instance of express
 */
module.exports.startServer = function (app, done) {
    server = http.createServer(app);
    server.on('error', function (error) {
        done(error);
    });
    server.on('listening', function() {
        var addr = server.address();
        app.set('port', addr.port);
        server.port = addr.port;
        server.baseUrl = 'http://localhost:' + addr.port + '/';
        done();
    });
    server.listen(0);
    return server;
};

module.exports.WebdriverTest = {};

/**
 * Wrapper around Mocha and Selenium for UI tests.
 *
 * Automagically make this.driver and this.server available from
 * the test bodies (within "it" callbacks). this.driver is the
 * WebDriver object (see examples in
 * https://code.google.com/p/selenium/wiki/WebDriverJs).
 * this.server is an http.Server instance running the app.
 *
 * Additionally:
 *   + navigating to relative URLs (e.g. "/") is supported
 *   + driver.wait() has a sane default value for the delay parameter
 *
 * @param description Like Mocha's first parameter to describe()
 * @param suiteBody Like Mocha's second parameter to describe()
 */
module.exports.WebdriverTest.describe = function (description, suiteBody) {
    if (! suiteBody) {
        return wdtesting.describe(description);
    }
    var webdriver = require('selenium-webdriver'),
        wdtesting = require('selenium-webdriver/testing');

    var mochaBefore = before;
    return wdtesting.describe(description, function () {
        var self = this;
        this.timeout(10000);  // Pump up default value
        this.setUpFakeData = module.exports.WebdriverTest.setUpFakeData;

        // For some reason wdtesting.before won't wait for the callback:
        mochaBefore(function(done) {
            if (! self.app) {
                self.app = require("../app");
            }
            self.server = module.exports.startServer(self.app, done);
        });

        wdtesting.before(function () {
            self.driver = new webdriver.Builder().
                withCapabilities(webdriver.Capabilities.chrome()).build();
            decorateDriver(self.driver, self.server.baseUrl);
        });
        wdtesting.after(function() {
            self.driver.quit();
        });

        // Not the most elegant (as compared to say, running suiteBody inside
        // vm.runInNewContext), but gets the job done:
        var itOrig = global.it;
        try {
            global.it = decorateIt(itOrig, self, wdtesting.it);
            return suiteBody.call(self);
        } finally {
            global.it = itOrig;
        }
    });
};

module.exports.WebdriverTest.setUpFakeData = function() {
    runtime.srvDir(temp.mkdirSync("BlueBoxNocFakeData"));
    var mochaBefore = before;
    var perl = require('../lib/perl');
    mochaBefore(function (done) {
        perl.runPerl(
            [path.resolve(runtime.srcDir(), "devsupport/make-fake-data.pl")],
            "",
            function (perlOut, perlExitCode, perlErr) {
                if (perlExitCode) {
                    done(perlErr);
                } else {
                    done();
                }
            }
        );
    });
};

/**
 * Get the XPath from the document root to this element.
 *
 * @return {!webdriver.promise.Promise.<string>} A promise that will be
 *     resolved with the element's pseudo-XPath.
 */
module.exports.WebdriverTest.getXPath = function(elem) {
    return elem.driver_.executeScript(
        // Adapted from https://stackoverflow.com/questions/4176560
        // This is mobile code, it gets stringified and sent into the
        // browser, yow!
        function getXPath(node) {
            if (node.id !== '') {
                return '//' + node.tagName.toLowerCase() + '[@id="' + node.id + '"]';
            }
            if (node === document.body) {
                return node.tagName.toLowerCase();
            }
            var nodeCount = 0;
            var childNodes = node.parentNode.childNodes;

            for (var i = 0; i < childNodes.length; i++) {
                var currentNode = childNodes[i];

                if (currentNode === node) {
                    return getXPath(node.parentNode) +
                        '/' + node.tagName.toLowerCase() +
                        '[' + (nodeCount + 1) + ']';
                }

                if (currentNode.nodeType === 1 &&
                    currentNode.tagName.toLowerCase() === node.tagName.toLowerCase()) {
                    nodeCount++;
                }
            }
        }, elem);
};


function decorateIt(itOrig, self, itFromWdtesting) {
    var it = function(description, testBody) {
        if (!testBody) {
            return itOrig(description);
        }
        return itFromWdtesting(description, function () {
            this.driver = self.driver;
            this.app = self.app;
            testBody.call(this);
        });
    };
    // The more you know: selenium-webdriver's it.only is implemented
    // in terms of it, and looks it up from the context (a.k.a. global
    // object) at run time. We don't want to wrap it twice.
    it.only = itOrig.only;
    return it;
}

function decorateDriver(driverObj, baseUrl) {
    var navigateOrig = driverObj.navigate;
    driverObj.navigate = (function () {
        var navigator = navigateOrig.call(driverObj);
        var toOrig = navigator.to;
        navigator.to = function (url) {
            if (! URL.parse(url).host) {
                url = URL.resolve(baseUrl, url);
            }
            return toOrig.call(navigator, url);
        };
        return navigator;
    }).bind(driverObj);
    var waitOrig = driverObj.wait;
    driverObj.wait = function (cb, opt_delay) {
        if (! opt_delay) opt_delay = 2000;
        waitOrig.call(driverObj, cb, opt_delay);
    };
}
