import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

import "../common"

Page {
    property alias userID: userProfile.userID
    property alias username: userProfile.username

    UserProfile {
        id: userProfile
        anchors.fill: parent
    }

    Component.onCompleted: userProfile.load()
}
