import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Item {
    id: root

    implicitWidth: profilePicture.sourceSize.width
    implicitHeight: profilePicture.sourceSize.height

    property alias source: profilePicture.source

    property var userID

    opacity: profilePicture.status === Image.Ready ? 1 : 0

    Behavior on opacity {
        FadeAnimator {}
    }

    Image {
        id: profilePicture

        anchors.fill: parent
        visible: false
        //source: model.user.profile_pic_url

        sourceSize {
            width: width
            height: height
        }
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: width / 2
        color: "black"
        visible: false
    }

    OpacityMask {
        anchors.fill: parent
        source: profilePicture
        maskSource: mask
    }

    MouseArea {
        anchors.fill: parent
        enabled: !!root.userID

        onClicked: {
            pageStack.push(Qt.resolvedUrl("../pages/UserProfilePage.qml"), {"userID": root.userID})
        }
    }
}
