import QtQuick 2.0
import Ubuntu.Components 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem

import "../../ubuntu-ui-extras"
import "../../backend"
import "../../components"

PageView {
    id: page
    title: "Project Settings"

    property Project project
    property string selection: "general"

    MasterDetailView {
        anchors.fill: parent

        forceSidebar: true

        itemSelected: selection !== ""

        header: Column {
            width: parent.width

            ListItem.Standard {
                text: "General"
                selected: selection === "general"
                onClicked: selection = "general"
            }

            ListItem.Header {
                text: "Plugins"
            }

            ListItem.Standard {
                visible: project.plugins.count === 0
                text: "No plugins yet!"
                enabled: false
            }
        }

        footer: Rectangle {
            width: parent.width
            height: addButton.height + units.gu(2)

            color: Qt.rgba(0,0,0,0.2)

            ListItem.ThinDivider {
                anchors.top: parent.top
            }

            Button {
                id: addButton
                anchors.centerIn: parent
                width: parent.width - units.gu(2)

                text: "Add plugins"
            }
        }

        model: project.plugins
        delegate: SubtitledListItem {
            id: listItem

            property Plugin plugin: modelData

            text: plugin.title
            subText: plugin.configuration
            selected: selection === plugin.type
            onClicked: selection = plugin.type

            property bool overlay: false

//            AwesomeIcon {
//                id: iconItem
//                name: listItem.plugin.icon
//                size: units.gu(3.5)
//                anchors {
//                    verticalCenter: parent.verticalCenter
//                    left: parent.left
//                    leftMargin: units.gu(1.5)
//                }
//            }

//            Column {
//                id: labels

//                spacing: units.gu(0.1)

//                anchors {
//                    verticalCenter: parent.verticalCenter
//                    left: iconItem.right
//                    leftMargin: units.gu(1.5)
//                    rightMargin: units.gu(4) + switchItem.width
//                    right: parent.right
//                }

//                Label {
//                    id: titleLabel

//                    width: parent.width
//                    elide: Text.ElideRight
//                    maximumLineCount: 1
//                    text: listItem.plugin.title
//                    color: overlay ? "#888888" : Theme.palette.selected.backgroundText
//                }

//                Label {
//                    id: subLabel
//                    width: parent.width

//                    height: visible ? implicitHeight: 0
//                    //color:  Theme.palette.normal.backgroundText
//                    maximumLineCount: 1
//                    opacity: overlay ? 0.7 : 0.65
//                    font.weight: Font.Light
//                    fontSize: "small"
//                    visible: text !== ""
//                    elide: Text.ElideRight
//                    text:listItem.plugin.configuration
//                    color: overlay ? "#888888" : Theme.palette.selected.backgroundText
//                }
//            }
        }

        content: Item {
            anchors.fill: parent

            Column {
                anchors.fill: parent
                visible: page.selection === "general"

                ListItem.Standard {
                    text: "Project Name"
                    control: TextField {
                        text: project.name

                        onTextChanged: project.name = text
                    }
                }

                ListItem.Standard {
                    text: "Show notifications"
                    control: Switch {
                        checked: project.notificationsEnabled

                        onCheckedChanged: project.notificationsEnabled = checked
                    }
                }
            }

            Loader {
                anchors.fill: parent
                visible: item !== null
                sourceComponent: plugin ? plugin.configView : null

                property Plugin plugin: project.getPlugin(selection)
            }
        }
    }
}
