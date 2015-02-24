var BlueboxNocApp = angular.module("BlueboxNocApp", ["ng-admin"]);
// https://github.com/marmelab/ng-admin
BlueboxNocApp.config(function (NgAdminConfigurationProvider, Application, Entity, Field, Reference, ReferencedList, ReferenceMany) {
    // Common field types
    function descField() { return new Field('desc').label('Description'); }
    function statusField() { return new Field('status').label('State'); }
    function lastIPField() { return new Field('lastKnownIP').label('Last known IP').editable(false); }
    function idField() { return new Field('id'); }
    // Names are used as primary keys for all classes except VNC targets
    function nameField() { return new Field('name'); }
    function nameInputField(validator) {
        return nameField().validation({validator: validator});
    }
    function dashboardClickyNameField(label) {
        return nameField().isDetailLink(true).label(label);
    }
    function readOnlyNameField() {
        // Clicky because it gets copied into list views a lot.
        return nameField().isDetailLink(true).editable(false);
    }

    // set the main API endpoint for this admin
    var rootUrl = (location.protocol + '//' + location.hostname +
    (location.port ? ':' + location.port : ''));
    var app = new Application('Menu'). // application main title
        baseApiUrl(rootUrl + "/api/"); // main API endpoint

    // define all entities at the top to allow references between them
    var vpn = new Entity('vpn')
        .label("VPNs")
        .identifier(nameField());
    var bbx = new Entity('bbx')
        .label("Blue Boxes")
        .identifier(nameField());
    var vnc = new Entity('vnc')
        .label("VNCs")
        .identifier(idField());
    var user = new Entity('user')
        .label("Users")
        .identifier(nameField());
    var group = new Entity('group')
        .label("Groups")
        .identifier(new Field('name'));
    var status = new Entity('status')
        .label("Status")
        .identifier(new Field('name'));

    // set the application entities
    app
        .addEntity(vpn)
        .addEntity(bbx)
        .addEntity(vnc)
		.addEntity(user)
        .addEntity(group)
        .addEntity(status);

    // set the application menu entries
    var menuCnt = 0;
    bbx.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-th-large"></span>');
    vpn.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-road"></span>');
    vnc.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-new-window"></span>');
    user.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-user"></span>')
        .disable(); // Users will not be used in interface;
    group.menuView()
        .order(menuCnt++)
        .icon('<span class="glyphicon glyphicon-user"></span>');
    status.menuView().disable();

    // BlueBoxes
    bbx.dashboardView()
        .title("BlueBoxes List")
        .order(2) // display the post panel first in the dashboard
        .limit(10) // limit the panel to the 5 latest posts
        .fields([
            dashboardClickyNameField("BBX"),
            descField(),
            new Field("vpn").label("VPN"),
            new Field("status").type("template").template('<button type="button" class="bbx-btn bbx-btn-xs bbx-btn-{{entry.values.status}}" aria-expanded="false">{{entry.values.status}}</button>'),
        ]);
    bbx.listView()
        .title("All Blue Boxes")
        .fields([
            readOnlyNameField(),
            descField(),
            lastIPField(),
            new Field("vpn").editable(false),
            new Reference('status')
                .label('Status')
                .targetEntity(status)
                .targetField(nameField())
                .cssClasses("bbx_status")
                .type("template").template('<button type="button" class="bbx-btn bbx-btn-{{entry.values.status}}" aria-expanded="false">{{entry.values.status}}</button>')
        ]);
    bbx.editionView()
        .title("Blue Box : {{entry.values.name}}")
        .actions(["list", "show", "delete"])
        .fields([
            readOnlyNameField(),
            descField(),
            lastIPField(),
            new Field("vpn").editable(false),
            new Field("status").type("template").template('<button type="button" class="bbx-btn bbx-btn-{{entry.values.status}}" aria-expanded="false">{{entry.values.status}}</button>'),
            new Field("Logs").type("template").template('<div ng-controller="bbx_logs"><textarea style="width:100%; border-style: none; border-color: Transparent; overflow: auto; outline: none;textarea:focus">{{logs}}</textarea></div>'),
            /* More smart way: http://www.grobmeier.de/bootstrap-tabs-with-angular-js-25112012.html#.VOXJ4eRMcUE */
            //new Field("Logs").type("template").template(' <div class="panel panel-default"> <div class="panel-heading"> {{entry.values.name}}\'s logs </div> <!-- /.panel-heading --> <div class="panel-body"> <!-- Nav tabs --> <ul class="nav nav-tabs"> <li class=""><a aria-expanded="false" href="#home" data-toggle="tab">Home</a> </li> <li class=""><a aria-expanded="false" href="http://localhost:3000/#/edit/bbx/bboo#profile" data-toggle="tab">Profile</a> </li> <li class="active"><a aria-expanded="true" href="#messages" data-toggle="tab">Messages</a> </li> <li><a href="#settings" data-toggle="tab">Settings</a> </li> </ul> <!-- Tab panes --> <div class="tab-content"> <div class="tab-pane fade" id="home"> <h4>Home Tab</h4> <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p> </div> <div class="tab-pane fade" id="profile"> <h4>Profile Tab</h4> <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p> </div> <div class="tab-pane fade active in" id="messages"> <h4>Messages Tab</h4> <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p> </div> <div class="tab-pane fade" id="settings"> <h4>Settings Tab</h4> <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p> </div> </div> </div> <!-- /.panel-body --> </div> <!-- /.panel --> ')
            new Field("TarFile").type("template").template('<div class="alert alert-info" id="bbx_tar_download_info"><h4>Download Installation File</h4><p>Note about status and Installation file installation process...</p><br /><div class="text-center"><button type="button" class="btn btn-default btn-lg"><span class="glyphicon glyphicon-floppy-save" aria-hidden="true"></span> Download tar.gz file</button></div></div>')
        ]);
    bbx.creationView().fields([
        nameInputField(BBXNameValidator),
        descField(),
        new Reference('vpn')
            .label('VPN')
            .targetEntity(vpn) // Select a target Entity
            .targetField(nameField()),
        new Field("Information").type("template").template('<div class="alert alert-success" role="alert">Some information about bbx creation process<br /><ul><li>First create the BBX</li><li>Be sure to have the correct VPN</li><li>Finally, if you want to be able to access a computer through VNC, be sure your VNC entity is connect to the same VPN than the BBX.</li></ul><a href="#" class="alert-link">Link to something</a></div>')
    ]);
    bbx.showView()
        .title("Blue Box : {{entry.values.name}}")
        .actions(["list", "delete"])
        .fields([
            readOnlyNameField(),
            descField(),
            lastIPField(),
            new Field("vpn").editable(false),
            new Field("status").type("template").template('<button type="button" class="bbx-btn bbx-btn-{{entry.values.status}}" aria-expanded="false">{{entry.values.status}}</button>'),
            new Field("Logs").type("template").template('<div ng-controller="bbx_logs"><textarea style="width:100%; border-style: none; border-color: Transparent; overflow: auto; outline: none;textarea:focus">{{logs}}</textarea></div>'),
            /* More smart way: http://www.grobmeier.de/bootstrap-tabs-with-angular-js-25112012.html#.VOXJ4eRMcUE */
            //new Field("Logs2").type("template").template(' <div class="panel panel-default"> <div class="panel-heading"> {{entry.values.name}}\'s logs </div> <!-- /.panel-heading --> <div class="panel-body"> <!-- Nav tabs --> <ul class="nav nav-tabs"> <li class=""><a aria-expanded="false" href="#home" data-toggle="tab">Home</a> </li> <li class=""><a aria-expanded="false" href="http://localhost:3000/#/edit/bbx/bboo#profile" data-toggle="tab">Profile</a> </li> <li class="active"><a aria-expanded="true" href="#messages" data-toggle="tab">Messages</a> </li> <li><a href="#settings" data-toggle="tab">Settings</a> </li> </ul> <!-- Tab panes --> <div class="tab-content"> <div class="tab-pane fade" id="home"> <h4>Home Tab</h4> <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p> </div> <div class="tab-pane fade" id="profile"> <h4>Profile Tab</h4> <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p> </div> <div class="tab-pane fade active in" id="messages"> <h4>Messages Tab</h4> <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p> </div> <div class="tab-pane fade" id="settings"> <h4>Settings Tab</h4> <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p> </div> </div> </div> <!-- /.panel-body --> </div> <!-- /.panel --> '),
            new Field("TarFile").type("template").template('<div class="alert alert-info" id="bbx_tar_download_info"><h4>Download Installation File</h4><p>Note about status and Installation file installation process...</p><br /><div class="text-center"><button type="button" class="btn btn-default btn-lg"><span class="glyphicon glyphicon-floppy-save" aria-hidden="true"></span> Download tar.gz file</button></div></div>'),
            new Field("TarFile2").type("template").template('<div class="alert alert-info" id="bbx_tar_download_info"><h4>Download Installation File</h4><p>Note about status and Installation file installation process...</p><br /><div class="text-center"><button type="button" class="btn btn-default btn-lg"><span class="glyphicon glyphicon-floppy-save" aria-hidden="true"></span> Download tar.gz file</button></div></div>')
        ]);

    // VPNs
    vpn.dashboardView()
        .title("VPNs List")
        .order(1) // display the post panel first in the dashboard
        .limit(5) // limit the panel to the 5 latest posts
        .fields([
            dashboardClickyNameField("VPN"),
            descField()
        ]);
    vpn.editionView()
        .title("Edit VPN: {{entry.values.name}}")
        .actions(["list", "show", "delete"])
        .fields([
            readOnlyNameField(),
            descField(),
            new ReferenceMany('bbxs') // a Reference is a particular type of field that references another entity
                .label('Blue Boxes')
                .targetEntity(bbx) // the tag entity is defined later in this file
                .targetField(nameField()) // the field to be displayed in this list
        ]);
    vpn.listView()
        .title("All VPNs")
        .fields([
            vpn.editionView().fields(),
            // duplicated ReferenceMany field to get the class only on list view
            new ReferenceMany('bbxs') // a Reference is a particular type of field that references another entity
                .label('Blue Boxes')
                .targetEntity(bbx) // the tag entity is defined later in this file
                .targetField(nameField()) // the field to be displayed in this list
                .cssClasses('bboxes_tag'),
            new ReferenceMany('vncs') // a Reference is a particular type of field that references another entity
                .label('VNC')
                .targetEntity(vnc)
                .targetField(nameField()) // the field to be displayed in this list
                .cssClasses('vncs_tag'),
        ]);
    vpn.creationView().fields([
        nameInputField(VPNNameValidator),
        descField()]);
    vpn.showView().fields([
        readOnlyNameField(),
        descField(),
        new Field("vpnBoxes").type("template").template('<div ng-controller="HelloWorld">Hello, {{user}}.</div>')
    ]);

    // VNCs
    vnc.dashboardView()
        .title("VNCs List")
        .order(3) // display the post panel first in the dashboard
        .limit(5) // limit the panel to the 5 latest posts
        .fields([
            dashboardClickyNameField("VNC"),
            descField(),
            new Reference('vpn')
                .label('VPN')
                .targetEntity(vpn)
                .targetField(nameField())
        ]);
    vnc.editionView()
        .title("Edit VNC : {{entry.values.name}}")
        .actions(["list", "show", "delete"])
        .fields([
            readOnlyNameField(),
            descField(),
            new Field("ip"),
            new Field("port"),
            // @todo preselect current vpn in the list
            new Reference('vpn')
                .label('VPN')
                .targetEntity(vpn) // Select a target Entity
                .targetField(nameField()), // Select a label Field
            // @todo see how to add a frame with VNC
            new Field('Open VNC', 'template')
                .type('template')
                .editable(false)
                .template('Open {{entry.values.name}} in a new window: <br /><a href="http://localhost:6080/vnc_auto.html?host={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">mode auto</a><br /><a href="http://localhost:6080/vnc.html?host={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">mode normal</a>')
        ]);
    vnc.listView()
        .title("All VNCs")
        .fields(vnc.editionView().fields());
    vnc.creationView().fields([
        nameInputField(VNCNameValidator),
        descField()]);
    vnc.showView().fields([
        readOnlyNameField(),
        descField(),
        new Field("link").type("template").template('<a href="http://{{entry.values.ip}}:{{entry.values.port}}">{{entry.values.ip}}:{{entry.values.port}}</a>'),
        new Field("vncBoxes").type("template").template('Open {{entry.values.title}} in a new window: <br /><a href="http://localhost:6080/vnc_auto.html?host={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">mode auto</a><br /><a href="http://localhost:6080/vnc.html?host={{entry.values.ip}}&port={{entry.values.port}}&vpn={{entry.values.vpn}}&token={{entry.values.token}}" target="_blank">mode normal</a>'),
        new Field("noVNC").type("template").template('<canvas></canvas>')
    ]);

    // USERs
    user.dashboardView().disable();/*
        .title("Users List")
        .order(4)
        .limit(10)
        .fields([
            nameField().isDetailLink(true).label("Users").identifier(true),
            new Field("sciper"),
            new Field("email")
        ])
        ;*/
    user.editionView()
        .title("Edit user : {{entry.values.name}}")
        .actions(["list", "show", "delete"])
        .fields([
            nameField().editable(false).isDetailLink(true).identifier(true),
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
    user.creationView().fields([
        nameInputField(USERNameValidator),
        descField()]);
    user.showView().fields([
        readOnlyNameField(),
        descField(),
        new Field("vncBoxes").type("template").template('<div ng-controller="HelloWorld">Hello, {{user}}.</div>')
    ]);

    // GROUPs
    group.dashboardView()
        .title("Groups List")
        .order(5)
        .limit(10)
        .fields([
            nameField().editable(false).isDetailLink(true).identifier(true).label("Groups")
        ])
        .sortField("name")
        .sortDir("ASC");
    group.listView()
        .fields([
            nameField().editable(false).isDetailLink(true).identifier(true),
            descField().editable(false),
            new Field("group_email").editable(false)
        ]);
    group.editionView()
        .title("All groups")
        .actions([])
        .fields([
            readOnlyNameField().identifier(true),
            descField().editable(false),
            new Field("group_email").editable(false)
        ]);
    group.creationView().disable();
    group.showView()
        .fields([
            nameField().editable(false).isDetailLink(true).identifier(true),
            descField().editable(false),
            new Field("group_email").editable(false)
        ]);

    status.dashboardView().disable();

    NgAdminConfigurationProvider.configure(app);
});
// How to slap additional UI on any of the ng-admin pages,
// e.g. here to access the VNC features
BlueboxNocApp.controller("HelloWorld", function ($scope) {
    $scope.user = "Calvin Hobbes";
});
BlueboxNocApp.controller("bbx_logs", function ($scope) {
    $scope.logs = "- 2015-01-10 10:10 BlueBox creation by XXX (#169411) \n- 2015-01-10 10:10 BlueBox creation by XXX (#169411) \n- 2015-01-10 10:10 BlueBox creation by XXX (#169411) \n- 2015-01-10 10:10 BlueBox creation by XXX (#169411) \netc...";
});
