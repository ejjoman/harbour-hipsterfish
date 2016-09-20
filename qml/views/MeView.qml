import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

import "../common"

BaseView {
    function scrollToTop() {
        gridView.scrollToTop()
    }

    function init() {
        console.log("init...")
        userProfile.load()
    }

    UserProfile {
        id: userProfile
        userID: InstagramClient.currentAccount.userID
        anchors.fill: parent
    }
}
