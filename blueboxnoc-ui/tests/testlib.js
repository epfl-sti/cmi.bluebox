var http = require('http');

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
        });
        wdtesting.after(function() {
            self.driver.quit();
        });

        // Not the most elegant (as compared to say, running suiteBody inside
        // vm.runInNewContext), but gets the job done:
        var itOrig = global.it;
        global.it = function(description, testBody) {
            if (! testBody) {
                return itOrig(description);
            }
            return wdtesting.it(description, function () {
                this.driver = self.driver;
                this.app = self.app;
                testBody.call(this);
            });
        };
        try {
            return suiteBody.call(self);
        } finally {
            global.it = itOrig;
        }
    });
};

