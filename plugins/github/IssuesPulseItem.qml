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
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import "../../components"
import "../../qml-extras/listutils.js" as List
import "../../ubuntu-ui-extras"
import "../../model"
import "../../qml-extras/utils.js" as Utils

PulseItem {
    id: pulseItem

    property bool showAllAssignedIssues
    property string type: "issues"

    show: List.length(issues) > 0
    title: i18n.tr("Assigned Issues")

    viewAll: plugin ? i18n.tr("View all <b>%1</b> %2").arg(List.length(plugin.openIssues)).arg(type) : ""

    property var issues: {
        var issues
        if (plugin) {
            issues = plugin.assignedIssues
        } else {
            issues = []

            if (!showAllAssignedIssues)
                return []

            for (var i = 0; i < backend.projects.count; i++) {
                var project = backend.projects.at(i)
                var p = project.getPlugin('GitHub')
                if (p) issues = issues.concat(p.assignedIssues)

                var p = project.getPlugin('Assembla')
                if (p) issues = issues.concat(p.assignedIssues)

                var p = project.getPlugin('Launchpad')
                if (p) issues = issues.concat(p.assignedIssues)
            }
        }

        issues = issues.sort(function (a, b) {
            return new Date(b.created_at) - new Date(a.created_at)
        })

        print("ASSIGNED ISSUES:", issues.length)

        return issues
    }

    ListItem.Standard {
        text: i18n.tr("No assigned %1").arg(type)
        enabled: false
        visible: List.length(issues) === 0
        height: visible ? implicitHeight : 0
    }

    Repeater {
        model: issues
        delegate: IssueListItem {
            issue: modelData
            showProject: plugin === null
            showAssignee: false
        }
    }
}
