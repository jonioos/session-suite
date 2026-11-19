import QtQuick
import QtQuick.Controls as Controls
import org.kde.plasma.private.sessions 2.0
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.plasma.workspace.components as Workspace
import org.kde.plasma.workspace.keyboardlayout as Keyboards
import org.kde.kscreenlocker 1.0 as ScreenLocker
import "mattino" as Mattino

Item {
    id: root

    // Properties and hooks supplied by KScreenLocker.
    property bool viewVisible: false
    property bool locked: false
    property bool suspendToRamSupported: false
    property bool suspendToDiskSupported: false
    signal suspendToRam()
    signal suspendToDisk()

    property bool secretPrompt: true
    property bool readyToUnlock: false
    property string promptText: ""
    property string notification: ""
    property bool authError: false

    implicitWidth: 960
    implicitHeight: 540

    function clearInput() {
        PasswordSync.password = "";
        screen.secret.clear();
        screen.secret.text = Qt.binding(() => PasswordSync.password);
    }

    function awaitPrompt(secret, prompt) {
        root.secretPrompt = secret;
        root.promptText = prompt.trim().replace(/:\s*$/, "");
        root.clearInput();
        Mattino.UnlockState.awaitingResponse = true;
        screen.focusInput();
    }

    function finishUnlock() {
        if (Mattino.UnlockState.finishing)
            return;

        Mattino.UnlockState.finishing = true;
        switch (Mattino.UnlockState.powerAction) {
        case "reboot":
            sessionManagement.requestReboot(SessionManagement.ForcePrompt);
            break;
        case "stop":
            sessionManagement.requestShutdown(SessionManagement.ForcePrompt);
            break;
        }
        Qt.quit();
    }

    function selectPowerAction(action) {
        const state = Mattino.UnlockState;
        state.powerAction = state.powerAction === action ? "" : action;
        screen.focusInput();
    }

    onViewVisibleChanged: {
        if (viewVisible) {
            authenticator.startAuthenticating();
            screen.focusInput();
        }
    }

    onLockedChanged: {
        if (locked && viewVisible)
            authenticator.startAuthenticating();
    }

    SessionManagement {
        id: sessionManagement
    }

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    Workspace.KeyboardLayoutSwitcher {
        id: layoutSwitcher
        visible: false
    }

    Connections {
        target: sessionManagement
        function onAboutToSuspend() {
            Mattino.UnlockState.powerAction = "";
            root.clearInput();
        }
    }

    Connections {
        target: authenticator

        function onPromptForSecretChanged() {
            root.awaitPrompt(true, authenticator.promptForSecret);
        }

        function onPromptChanged() {
            root.awaitPrompt(false, authenticator.prompt);
        }

        function onInfoMessageChanged() {
            root.notification = authenticator.infoMessage;
            root.authError = false;
        }

        function onErrorMessageChanged() {
            root.notification = authenticator.errorMessage;
            root.authError = true;
        }

        function onFailed(kind) {
            if (kind !== 0)
                return;

            root.clearInput();
            Mattino.UnlockState.awaitingResponse = false;
            root.authError = true;
            root.notification = qsTr("Unlock failed. Try again.");
            retry.restart();
        }

        function onSucceeded() {
            root.clearInput();
            Mattino.UnlockState.awaitingResponse = false;
            if (authenticator.hadPrompt) {
                root.finishUnlock();
            } else {
                root.readyToUnlock = true;
                screen.focusInput();
            }
        }
    }

    Timer {
        id: retry
        interval: 3000
        onTriggered: {
            root.notification = "";
            root.authError = false;
            authenticator.startAuthenticating();
        }
    }

    Mattino.Scene {
        id: screen
        anchors.fill: parent
        focus: true

        account: kscreenlocker_userName
        actionText: {
            switch (Mattino.UnlockState.powerAction) {
            case "reboot": return qsTr("Unlock to restart");
            case "stop": return qsTr("Unlock to shut down");
            default: return qsTr("Unlock");
            }
        }
        secretPlaceholder: root.promptText || (root.secretPrompt ? qsTr("Password") : qsTr("Response"))
        showSecret: !root.readyToUnlock
        canEdit: !retry.running
        masked: root.secretPrompt
        canSubmit: root.readyToUnlock || Mattino.UnlockState.awaitingResponse
        keyboardInset: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0
        messageIsError: root.authError
        message: [root.notification, capsLockState.locked ? qsTr("Caps Lock is on") : ""]
            .filter(text => text.length > 0).join(" · ")
        contextText: {
            if (authenticator.authenticatorTypes & ScreenLocker.Authenticator.Fingerprint)
                return qsTr("You can use the fingerprint reader");
            if (authenticator.authenticatorTypes & ScreenLocker.Authenticator.Smartcard)
                return qsTr("You can use your smart card");
            return "";
        }

        secret.text: PasswordSync.password
        secret.onTextEdited: PasswordSync.password = secret.text

        onSubmitted: {
            if (root.readyToUnlock) {
                root.finishUnlock();
            } else if (Mattino.UnlockState.awaitingResponse) {
                const response = secret.text;
                Mattino.UnlockState.awaitingResponse = false;
                root.notification = "";
                root.authError = false;
                root.clearInput();
                authenticator.respond(response);
            }
        }

        Keys.onEscapePressed: {
            Mattino.UnlockState.powerAction = "";
            root.clearInput();
            Qt.inputMethod.hide();
        }

        tools: [
            Mattino.Action {
                glyph: "keyboard"
                visible: layoutSwitcher.hasMultipleKeyboardLayouts
                Accessible.name: qsTr("Switch keyboard layout")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: layoutSwitcher.layoutNames.longName || Accessible.name
                onClicked: {
                    layoutSwitcher.keyboardLayout.switchToNextLayout();
                    screen.focusInput();
                }
            },
            Mattino.Action {
                glyph: "keyboard"
                visible: Qt.platform.pluginName.includes("wayland") && Keyboards.KWinVirtualKeyboard.active
                Accessible.name: qsTr("On-screen keyboard")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: Accessible.name
                onClicked: {
                    screen.focusInput();
                    Keyboards.KWinVirtualKeyboard.enabled = true;
                    Qt.inputMethod.show();
                }
            },
            Mattino.Action {
                glyph: "switch"
                visible: sessionManagement.canSwitchUser
                Accessible.name: qsTr("Switch user")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: Accessible.name
                onClicked: sessionManagement.switchUser()
            }
        ]

        powerTools: [
            Mattino.Action {
                glyph: "reboot"
                visible: sessionManagement.canReboot
                selected: Mattino.UnlockState.powerAction === "reboot"
                Accessible.name: qsTr("Restart")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: Accessible.name
                onClicked: root.selectPowerAction("reboot")
            },
            Mattino.Action {
                glyph: "power"
                enabled: root.suspendToRamSupported || root.suspendToDiskSupported
                Accessible.name: qsTr("Suspend and hibernate")
                Controls.ToolTip.visible: hovered && !sleepMenu.opened
                Controls.ToolTip.text: Accessible.name
                onClicked: sleepMenu.open()

                Mattino.PickerMenu {
                    id: sleepMenu
                    x: Math.round((parent.width - width) / 2)
                    y: parent.height + 4

                    Mattino.PickerOption { text: qsTr("Suspend"); enabled: root.suspendToRamSupported; onTriggered: root.suspendToRam() }
                    Mattino.PickerOption { text: qsTr("Hibernate"); enabled: root.suspendToDiskSupported; onTriggered: root.suspendToDisk() }
                }
            },
            Mattino.Action {
                glyph: "stop"
                visible: sessionManagement.canShutdown
                selected: Mattino.UnlockState.powerAction === "stop"
                Accessible.name: qsTr("Shut down")
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: Accessible.name
                onClicked: root.selectPowerAction("stop")
            }
        ]
    }

    Loader {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        active: root.viewVisible
        source: "LockOsd.qml"
    }
}
