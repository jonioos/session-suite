import QtQuick
import QtQuick.Controls as Controls
import "mattino" as Mattino

Mattino.Scene {
    id: login

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property string selectedUser: userModel.lastUser || ""
    property string selectedName: ""
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string sessionName: ""
    property bool manualUser: false
    property bool pending: false
    property bool failed: false

    readonly property string userToAuthenticate: showUsername ? username.text.trim() : selectedUser

    focus: true
    account: selectedName || selectedUser
    actionText: pending ? qsTr("Signing in…") : qsTr("Sign in")
    message: failed ? qsTr("Sign-in failed. Check your username and password.") : ""
    messageIsError: failed
    showUsername: manualUser || selectedUser.length === 0
    canEdit: !pending
    username.readOnly: pending
    canSubmit: !pending && userToAuthenticate.length > 0
    keyboardInset: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0

    function selectUser(index, name, realName) {
        userIndex = index;
        selectedUser = name;
        selectedName = realName;
        manualUser = false;
        resetInput();
    }

    function resetInput() {
        secret.clear();
        failed = false;
        focusInput();
    }

    onSubmitted: {
        pending = true;
        failed = false;
        sddm.login(userToAuthenticate, secret.text, sessionIndex);
        secret.clear();
    }

    Component.onCompleted: focusInput()

    Keys.onEscapePressed: {
        if (manualUser && selectedUser) {
            manualUser = false;
            resetInput();
        } else {
            secret.clear();
        }
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            login.pending = false;
            login.focusInput();
            login.failed = true;
        }

        function onLoginSucceeded() {
            login.secret.clear();
        }
    }

    accountMenu.onOpened: accountMenu.currentIndex = login.userIndex

    Instantiator {
        model: userModel

        delegate: Mattino.PickerOption {
            required property int index
            required property string name
            required property string realName

            text: realName || name
            selected: !login.manualUser && login.userIndex === index

            Component.onCompleted: {
                if (index === login.userIndex) {
                    login.selectedUser = name;
                    login.selectedName = realName;
                }
            }

            onTriggered: login.selectUser(index, name, realName)
        }

        onObjectAdded: (index, object) => login.accountMenu.insertItem(index, object)
        onObjectRemoved: (index, object) => login.accountMenu.removeItem(object)
    }

    Mattino.PickerOption {
        id: otherUser
        text: qsTr("Other user…")
        onTriggered: {
            login.manualUser = true;
            login.username.clear();
            login.resetInput();
        }

        Component.onCompleted: login.accountMenu.addItem(otherUser)
    }

    tools: [
        Mattino.Action {
            glyph: "switch"
            visible: login.showUsername && login.selectedUser.length > 0
            enabled: !login.pending
            Accessible.name: qsTr("Return to the selected user")
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: Accessible.name
            onClicked: {
                login.manualUser = false;
                login.resetInput();
            }
        },
        Mattino.Action {
            glyph: "session"
            visible: sessionsMenu.count > 1
            enabled: !login.pending
            Accessible.name: qsTr("Switch session")
            Controls.ToolTip.visible: hovered && !sessionsMenu.opened
            Controls.ToolTip.text: login.sessionName || Accessible.name
            onClicked: sessionsMenu.open()

            Mattino.PickerMenu {
                id: sessionsMenu
                width: 182
                x: Math.round((parent.width - width) / 2)
                y: parent.height + 4
                onOpened: currentIndex = login.sessionIndex

                Instantiator {
                    model: sessionModel

                    delegate: Mattino.PickerOption {
                        required property int index
                        required property string name

                        text: name
                        selected: login.sessionIndex === index

                        Component.onCompleted: {
                            if (index === login.sessionIndex)
                                login.sessionName = name;
                        }

                        onTriggered: {
                            login.sessionIndex = index;
                            login.sessionName = name;
                        }
                    }

                    onObjectAdded: (index, object) => sessionsMenu.insertItem(index, object)
                    onObjectRemoved: (index, object) => sessionsMenu.removeItem(object)
                }
            }
        },
        Mattino.Action {
            glyph: "keyboard"
            visible: keyboard.layouts.length > 1
            Accessible.name: qsTr("Switch keyboard layout")
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: keyboard.layouts[keyboard.currentLayout]?.longName || Accessible.name
            onClicked: {
                keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length;
                login.focusInput();
            }
        }
    ]

    powerTools: [
        Mattino.Action {
            glyph: "reboot"
            visible: sddm.canReboot
            enabled: !login.pending
            Accessible.name: qsTr("Restart")
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: Accessible.name
            onClicked: sddm.reboot()
        },
        Mattino.Action {
            glyph: "power"
            enabled: !login.pending && (sddm.canSuspend || sddm.canHibernate)
            Accessible.name: qsTr("Suspend and hibernate")
            Controls.ToolTip.visible: hovered && !powerMenu.opened
            Controls.ToolTip.text: Accessible.name
            onClicked: powerMenu.open()

            Mattino.PickerMenu {
                id: powerMenu
                x: Math.round((parent.width - width) / 2)
                y: parent.height + 4

                Mattino.PickerOption { text: qsTr("Suspend"); enabled: sddm.canSuspend; onTriggered: sddm.suspend() }
                Mattino.PickerOption { text: qsTr("Hibernate"); enabled: sddm.canHibernate; onTriggered: sddm.hibernate() }
            }
        },
        Mattino.Action {
            glyph: "stop"
            visible: sddm.canPowerOff
            enabled: !login.pending
            Accessible.name: qsTr("Shut down")
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: Accessible.name
            onClicked: sddm.powerOff()
        }
    ]
}
