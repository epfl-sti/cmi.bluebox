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

function findBy(driverOrElement, webdriverLocator, opt_options) {
    if (! opt_options) opt_options = {};
    if (opt_options.wait) {
        var driver = driverOrElement.driver_ || driverOrElement;
        driver.wait(function () {
            return driverOrElement.isElementPresent(webdriverLocator);
        });
    }
    return driverOrElement.findElement(webdriverLocator);
}

function findLinkByText(driverOrElement, text, opt_options) {
    return findBy(driverOrElement, webdriver.By.linkText(text), opt_options);
}

function findText(driverOrElement, text, opt_options) {
    return findBy(driverOrElement,
        webdriver.By.xpath('*[contains(., "' + text + '")]'),
        opt_options);
}

function findDashboardWidget(driver, title, opt_options) {
    return findLinkByText(driver, title, opt_options)
        .then(function (elem) {
            debug.printXPath(
                "XPath to link containing '" + title + "': ", elem);
            return elem.findElement(webdriver.By.xpath('ancestor::ma-dashboard-panel'));
        });
}

testlib.WebdriverTest.describe('Read-only navigation', function() {
    var driver = this.driver;
    this.setUpFakeData();

    it('serves a homepage', function() {
        driver.get("/");
        var logo = driver.findElement(webdriver.By.className('logo'));
        logo.getAttribute('src').then(function(src) {
            src.match(new RegExp('/images/')) ||
                assert.fail(src, "should contain /images/", "unexpected logo URL", "match");
        });
    });
    it('has fake data', function () {
        driver.get("/");
        findLinkByText(driver, "BlueBoxNOC_Admins", {wait: true});
    });

    it('shows a complete dashboard', function () {
        driver.get("/");

        function findInDashboardWidget(dashboardTitle, opts) {
            findDashboardWidget(driver, dashboardTitle, opts)
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
                texts: ["Foobar"],
                wait: true
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

    it('shows VPN list and details', function () {
        driver.get("/");
        findLinkByText(driver, "VPNs List", {wait: true})
            .then(function (elem) {
            elem.click();
        });
        findText(driver, "All VPNs", {wait: true});
    });
});
