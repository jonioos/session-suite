import QtQuick
import QtQuick.Templates as T

T.Button {
    id: control

    property string glyph
    property bool primary: false
    property bool selected: false

    implicitWidth: glyph && !text ? 38 : implicitContentWidth + 26
    implicitHeight: primary ? 42 : 36
    leftPadding: glyph && !text ? (width - 18) / 2 : 13
    rightPadding: leftPadding
    hoverEnabled: true
    font.family: "Noto Sans"
    font.pixelSize: primary ? 15 : 12
    font.weight: Font.DemiBold
    opacity: enabled ? 1 : 0.65

    background: Rectangle {
        radius: control.primary ? 11 : 9
        color: control.primary
            ? (control.down ? "#0e2241" : control.hovered ? "#24476f" : "#183657")
            : (control.down || control.selected ? "#dce7ee" : control.hovered ? "#e6eef3" : "transparent")
        border.width: control.activeFocus ? 2 : 0
        border.color: control.primary ? "#99d8ff" : "#32638a"
    }

    contentItem: Item {
        implicitWidth: labelRow.implicitWidth
        implicitHeight: labelRow.implicitHeight

        Row {
            id: labelRow
            anchors.centerIn: parent
            spacing: 8

            Image {
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter
                visible: Boolean(control.glyph)
                source: control.glyph ? "icons/" + control.glyph + ".svg" : ""
                sourceSize.width: 36
                sourceSize.height: 36
            }

            Text {
                visible: Boolean(control.text)
                text: control.text
                textFormat: Text.PlainText
                color: control.primary ? "#ffffff" : "#28455e"
                font: control.font
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
