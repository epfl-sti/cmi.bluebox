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
    var user = new Entity('user')
        .label("Users")
        .identifier(new Field('username'));
    // set the application entities
    app
        .addEntity(vpn)
        .addEntity(bbx)
        .addEntity(vnc)
        .addEntity(user);
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
    user.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-user"></span>');

    // Common fields
    function descField() { return new Field('desc').label('Description') };

    // VPNs
    vpn.dashboardView()
        .title("VPNs List")
        .order(1) // display the post panel first in the dashboard
        .limit(5) // limit the panel to the 5 latest posts
        .fields([
            new Field("title").isDetailLink(true).label("VPN"),
            descField()
        ]);
    vpn.editionView()
        .title("Edit VPN : {{entry.values.title}}")
        .actions(["list", "show", "delete", "bluebox"])
        .fields([
            new Field("title").editable(false).isDetailLink(true),
            descField(),
            new ReferenceMany('bbxs') // a Reference is a particular type of field that references another entity
                .label('Blue Boxes')
                .targetEntity(bbx) // the tag entity is defined later in this file
                .targetField(new Field('title')) // the field to be displayed in this list
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
                .cssClasses('bboxes_tag')
        ]);
    var vpnTitleAtCreationTime = new Field("title").validation({validator: !{VPNTitleValidator}});
    vpn.creationView().fields([
        vpnTitleAtCreationTime,
        descField()]);
    vpn.showView().fields([
        new Field("title").editable(false).isDetailLink(true),
        descField(),
        new Field("vpnBoxes").type("template").template('<div ng-controller="HelloWorld">Hello, {{user}}.</div>')
    ]);
    // BlueBoxes
    bbx.dashboardView()
        .title("BlueBoxes List")
        .order(2) // display the post panel first in the dashboard
        .limit(10) // limit the panel to the 5 latest posts
        .fields([
            new Field("title").isDetailLink(true).label("BBX"),
            descField(), new Field("vpn")
        ]);
    bbx.editionView().title("Blue Box : {{entry.values.title}}")
        .actions(["list", "show", "delete"])
        .fields([
            new Field("title").editable(false).isDetailLink(true),
            new Field("vpn").editable(false),
            descField()
        ]);
    bbx.listView()
        .title("All Blue Boxes")
        .fields(bbx.editionView().fields());
    var bbxTitleAtCreationTime = new Field("title").validation({validator: !{BBXTitleValidator}});
    bbx.creationView().fields([
        bbxTitleAtCreationTime,
        descField()]);
    bbx.showView().fields([
        new Field("title").editable(false).isDetailLink(true),
        descField(),
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
            descField()
        ]);
    vnc.editionView()
        .title("Edit VNC : {{entry.values.title}}")
        .actions(["list", "show", "delete"])
        .fields([
            new Field("title").editable(false).isDetailLink(true),
            descField(),
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
                .template('<a href="/connect?ip={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">Open {{entry.values.title}} in a new window</a>')
        ]);
    vnc.listView()
        .title("All VNCs")
        .fields(vnc.editionView().fields());
    var vncTitleAtCreationTime = new Field("title").validation({validator: !{VNCTitleValidator}});
    vnc.creationView().fields([
        vncTitleAtCreationTime,
        descField()]);
    vnc.showView().fields([
        new Field("title").editable(false).isDetailLink(true),
        descField(),
        new Field("vncBoxes").type("template").template('<div id="VNC_connect"><a href="/connect?ip={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">Connect to {{entry.values.title}}</a></div>')
    ]);
    // USERs
    user.dashboardView()
        .title("Users List")
        .order(4)
        .limit(10)
        .fields([
            new Field("username").isDetailLink(true).label("Users").identifier(true),
            new Field("sciper"),
            new Field("email")
        ]);
    user.editionView()
        .title("Edit user : {{entry.values.title}}")
        .actions(["list", "show", "delete"])
        .fields([
            new Field("username").editable(false).isDetailLink(true).identifier(true),
            new Field("sciper").editable(false),
            new Field("email").editable(false),
            new Field("group"),
            /*new ReferencedList('group') // display list of related comments
             .targetEntity(user)
             .targetReferenceField('username')
             .targetFields([
             new Field('group')
             ]),*/
            new Field('View details', 'template')
                .type('template')
                .editable(false)
                .template('<a href="http://people.epfl.ch/cgi-bin/people/showcv?id={{entry.values.sciper}}&op=admindata&type=show&login=1&lang=en&cvlang=en" target="_blank">Open {{entry.values.username}} details</a>')
        ]);
    user.listView()
        .title("All Users")
        .fields(user.editionView().fields());
    var userTitleAtCreationTime = new Field("title").validation({validator: !{USERTitleValidator}});
    user.creationView().fields([
        userTitleAtCreationTime,
        descField()]);
    user.showView().fields([
        new Field("title").editable(false).isDetailLink(true),
        descField(),
        new Field("vncBoxes").type("template").template('<div ng-controller="HelloWorld">Hello, {{user}}.</div>')
    ]);
    NgAdminConfigurationProvider.configure(app);
});
// How to slap additional UI on any of the ng-admin pages,
// e.g. here to access the VNC features
BlueboxNocApp.controller("HelloWorld", function ($scope) {
    $scope.user = "Calvin Hobbes";
});
