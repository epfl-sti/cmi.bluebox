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

var findText = testlib.WebdriverTest.findText,
    findLinkByText = testlib.WebdriverTest.findLinkByText;

function findDashboardWidget(driver, title) {
    return findLinkByText(driver, title)
        .then(function (elem) {
            debug.printXPath(
                "XPath to link containing '" + title + "': ", elem);
            return elem.findElement(webdriver.By.xpath('ancestor::ma-dashboard-panel'));
        });
}

testlib.WebdriverTest.describe('UI tests', function() {
    var driver = this.driver;
    this.setUpFakeData();

    describe('Read-only navigation', function () {
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
            findLinkByText(driver, "BlueBoxNOC_Admins");
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

        function checkListView(title, opts) {
            var titlePlural = opts.titlePlural || (title + "s");
            var dashboardTitle = opts.dashboardTitle || (titlePlural + " List");
            var listViewTitle = opts.listViewTitle || ("All " + titlePlural);
            driver.get("/");
            findLinkByText(driver, dashboardTitle)
                .then(function (elem) {
                    elem.click();
                });
            findText(driver, listViewTitle);
            findText(driver, opts.example.description).then(function (elem) {
                debug.printXPath(opts.example.description + " found at: ", elem);
                return elem.findElement(webdriver.By.xpath('ancestor::tr'))
            }).then(function (rowObject) {
                findLinkByText(rowObject, opts.example.linkName);
                if (opts.moreRowChecks) {
                    opts.moreRowChecks(rowObject);
                }
            });
        }

        it('shows a VPN list with full details', function () {
            checkListView("VPN", {
                example: {linkName: "Bar", description: "Foobar"},
                moreRowChecks: function(rowObject) {
                    // Inspect that row to find all the things.
                    // It's supposed to look like this:
                    // Name      |    Description  | Blue Boxes  | VNC
                    // <a>Bar</a>| Foobar          | []bboo2     | []vnc2
                    findText(rowObject, "bboo2");
                    findText(rowObject, "vnc2").then(function (vncElem) {
                        return vncElem.getAttribute('class');
                    }).then(function (cssClasses) {
                        assert(cssClasses.match(/label/));
                    });

                }
            });
        });

        function checkEditView(title, opts) {
            var titlePlural = opts.titlePlural || (title + "s");
            var dashboardTitle = opts.dashboardTitle ||
                (titlePlural + " List");

            driver.get("/");
            [dashboardTitle, opts.example.linkName]
                .forEach(function (linkToClick) {
                    findLinkByText(driver, linkToClick)
                        .then(function (elem) {
                            elem.click();
                        });
                });
            findText(driver, "Name");
            findText(driver, "Description");
        }

        it('shows a VPN edit page', function () {
            checkEditView("VPN", {example: {linkName: "Foo"}});
            findText(driver, "Blue Boxes");
        });

        it('does likewise for VNCs', function () {
            checkListView("VNC", {
                example: {
                    linkName: "vnc3", 
                    description: "detail of my third vnc"
                },
                moreRowChecks: function (rowObject) {
                    findText(rowObject, "192.168.30.30");  // IP
                    findLinkByText(rowObject, "Bax");      // VPN
                    findText(rowObject, "Open vnc3 in a new window");
                }
            });
            checkEditView("VNC", {
                example: {
                    linkName: "vnc2"
                }
            });
        });

        it.only('does likewise for Blue Boxes', function () {
            checkListView("BlueBox", {
                titlePlural: "BlueBoxes",
                listViewTitle: "All Blue Boxes",
                example: {
                    linkName: "bboo2",
                    description: "Booboo2"
                },
                moreRowChecks: function (rowObject) {
                    // Last known IP
                    findText(rowObject, "192.168.10.1");
                    // Status
                    findText(rowObject, "INIT").then(function (buttonElem) {
                        return buttonElem.findElement(webdriver.By.xpath('ancestor::a'));
                    }).then(function (linkElem) {
                        return linkElem.getAttribute('ng-click');
                    }).then(function (ngClickValue) {
                        assert(ngClickValue.match(/gotoDetail/));
                    })
                }
            });
            checkEditView("BlueBox", {
                titlePlural: "BlueBoxes",
                example: {
                    linkName: "bbay"
                }
            });
        });
    });
});
