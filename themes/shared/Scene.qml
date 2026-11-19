import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts

FocusScope {
    id: scene

    property string account
    property string actionText
    property string message
    property bool messageIsError: false
    property bool showUsername: false
    property bool showSecret: true
    property bool masked: true
    property bool canSubmit: true
    property bool canEdit: true
    property string secretPlaceholder: qsTr("Password")
    property string contextText
    property real keyboardInset: 0

    property alias accountMenu: accountMenu
    property alias secret: secretField
    property alias username: username
    property alias primaryAction: primaryAction
    property alias tools: tools.data
    property alias powerTools: powerTools.data

    signal submitted()

    function toggleAccountMenu() {
        if (accountMenu.opened)
            accountMenu.close();
        else if (accountMenu.count)
            accountMenu.open();
    }

    function focusInput() {
        if (showUsername) {
            username.forceActiveFocus();
        } else if (showSecret && canEdit) {
            secretField.forceActiveFocus();
        } else {
            primaryAction.forceActiveFocus();
        }
    }

    implicitWidth: 960
    implicitHeight: 540

    Rectangle {
        anchors.fill: parent
        color: "#113a49"
    }

    Image {
        id: wallpaper
        readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

        anchors.fill: parent
        source: "Mattino.png"
        visible: softwareRendering
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        // A smaller, interpolated texture softens the wallpaper on the software backend.
        sourceSize.width: softwareRendering ? 104 : Math.min(3840, Math.max(1920,
            Math.ceil(Math.max(width, height * 16 / 9) * Screen.devicePixelRatio / 960) * 960))
    }

    MultiEffect {
        anchors.fill: wallpaper
        source: wallpaper
        visible: !wallpaper.softwareRendering
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 52
        blur: 1.0
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#330d263a" }
            GradientStop { position: 0.54; color: "#090d263a" }
            GradientStop { position: 1; color: "#260a271c" }
        }
    }

    Item {
        id: header
        width: parent.width
        height: 60

        property date now: new Date()

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: header.now = new Date()
        }

        component HeaderText: Item {
            property alias text: caption.text
            implicitWidth: caption.implicitWidth
            implicitHeight: caption.implicitHeight

            Text {
                y: 2
                text: caption.text
                font: caption.font
                color: "#ab0a2236"
                style: Text.Outline
                styleColor: "#710a2236"
                Accessible.ignored: true
            }

            Text {
                id: caption
                color: "#ffffff"
                font.family: "Noto Sans"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }

        HeaderText {
            anchors.left: parent.left
            anchors.leftMargin: 23
            anchors.verticalCenter: parent.verticalCenter
            text: header.now.toLocaleDateString(Qt.locale("en_GB"), "dddd d MMMM")
        }

        Image {
            width: 22
            height: 22
            anchors.centerIn: parent
            source: "icons/lock.svg"
            sourceSize.width: 44
            sourceSize.height: 44
        }

        HeaderText {
            anchors.right: parent.right
            anchors.rightMargin: 23
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(header.now, "HH:mm")
        }
    }

    Flickable {
        id: viewport
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.min(scene.keyboardInset, Math.max(0, scene.height - 210))
        width: parent.width
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, panel.height + 32)
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        onHeightChanged: {
            if (scene.keyboardInset && contentHeight > height) {
                contentY = Math.max(0, panel.y + secretField.mapToItem(panel, 0, 0).y
                    + secretField.height + 12 - height);
            }
        }

        Rectangle {
            id: panel
            readonly property int horizontalPadding: Math.round(width * 0.07)
            readonly property int topPadding: Math.round(width * 0.22)
            readonly property int bottomPadding: Math.round(width * 0.05)

            width: Math.min(344, Math.max(288, Math.round(viewport.width * 0.17)), viewport.width - 32)
            height: Math.max(Math.round(width * 1.17), form.implicitHeight + topPadding + bottomPadding)
            radius: 13
            color: "#f8fbfd"
            border.color: "#ffffff"
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(16, Math.round((viewport.contentHeight - height) / 2
                - (scene.keyboardInset ? 0 : header.height / 2)))

            Rectangle {
                z: -1
                x: -1
                y: 5
                width: parent.width + 2
                height: parent.height + 2
                radius: parent.radius + 1
                color: "#3912222f"
            }

            ColumnLayout {
                id: form
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: panel.topPadding
                anchors.leftMargin: panel.horizontalPadding
                anchors.rightMargin: panel.horizontalPadding
                spacing: 6

                Image {
                    readonly property int badgeSize: Math.round(panel.width * 0.30)
                    readonly property int pixelSize: Math.ceil(badgeSize * Screen.devicePixelRatio)

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: badgeSize
                    Layout.preferredHeight: badgeSize
                    Layout.bottomMargin: 2
                    source: "icons/badge.svg"
                    sourceSize: Qt.size(pixelSize, pixelSize)
                }

                Field {
                    id: username
                    Layout.fillWidth: true
                    visible: scene.showUsername
                    placeholderText: qsTr("Username")
                    Accessible.name: placeholderText
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                    onAccepted: secretField.forceActiveFocus()
                }

                Controls.Control {
                    id: accountRow
                    Layout.fillWidth: true
                    implicitHeight: 38
                    visible: !scene.showUsername

                    leftPadding: 12
                    rightPadding: accountMenu.count ? 34 : 12
                    activeFocusOnTab: accountMenu.count > 0
                    Accessible.name: scene.account
                    Accessible.role: accountMenu.count ? Accessible.Button : Accessible.StaticText
                    Accessible.onPressAction: scene.toggleAccountMenu()
                    Keys.onSpacePressed: scene.toggleAccountMenu()
                    Keys.onReturnPressed: scene.toggleAccountMenu()
                    Keys.onEnterPressed: scene.toggleAccountMenu()
                    Keys.onDownPressed: if (!accountMenu.opened) scene.toggleAccountMenu()

                    background: Rectangle {
                        color: accountMenu.opened || (tap.hovered && accountMenu.count) ? "#e0edf6" : "#eaf1f6"
                        border.width: accountRow.activeFocus || accountMenu.opened ? 2 : 1
                        border.color: accountRow.activeFocus || accountMenu.opened ? "#39739c" : "#c2d2df"
                        radius: 8
                    }

                    contentItem: Text {
                        text: scene.account
                        textFormat: Text.PlainText
                        color: "#274259"
                        font.family: "Noto Sans"
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    Image {
                        width: 16
                        height: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        source: "icons/chevron.svg"
                        rotation: accountMenu.opened ? 180 : 0
                        visible: accountMenu.count > 0
                    }

                    HoverHandler { id: tap }
                    TapHandler {
                        enabled: accountMenu.count > 0
                        onTapped: scene.toggleAccountMenu()
                    }
                }

                PickerMenu {
                    id: accountMenu
                    parent: accountRow
                    y: accountRow.height + 5
                    width: accountRow.width
                    closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutsideParent
                }

                Field {
                    id: secretField
                    Layout.fillWidth: true
                    visible: scene.showSecret
                    readOnly: !scene.canEdit
                    echoMode: scene.masked ? TextInput.Password : TextInput.Normal
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                        | (scene.masked ? Qt.ImhHiddenText : 0)
                    placeholderText: scene.secretPlaceholder
                    Accessible.name: placeholderText
                    focus: !scene.showUsername && visible
                    onAccepted: if (scene.canSubmit) scene.submitted()
                }

                Action {
                    id: primaryAction
                    Layout.fillWidth: true
                    primary: true
                    text: scene.actionText
                    enabled: scene.canSubmit
                    focus: !scene.showSecret
                    onClicked: scene.submitted()
                    Keys.onReturnPressed: if (enabled) scene.submitted()
                    Keys.onEnterPressed: if (enabled) scene.submitted()
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: text.length > 0
                    text: scene.message
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    color: scene.messageIsError ? "#932b32" : "#425f75"
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    Accessible.role: Accessible.StaticText
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    Layout.topMargin: Math.round(panel.width * 0.04)

                    RowLayout {
                        id: tools
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                    }

                    RowLayout {
                        id: powerTools
                        readonly property real centeredX: Math.round((parent.width - width) / 2)
                        readonly property real clearOfTools: tools.implicitWidth > 0 ? tools.width + 6 : 0

                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(centeredX, Math.min(parent.width - width, clearOfTools))
                        spacing: 2
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: scene.contextText
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    color: "#526778"
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                }
            }
        }
    }
}
