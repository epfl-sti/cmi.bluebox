/**
 * Test the UI.
 */
var assert = require('assert'),
    debug = require('debug')('ui_test'),
    testlib = require('./testlib'),
    webdriver = require('selenium-webdriver');

debug.printXPath = function (opt_text, elem) {
    var debug = this;
    if (! debug.enabled) return;

    if (! elem) {
        elem = opt_text;
        opt_text = "";
    }
    testlib.WebdriverTest.getXPath(elem)
        .then(function (xpath) {
            debug(opt_text + xpath);
        });
};

function findLinkByText(driverOrElement, text) {
    return driverOrElement.findElement(webdriver.By.linkText(text));
}

function findText(driverOrElement, text) {
    return driverOrElement.findElement(webdriver.By.xpath(
        '*[contains(., "' + text + '")]'));
}

function waitFindLinkByText(driver, text) {
    driver.wait(function () {
        return driver.isElementPresent(webdriver.By.linkText(text));
    });
    return findLinkByText(driver, text);
}

function findDashboardWidget(driver, title) {
    return waitFindLinkByText(driver, title)
        .then(function (elem) {
            debug.printXPath(
                "XPath to link containing '" + title + "': ", elem);
            return elem.findElement(webdriver.By.xpath('ancestor::ma-dashboard-panel'));
        });
}

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
        waitFindLinkByText(driver, "BlueBoxNOC_Admins");
    });

    it('shows a complete dashboard', function () {
        var driver = this.driver;
        driver.get("/");

        function findInDashboardWidget(dashboardTitle, opts) {
            findDashboardWidget(driver, dashboardTitle)
                .then(function (widgetElem) {
                    var linkTexts = opts.linkTexts || [];
                    linkTexts.forEach(function (linkText) {
                        findLinkByText(widgetElem, linkText);
                    });

                    var texts = opts.texts || [];
                    texts.forEach(function (text) {
                        findText(widgetElem, text);
                    })
                });
        }

        findInDashboardWidget("VPNs List",
            {
                linkTexts: ["VPN", "Description", "Bax"],
                texts: ["Foobar"]
            });
        findInDashboardWidget("BlueBoxes List",
            {
                linkTexts: ["BBX", "Description", "VPN", "Status", "bboo2"],
                texts: ["Booboo2"]
            });
        findInDashboardWidget("VNCs List",
            {
                linkTexts: ["VNC", "Description", "VPN", "vnc2"],
                texts: ["detail of my second vnc"]
            });
    });
});
