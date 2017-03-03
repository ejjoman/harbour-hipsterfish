import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import harbour.hipsterfish.Instagram 1.0
import "js/Utils.js" as Utils

ApplicationWindow
{
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All

    Connections {
        target: InstagramClient

        onCurrentAccountChanged: {
            console.debug("current account changed:", InstagramClient.currentAccount);

            if (InstagramClient.currentAccount) {
                pageStack.replaceAbove(null, Qt.resolvedUrl("pages/StartPage.qml"));
            } else {
                if (InstagramAccountManager.hasAccount) {
                    pageStack.replaceAbove(null, Qt.resolvedUrl("pages/LoginPage.qml"));
                } else {
                    pageStack.replaceAbove(null, Qt.resolvedUrl("pages/AccountSelectionPage.qml"));
                }
            }
        }

        //onAccountCreated:
        onAccountNeedsRelogin: {
            console.log("qml side... ", account)

            pageStack.replaceAbove(null, Qt.resolvedUrl("pages/LoginPage.qml"), {"account" : account});
        }
    }

    Component.onCompleted: {
        // for QML live
        if (InstagramClient.currentAccount) {
            pageStack.replaceAbove(null, Qt.resolvedUrl("pages/StartPage.qml"));
        }

        if (!InstagramAccountManager.hasAccount) {
            // account creation page
            pageStack.replaceAbove(null, Qt.resolvedUrl("pages/LoginPage.qml"));
        } else if(InstagramAccountManager.defaultAccount) {
            InstagramClient.currentAccount = InstagramAccountManager.defaultAccount;
        } else {
            pageStack.replaceAbove(null, Qt.resolvedUrl("pages/AccountSelectionPage.qml"));
        }
    }
}


