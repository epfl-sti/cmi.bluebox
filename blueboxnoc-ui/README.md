# About
This is the UI part of the [epfl-sti/cmi.bluebox](epfl-sti/cmi.bluebox) projet. This web user interface aims to serve a simple and intuitive way to configure Bluebox, to set VPN and VNC and finally to remotely access computers through VNC.

The web UI is based on [node.js](https://nodejs.org/), [angular.js](https://angularjs.org/) and [ng-admin](marmelab/ng-admin).

The VNC part is using [noVNC](http://novnc.com)'s project.

# Workflow
A detailed workflow is described in the [project's wiki](https://github.com/epfl-sti/cmi.bluebox/wiki#2015-02-09---blue-box-personalization-use-case).

# Basic Schema
The data are stored in a flat json file `fleet_state.json` and the schema can be described as the image below:
![screenshot](../doc/db/db.png?raw=true)

