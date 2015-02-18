var BlueboxNocApp = angular.module("BlueboxNocApp", ["ng-admin"]);
// https://github.com/marmelab/ng-admin
BlueboxNocApp.config(function (NgAdminConfigurationProvider, Application, Entity, Field, Reference, ReferencedList, ReferenceMany) {
    // set the main API endpoint for this admin
    var rootUrl = (location.protocol + '//' + location.hostname +
    (location.port ? ':' + location.port : ''));
    var app = new Application('Menu'). // application main title
        baseApiUrl(rootUrl + "/api/"); // main API endpoint

    // define all entities at the top to allow references between them
    var vpn = new Entity('vpn')
        .label("VPNs")
        .identifier(new Field('title'));
    var bbx = new Entity('bbx')
        .label("Blue Boxes")
        .identifier(new Field('title'));
    var vnc = new Entity('vnc')
        .label("VNCs")
        .identifier(new Field('title'));
    var group = new Entity('group')
        .label("Groups")
        .identifier(new Field('groupname'));

    // set the application entities
    app
        .addEntity(vpn)
        .addEntity(bbx)
        .addEntity(vnc)
        .addEntity(group);

    // set the application menu entries
    var menuCnt = 0;
    vpn.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-road"></span>');
    bbx.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-th-large"></span>');
    vnc.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-new-window"></span>');
    group.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-user"></span>'); //.disable();

    // VPNs
    vpn.dashboardView()
        .title("VPNs List")
        .order(1) // display the post panel first in the dashboard
        .limit(5) // limit the panel to the 5 latest posts
        .fields([
            new Field("title").isDetailLink(true).label("VPN"),
            new Field("detail")
        ]);
    vpn.editionView()
        .title("Edit VPN : {{entry.values.title}}")
        .actions(["list", "show", "delete"])
        .fields([
            new Field("title").editable(false).isDetailLink(true),
            new Field("detail"),
            new ReferenceMany('bbxs') // a Reference is a particular type of field that references another entity
                .label('Blue Boxes')
                .targetEntity(bbx) // the tag entity is defined later in this file
                .targetField(new Field('title')), // the field to be displayed in this list
            new Reference('group')
                .label('Group')
                .targetEntity(group) // Select a target Entity
                .targetField(new Field('groupname')) // Select a label Field
        ]);
    vpn.listView()
        .title("All VPNs")
        .fields([
            vpn.editionView().fields(),
            // duplicated ReferenceMany field to get the class only on list view
            new ReferenceMany('bbxs') // a Reference is a particular type of field that references another entity
                .label('Blue Boxes')
                .targetEntity(bbx) // the tag entity is defined later in this file
                .targetField(new Field('title')) // the field to be displayed in this list
                .cssClasses('bboxes_tag'),
            new Reference('group')
                .label('Group')
                .targetEntity(group) // Select a target Entity
                .targetField(new Field('groupname')) // Select a label Field
        ]);
    var vpnTitleAtCreationTime = new Field("title").validation({validator: !{VPNTitleValidator}});
    vpn.creationView().fields([
        vpnTitleAtCreationTime,
        new Field("detail")]);
    vpn.showView().fields([
        new Field("title").editable(false).isDetailLink(true),
        new Field("detail"),
        //new Field("vpnBoxes").type("template").template('<div ng-controller="HelloWorld">Hello, {{user}}.</div>')
    ]);

    // BlueBoxes
    bbx.dashboardView()
        .title("BlueBoxes List")
        .order(2) // display the post panel first in the dashboard
        .limit(10) // limit the panel to the 5 latest posts
        .fields([
            new Field("title").isDetailLink(true).label("BBX"),
            new Field("vpn"),
            new Field("status")
        ]);
    bbx.editionView().title("Blue Box : {{entry.values.title}}")
        .actions(["list", "show", "delete"])
        .fields([
            new Field("title").editable(false).isDetailLink(true),
            new Field("vpn").editable(false),
            new Field("detail"),
            new Field("status").editable(false)
        ]);
    bbx.listView()
        .title("All Blue Boxes")
        .fields(bbx.editionView().fields());
    var bbxTitleAtCreationTime = new Field("title").validation({validator: !{BBXTitleValidator}});
    bbx.creationView().fields([
        bbxTitleAtCreationTime,
        new Field("detail")]);
    bbx.showView().fields([
        new Field("title").editable(false).isDetailLink(true),
        new Field("detail"),
        new Field("vpn"),
        new Field("BBxVpn").type("template").template('<div ng-controller="HelloWorld">Hello, {{user}}.</div>')
    ]);
    // VNCs
    vnc.dashboardView()
        .title("VNCs List")
        .order(3) // display the post panel first in the dashboard
        .limit(5) // limit the panel to the 5 latest posts
        .fields([
            new Field("title").isDetailLink(true).label("VNC"),
            new Field("detail")
        ]);
    vnc.editionView()
        .title("Edit VNC : {{entry.values.title}}")
        .actions(["list", "show", "delete"])
        .fields([
            new Field("title").editable(false).isDetailLink(true),
            new Field("detail"),
            new Field("ip"),
            new Field("port"),
            // @todo preselect current vpn in the list
            new Reference('vpn')
                .label('VPN title')
                .targetEntity(vpn) // Select a target Entity
                .targetField(new Field('title')), // Select a label Field
            // @todo see how to add a frame with VNC
            new Field('Open VNC', 'template')
                .type('template')
                .editable(false)
                // http://IGMGEB080333:6080/vnc.html?host=IGMGEB080333&port=6080
                .template('Open {{entry.values.title}} in a new window: <br /><a href="http://localhost:6080/vnc_auto.html?host={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">mode auto</a><br /><a href="http://localhost:6080/vnc.html?host={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">mode normal</a>')
        ]);
    vnc.listView()
        .title("All VNCs")
        .fields(vnc.editionView().fields());
    var vncTitleAtCreationTime = new Field("title").validation({validator: !{VNCTitleValidator}});
    vnc.creationView().fields([
        vncTitleAtCreationTime,
        new Field("detail")]);
    vnc.showView().fields([
        new Field("title").editable(false).isDetailLink(true),
        new Field("detail"),
        new Field("vncBoxes").type("template").template('Open {{entry.values.title}} in a new window: <br /><a href="http://localhost:6080/vnc_auto.html?host={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">mode auto</a><br /><a href="http://localhost:6080/vnc.html?host={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">mode normal</a>')
    ]);

    // GROUPs
    group.dashboardView()
        .title("Groups List")
        .order(4)
        .limit(10)
        .fields([
            new Field("groupname").isDetailLink(true).label("Groups")
        ])
        .sortField("groupname")
        .sortDir("ASC");
    group.editionView()
        .title("All groups")
        .actions([])
        .fields([
            new Field("groupname").editable(false).isDetailLink(true).identifier(true),
            new Field("detail").editable(false),
            new Field("group_email").editable(false)
        ]);
    group.listView()
        .fields([
            new Field("groupname").editable(false).isDetailLink(true).identifier(true),
            new Field("detail").editable(false),
            new Field("group_email").editable(false)
        ]);
    group.creationView().disable();
    group.showView()
        .fields([
            new Field("groupname").editable(false).isDetailLink(true).identifier(true),
            new Field("detail").editable(false),
            new Field("group_email").editable(false)
        ]);

    NgAdminConfigurationProvider.configure(app);
});
// How to slap additional UI on any of the ng-admin pages,
// e.g. here to access the VNC features
BlueboxNocApp.controller("HelloWorld", function ($scope) {
    $scope.user = "Calvin Hobbes";
});