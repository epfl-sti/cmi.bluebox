/**
 * Test the UI.
 */
var assert = require('assert'),
    testlib = require('./testlib'),
    webdriver = require('selenium-webdriver');

testlib.WebdriverTest.describe('UI Appearance tests', function() {
    it('serves a homepage', function() {
        this.driver.get(server.baseUrl);
        var logo = this.driver.findElement(webdriver.By.className('logo'));
        logo.getAttribute('src').then(function(src) {
            src.match(new RegExp('/images/')) ||
                assert.fail(src, "should contain /images/", "unexpected logo URL", "match");
        });
    });
});