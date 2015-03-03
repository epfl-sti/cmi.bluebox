/**
 * Test the UI.
 */
var assert = require('assert'),
    debug = require('debug')('ui_test'),
    when = require('when'),
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

webdriver.WebElementPromise.prototype.thenClickIt = function() {
    this.then(function(elem) {
        return elem.click();
    });
};

webdriver.promise.Promise.prototype.thenSendKeys = function(text) {
    this.then(function(elem) {
        return elem.sendKeys(text);
    });
};

var findText = testlib.WebdriverTest.findText,
    findLinkByText = testlib.WebdriverTest.findLinkByText,
    findByLabel = testlib.WebdriverTest.findByLabel,
    findButton = testlib.WebdriverTest.findButton;

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
    describe('Read-only navigation', function () {
        before(testlib.WebdriverTest.setUpFakeData);

        it('serves a homepage', function() {
            driver.get("/");
            var logo = driver.findElement(webdriver.By.className('logo'));
            logo.getAttribute('src').then(when.lift(function(src) {
                new RegExp('/images/').test(src) ||
                assert.fail(src, "should contain /images/", "unexpected logo URL", "match");
            }));
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
            findLinkByText(driver, dashboardTitle).thenClickIt();
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
            function thenAssertIsLabel(elem) {
                return elem.getAttribute('class')
                    .then(when.lift(function (cssClasses) {
                        assert(/label/.test(cssClasses));
                    }));
            }
            checkListView("VPN", {
                example: {linkName: "Bar", description: "Foobar"},
                moreRowChecks: function(rowObject) {
                    // Inspect that row to find all the things.
                    // It's supposed to look like this:
                    // Name      |    Description  | Blue Boxes  | VNC
                    // <a>Bar</a>| Foobar          | []bboo2     | []vnc2
                    findText(rowObject, "bboo2");
                    findText(rowObject, "vnc2").then(thenAssertIsLabel);
                }});
            checkListView("VPN", {
                example: {linkName: "Bay", description: "Foobay"},
                moreRowChecks: function(rowObject) {
                    findText(rowObject, "bbay");
                    findText(rowObject, "vnc4").then(thenAssertIsLabel);
                }});
        });

        function checkEditView(title, opts) {
            var titlePlural = opts.titlePlural || (title + "s");
            var dashboardTitle = opts.dashboardTitle ||
                (titlePlural + " List");

            driver.get("/");
            [dashboardTitle, opts.example.linkName]
                .forEach(function (linkToClick) {
                    findLinkByText(driver, linkToClick).thenClickIt();
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

        it('does likewise for Blue Boxes', function () {
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
                    }).then(when.lift(function (ngClickValue) {
                        assert(/gotoDetail/.test(ngClickValue));
                    }));
                }
            });
            checkEditView("BlueBox", {
                titlePlural: "BlueBoxes",
                example: {
                    linkName: "bbay"
                }
            });
        });

        it('has pagination', function () {
            driver.get('/');
            findLinkByText(driver, 'Blue Boxes').then(function (BbxLink) {
                return BbxLink.click();
            }).then(function () {
                return findLinkByText(driver, 'Next »');
            }).then(function (nxtBtn) {
                return nxtBtn.click();
            }).then(function () {
                return findLinkByText(driver, '« Prev');
            }).then(function (prvBtn) {
                return prvBtn.click();
            });
        });

        it.only('has a status page', function () {
            driver.get('#/status');
            findText(driver, "INIT");
            findText(driver, "DOWNLOADED");
            findText(driver, "NEEDS_UPDATE");
            findText(driver, "ACTIVE");
            findText(driver, "FAILING");
        });
    });
    describe('Create, Update, Delete operations', function () {
        beforeEach(testlib.WebdriverTest.setUpFakeData);
        it('creates a VPN', function () {
            driver.get("/");
            findLinkByText(driver, "VPNs").thenClickIt();
            findText(driver, "Create").thenClickIt();
            findByLabel(driver, "Name").thenSendKeys("NewName");
            findByLabel(driver, "Description")
                .thenSendKeys("This is a description");
            findButton(driver, "Submit").then(when.lift(function (btnElem) {
                debug.printXPath("Submit button ", btnElem);
                return btnElem;
            })).then(function(elem) {
                // TODO: this should be thenClickIt, somehow
                return elem.click();
            }).then(function () {
                findText(driver, 'Edit VPN: NewName');
            });
        });
    });
    it('refuses to create two VPNs with the same name', function () {
        driver.get("/");
        findLinkByText(driver, "VPNs").thenClickIt();
        findText(driver, "Create").thenClickIt();
        findByLabel(driver, "Name").thenSendKeys("Foo");
        findByLabel(driver, "Description")
            .thenSendKeys("This is a description");
        findButton(driver, "Submit").thenClickIt().then(function () {
           findText("already exists");
        });
    });
});
