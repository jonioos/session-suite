import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Templates as T

T.Menu {
    id: menu

    popupType: T.Popup.Item
    implicitWidth: 176
    implicitHeight: options.contentHeight + topPadding + bottomPadding
    height: Math.min(implicitHeight, 252)
    padding: 5
    margins: 10
    focus: true

    contentItem: ListView {
        id: options
        model: menu.contentModel
        currentIndex: menu.currentIndex
        spacing: 2
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
    }

    background: Item {
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: -4
            radius: 10
            color: "#30112a40"
        }

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#f8fbfd"
            border.color: "#a9bdcc"
        }
    }
}
