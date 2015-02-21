/**
 * Test the UI.
 */
var assert = require('assert'),
    testlib = require('./testlib'),
    webdriver = require('selenium-webdriver');

testlib.WebdriverTest.describe('Read-only navigation', function() {
    this.setUpFakeData();
    it('serves a homepage', function() {
        var driver = this.driver;
        driver.get("/");
        var logo = driver.findElement(webdriver.By.className('logo'));
        logo.getAttribute('src').then(function(src) {
            src.match(new RegExp('/images/')) ||
                assert.fail(src, "should contain /images/", "unexpected logo URL", "match");
        });
    });
    it('has fake data', function () {
        var driver = this.driver;
        driver.get("/");
        driver.wait(function () {
            return driver.isElementPresent(webdriver.By.linkText("BlueBoxNOC_Admins"));
        });
    });
});
