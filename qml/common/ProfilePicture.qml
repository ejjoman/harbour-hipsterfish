import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Item {
    id: root

    implicitWidth: profilePicture.sourceSize.width
    implicitHeight: profilePicture.sourceSize.height

    property alias source: profilePicture.source

    Image {
        anchors.fill: parent

        id: profilePicture
        visible: false
        source: model.user.profile_pic_url
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
}
