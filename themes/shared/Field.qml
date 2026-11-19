import QtQuick
import QtQuick.Templates as T

T.TextField {
    id: control

    implicitWidth: 180
    implicitHeight: 40
    leftPadding: 13
    rightPadding: 13
    selectByMouse: true
    color: "#142b41"
    placeholderTextColor: "#526778"
    selectionColor: "#24476f"
    selectedTextColor: "#ffffff"
    font.family: "Noto Sans"
    font.pixelSize: 15
    verticalAlignment: TextInput.AlignVCenter
    activeFocusOnTab: true

    Text {
        x: control.leftPadding
        width: control.width - control.leftPadding - control.rightPadding
        anchors.verticalCenter: parent.verticalCenter
        visible: !control.text && !control.preeditText
        text: control.placeholderText
        color: control.placeholderTextColor
        font: control.font
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: 10
        color: "#ffffff"
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? "#39739c" : "#a9bdcc"
    }
}
