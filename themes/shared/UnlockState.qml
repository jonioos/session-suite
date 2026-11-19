pragma Singleton

import QtQml

QtObject {
    // KScreenLocker relays keyboard events to every screen in the same engine.
    property bool awaitingResponse: false
    property bool finishing: false
    property string powerAction: ""
}
