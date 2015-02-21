/**
 * Test the UI.
 */
var assert = require('assert'),
    testlib = require('./testlib'),
    webdriver = require('selenium-webdriver');

testlib.WebdriverTest.describe('Read-only navigation', function() {

    it('serves a homepage', function() {
        this.driver.get("/");
        var logo = this.driver.findElement(webdriver.By.className('logo'));
        logo.getAttribute('src').then(function(src) {
            src.match(new RegExp('/images/')) ||
                assert.fail(src, "should contain /images/", "unexpected logo URL", "match");
        });
    });
    it('shows the default data on the dashboard');
});