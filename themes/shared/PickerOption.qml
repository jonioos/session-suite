import QtQuick
import QtQuick.Templates as T

T.MenuItem {
    id: option

    property bool selected: false

    width: menu ? menu.availableWidth : implicitWidth
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: 36
    leftPadding: 10
    rightPadding: 10
    hoverEnabled: true
    Accessible.description: selected ? qsTr("Selected") : ""

    background: Rectangle {
        radius: 6
        color: option.highlighted ? "#dce9f4"
                                   : option.selected ? "#eaf2f8" : "transparent"
    }

    contentItem: Text {
        text: option.text
        textFormat: Text.PlainText
        font.family: "Noto Sans"
        font.pixelSize: 14
        font.weight: option.selected ? Font.DemiBold : Font.Normal
        color: option.enabled ? "#1c3851" : "#657b8e"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
