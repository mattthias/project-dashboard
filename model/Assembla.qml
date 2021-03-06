/*
 * Project Dashboard - Manage everything about your projects in one app
 * Copyright (C) 2014 Michael Spencer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.0
import "internal" as Internal

import "../qml-extras/httplib.js" as Http
import "../ubuntu-ui-extras"
import "../components"

import "../qml-extras/promises.js" as Promise

Internal.Assembla {
    id: assembla

    authenticationStatus: oauthToken === "" ? "" : i18n.tr("Logged in as %1").arg(user.login)

    description: i18n.tr("Manage, Deliver, and Maintain Websites, Apps, and Agile Projects.")

    enabled: oauthToken !== ""

    accountItem: SubtitledListItem {
        text: user ? user.name : enabled ? i18n.tr("Loading user info...") : ""
        subText: user ? user.login : ""
        visible: assembla.enabled
        progression: true
        height: visible ? units.gu(8) : 0
    }

    property string api: "https://api.assembla.com/v1"

    onOauthTokenChanged: {
        if (oauthToken !== "") {
            httpGet('/user.json').done(function(response) {
                var json = JSON.parse(response)
                user = json
            }).error(function(error, info) {
                print("ERROR" + error)

                if (info.status == 401) {
                    Http.post('https://%1:%2@api.assembla.com/token?client_id=%3&grant_type=refresh_token&refresh_token=%4'
                              .arg('dcsqOS5hyr44kZacwqjQXA')
                              .arg('0661da1c5ffe98abcabab0644f24fd47')
                              .arg('dcsqOS5hyr44kZacwqjQXA')
                              .arg(refreshToken)).done(function (data, info) {
                        oauthToken = JSON.parse(data).access_token
                    })
                }
            })

            httpGet('/spaces.json').done(function(response) {
                var json = JSON.parse(response)
                repos = json
            }).error(function(error) {
                print("ERROR" + error)
            })
        } else {
            user = undefined
        }
    }

    function authenticate() {
        pageStack.push(Qt.resolvedUrl("../backend/services/AssemblaOAuth.qml"))
    }

    function httpGet(call, args) {
        if (call.indexOf('http') !== 0) {
            call = api + call
        }

        return Http.get(call, {
                            headers: {"Authorization": "Bearer " + oauthToken}
                        })
    }

    function expand(string, args) {
        if (!args)
            return string
        for (var i = 0; i < args.length; i++) {
            string = string.arg(args[i])
        }

        return string
    }

    function revoke() {
        oauthToken = ""
    }
}
