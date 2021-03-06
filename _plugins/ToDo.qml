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
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.Pickers 1.0 as Picker
import Ubuntu.Components.ListItems 1.0 as ListItem
import "../backend"
import "../components"
import "../ubuntu-ui-extras/listutils.js" as List
import "../ubuntu-ui-extras/dateutils.js" as DateUtils
import "../ubuntu-ui-extras"

Plugin {
    id: plugin

    name: "tasks"
    title: "Tasks"
    icon: "check-square-o"

    property var tasks: doc.get("tasks", []).sort(sortFunction)

    // Return -1 to sort A before B, 1 to sort B before A
    function sortFunction(a,b) {
        if (a.date === undefined && b.date === undefined) {
            if ((a.text.indexOf("!") !== -1 && b.text.indexOf("!") !== -1) ||
                    (a.text.indexOf("!") == -1 && b.text.indexOf("!") == -1)) {
                return a.text > b.text ? 1 : a.text < b.text ? -1 : 0
            } else if (a.text.indexOf("!") !== -1 && b.text.indexOf("!") == -1) {
                return -1
            } else {
                return 1
            }
        } else if (a.date === undefined) {
            return 1
        } else if (b.date === undefined) {
            return -1
        } else {
            return new Date(a.date) - new Date(b.date)
        }
    }

    onSave: {
        doc.set("tasks", tasks)
    }

    function newTask(text, date) {
        var task = {"text": text, "done": false, "date": date ? date.toJSON(): undefined}
        tasks.push(task)
        tasks = tasks.sort(sortFunction)
        tasks = tasks
        notification.show(i18n.tr("Task added"))
    }

    property var openTasks: {
        var list = []
        //print("Searching...")
        for (var i = 0; i < tasks.length; i++) {
            var task = tasks[i]
            //print(task.text, task.done)
            if (!task.done) {
                //print("Open task:", task.text)
                task.index = i
                list.push(task)
            }
        }

        return list
    }

    items: PluginItem {
        title: i18n.tr("Tasks")
        icon: "check-square-o"
        value: openTasks.length > 0 ? openTasks.length : ""

        action: Action {
            text: i18n.tr("Add Task")
            description: i18n.tr("Add a new task to your to do list")
            iconSource: getIcon("add")
            onTriggered: PopupUtils.open(addLinkDialog)
        }

        pulseItem: PulseItem {

            show: openTasks.length > 0
            title: i18n.tr("Upcoming Tasks")
            viewAll: i18n.tr("View all <b>%1</b> tasks").arg(openTasks.length)

            ListItem.Standard {
                text: i18n.tr("No upcoming tasks")
                enabled: false
                visible: openTasks.length === 0
                height: visible ? implicitHeight : 0
            }

            Repeater {
                id: repeater
                model: Math.min(openTasks.length, project.maxRecent)
                delegate: ToDoListItem {
                    property var modelData: openTasks[index]
                    id: item
                    done: modelData.done
                    text: modelData.text
                    property var dueDate: modelData.date !== undefined ? new Date(modelData.date) : undefined
                    subText: modelData.date ? i18n.tr("Due %1").arg(DateUtils.formattedDate(dueDate)) : ""
                    subTextColor: dueDate !== undefined  ? DateUtils.isToday(dueDate) ? colors["green"]
                                                                              : DateUtils.dateIsBefore(dueDate, new Date()) ? colors["red"]
                                                                                                                            : DateUtils.dateIsThisWeek(dueDate) ? colors["yellow"]
                                                                                                                                                                : defaultSubTextColor
                                                 : defaultSubTextColor

                    onClicked: PopupUtils.open(editDialog, mainView, {index: modelData.index})
                    show: !done

                    onHeightChanged: {
                        if (height === 0 && done && !openTasks[index].done) {
                            tasks[modelData.index].done = true
                            tasks = tasks
                            done = Qt.binding(function() { return modelData.done })
                        }
                    }
                }
            }
        }

        page: PluginPage {
            title: i18n.tr("Tasks")

            actions: [
                Action {
                    text: i18n.tr("Add")
                    iconSource: getIcon("add")
                    onTriggered: PopupUtils.open(addLinkDialog)
                },

                Action {
                    text: i18n.tr("View")
                    iconSource: getIcon("navigation-menu")
                    onTriggered: PopupUtils.open(viewPopover, value)
                }

            ]

            ListView {
                id: listView
                anchors.fill: parent
                model: tasks
                delegate: ToDoListItem {
                    done: modelData.done
                    text: modelData.text
                    property var dueDate: modelData.date !== undefined ? new Date(modelData.date) : undefined
                    subText: modelData.date ? i18n.tr("Due %1").arg(DateUtils.formattedDate(dueDate)) : ""
                    subTextColor: dueDate !== undefined && !done ? DateUtils.isToday(dueDate) ? colors["green"]
                                                                              : DateUtils.dateIsBefore(dueDate, new Date()) ? colors["red"]
                                                                                                                            : DateUtils.dateIsThisWeek(dueDate) ? colors["yellow"]
                                                                                                                                                                : defaultSubTextColor
                                                 : defaultSubTextColor

                    onClicked: PopupUtils.open(editDialog, listView, {index: index})

                    show: !done || doc.get("showCompleted", false)

                    onDoneChanged: {
                        if (height === units.gu(6) && !done && tasks[index].done) {
                            tasks[index].done = false
                            tasks = tasks
                            done = Qt.binding(function() { return modelData.done })
                        }
                    }

                    onHeightChanged: {
                        if (height === 0 && done && !tasks[index].done) {
                            tasks[index].done = true
                            tasks = tasks
                            done = Qt.binding(function() { return modelData.done })
                        }
                    }
                }
            }

            Scrollbar {
                flickableItem: listView
            }

            Label {
                anchors.centerIn: parent
                visible: listView.contentHeight === 0
                text: "No tasks"
                opacity: 0.5
                fontSize: "large"
            }
        }
    }

    Component {
        id:viewPopover

        Popover {
            id: popover

            contentHeight: column.height

            Column {
                id: column
                width: parent.width

                ListItem.Standard {
                    text: i18n.tr("Show completed tasks")
                    control: CheckBox {
                        checked: doc.get("showCompleted", false)
                        onClicked: {
                            doc.set("showCompleted", checked)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: addLinkDialog
        Dialog {
            id: dialog

            title: i18n.tr("Add Task")
            text: i18n.tr("Enter the title and opionally the due date of your task:")

            property Resources plugin

            Component.onCompleted: titleField.parent.parent.height = Qt.binding(function() { return titleField.parent.height + dialog.__foreground.margins })

            TextField {
                id: titleField

                placeholderText: i18n.tr("Title")

                onAccepted: okButton.click()
                style: DialogTextFieldStyle {}
            }

            Item {
                width: parent.width
                height: childrenRect.height

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Has due date:")
                }

                Switch {
                    id: dueDateSwitch
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                }
            }

            Item {
                width: parent.width
                height: dueDateSwitch.checked ? datePicker.height : 0
                opacity: dueDateSwitch.checked ? 1 : 0
                clip: true

                Behavior on height {
                    UbuntuNumberAnimation {}
                }

                Behavior on opacity {
                    UbuntuNumberAnimation {}
                }

                Picker.DatePicker {
                    id: datePicker
                    width: parent.width
                    date: new Date()
                    style: SuruDatePickerStyle {}
                    anchors.bottom: parent.bottom
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height

                Button {
                    objectName: "cancelButton"
                    text: i18n.tr("Cancel")
                    anchors {
                        left: parent.left
                        right: parent.horizontalCenter
                        rightMargin: units.gu(1)
                    }

                    color: "gray"

                    onClicked: {
                        PopupUtils.close(dialog)
                    }
                }

                Button {
                    id: okButton
                    objectName: "okButton"

                    text: i18n.tr("Ok")
                    enabled: titleField.text !== ""
                    anchors {
                        left: parent.horizontalCenter
                        right: parent.right
                        leftMargin: units.gu(1)
                    }

                    onClicked: {
                        PopupUtils.close(dialog)
                        newTask(titleField.text, dueDateSwitch.checked ? datePicker.date : undefined)
                    }
                }
            }
        }
    }

    Component {
        id: editDialog
        Dialog {
            id: dialog

            property int index

            title: i18n.tr("Edit Task")
            text: i18n.tr("Change the title or due date of your task:")

            property Resources plugin

            Component.onCompleted: titleField.parent.parent.height = Qt.binding(function() { return titleField.parent.height + dialog.__foreground.margins })

            TextField {
                id: titleField

                placeholderText: i18n.tr("Title")

                style: DialogTextFieldStyle {}
                onAccepted: okButton.click()
                text: tasks[index].text
            }

            Item {
                width: parent.width
                height: childrenRect.height

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.tr("Has due date:")
                }

                Switch {
                    id: dueDateSwitch
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    checked: tasks[index].date !== undefined
                }
            }

            Item {
                width: parent.width
                height: dueDateSwitch.checked ? datePicker.height : 0
                opacity: dueDateSwitch.checked ? 1 : 0
                clip: true

                Behavior on height {
                    UbuntuNumberAnimation {}
                }

                Behavior on opacity {
                    UbuntuNumberAnimation {}
                }

                Picker.DatePicker {
                    id: datePicker
                    width: parent.width
                    style: SuruDatePickerStyle {}
                    anchors.bottom: parent.bottom
                    date: tasks[index].date ? new Date(tasks[index].date) : new Date()
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height

                Button {
                    objectName: "cancelButton"
                    text: i18n.tr("Cancel")
                    anchors {
                        left: parent.left
                        right: parent.horizontalCenter
                        rightMargin: units.gu(1)
                    }

                    color: "gray"

                    onClicked: {
                        PopupUtils.close(dialog)
                    }
                }

                Button {
                    id: okButton
                    objectName: "okButton"

                    text: i18n.tr("Ok")
                    enabled: titleField.text !== ""
                    anchors {
                        left: parent.horizontalCenter
                        right: parent.right
                        leftMargin: units.gu(1)
                    }

                    onClicked: {
                        PopupUtils.close(dialog)
                        tasks[index] = {
                            "text": titleField.text,
                            "done": tasks[index].done,
                            "date": dueDateSwitch.checked ? datePicker.date.toJSON() : undefined
                        }

                        tasks = tasks.sort(sortFunction)
                    }
                }
            }
        }
    }
}

