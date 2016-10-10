import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"

ListItem {
    property var modelData
    contentHeight: row.height

    Row {
        id: row
        height: profilePicture.height + Theme.paddingMedium * 2

        anchors {
            //fill: parent
            left: parent.left
            right: parent.right
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin

            verticalCenter: parent.verticalCenter
        }

        spacing: Theme.paddingMedium

        ProfilePicture {
            id: profilePicture

            source: modelData.profile_pic_url
            width: Theme.itemSizeExtraSmall
            height: Theme.itemSizeExtraSmall

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            Label {
                text: modelData.username
            }

            Label {
                text: modelData.full_name
                visible: text.length > 0
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }
        }
    }

    onClicked: {
        pageStack.push(Qt.resolvedUrl("../pages/UserProfilePage.qml"), {"userID": modelData.pk})
    }
}
