import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"

ListItem {
    property var modelData
    property bool showFollowButton: false

    contentHeight: profilePicture.height + Theme.paddingMedium * 2

    ProfilePicture {
        id: profilePicture

        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin

            verticalCenter: parent.verticalCenter
        }

        source: modelData.profile_pic_url
        width: Theme.itemSizeExtraSmall
        height: Theme.itemSizeExtraSmall
    }

    Column {
        anchors {
            left: profilePicture.right
            leftMargin: Theme.paddingMedium

            right: showFollowButton ? followButtonLoader.left : parent.right
            rightMargin: showFollowButton ? Theme.paddingLarge : Theme.horizontalPageMargin

            verticalCenter: parent.verticalCenter
        }

        Label {
            text: modelData.username
            width: parent.width

            truncationMode: TruncationMode.Fade
        }

        Label {
            text: modelData.full_name
            width: parent.width
            visible: text.length > 0
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor

            truncationMode: TruncationMode.Fade
        }
    }

    Loader {
        id: followButtonLoader
        active: showFollowButton

        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin

            verticalCenter: parent.verticalCenter
        }

        sourceComponent: Component {
            FollowButton {
                id: followButton

                //opacity: modelData.friendshipstatus_loaded ? 1 : 0

                Behavior on opacity {
                    FadeAnimator {}
                }

                isFollowing: modelData.friendshipstatus_loaded && modelData.following
                showSuggestedButton: isFollowing && modelData.has_chaining
                showLabelInSplitMode: false
            }
        }
    }

    onClicked: {
        pageStack.push(Qt.resolvedUrl("../pages/UserProfilePage.qml"), {"userID": modelData.pk})
    }
}
