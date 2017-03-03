import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property bool isFollowing: false
    property bool showSuggestedButton: true
    property bool showLabelInSplitMode: false

    signal toggleFollowButtonClicked
    signal showSuggestionsButtonClicked

    width: Theme.buttonWidthSmall * .75
    height: Theme.itemSizeSmall * .5 + Theme.paddingSmall

    InstagramButton {
        id: followButton
        hightlight: isFollowing

        label: hightlight ? qsTr("Following") : qsTr("Follow")
        labelVisible: !showSuggestedButton || showLabelInSplitMode
        iconSource: "image://theme/icon-s-favorite?" + (followButton.pressed ? Theme.highlightColor : Theme.primaryColor)

        anchors {
            left: parent.left
            bottom: parent.bottom
            top: parent.top
            right: showSuggestedButton ? suggestedButton.left : parent.right
            rightMargin: showSuggestedButton ? Theme.paddingSmall : 0
        }

        onClicked: toggleFollowButtonClicked()
    }

//    MouseArea {
//        id: followButtonMouseArea

//        anchors {
//            left: parent.left
//            bottom: parent.bottom
//            top: parent.top
//            right: showSuggestedButton ? suggestedButtonMouseArea.left : parent.right
//            rightMargin: showSuggestedButton ? Theme.paddingSmall : 0
//        }

//        //width: showSuggestedButton ? parent.width - suggestedButtonMouseArea.width : implicitWidth

//        Rectangle {
//            anchors.fill: parent

//            border.color: {
//                if (followButtonMouseArea.pressed)
//                    return Theme.highlightColor

//                return isFollowing ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity) : Theme.primaryColor
//            }

//            border.width: Theme.paddingSmall / 4

//            radius: Theme.paddingSmall
//            color: isFollowing ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity) : "transparent"

//            Row {
//                id: row
//                width: Math.min(implicitWidth, _maxWidth)
//                anchors.centerIn: parent

//                spacing: Theme.paddingSmall

//                Image {
//                    id: icon
//                    source: "image://theme/icon-s-favorite?" + (followButtonMouseArea.pressed ? Theme.highlightColor : Theme.primaryColor)
//                }

//                Label {
//                    font.pixelSize: Theme.fontSizeExtraSmall
//                    text: isFollowing ? qsTr("Following") : qsTr("Follow")
//                    color: followButtonMouseArea.pressed ? Theme.highlightColor : Theme.primaryColor
//                    truncationMode: TruncationMode.Fade
//                    width: Math.min(contentWidth, _maxWidth - icon.width - row.spacing)

//                    visible: !showSuggestedButton || showLabelInSplitMode
//                }
//            }
//        }

//        onClicked: toggleFollowButtonClicked()
//    }

    InstagramButton {
        id: suggestedButton
        hightlight: isFollowing

        visible: showSuggestedButton
        iconSource: "image://theme/icon-cover-play?" + (suggestedButton.pressed ? Theme.highlightColor : Theme.primaryColor)

        anchors {
            bottom: parent.bottom
            top: parent.top
            right: parent.right
        }

        width: showLabelInSplitMode ? height : parent.width / 2 - Theme.paddingSmall
        onClicked: showSuggestionsButtonClicked()
    }


//    MouseArea {
//        id: suggestedButtonMouseArea

//        visible: showSuggestedButton

//        anchors {
//            bottom: parent.bottom
//            top: parent.top
//            right: parent.right
//        }

//        width: showLabelInSplitMode ? height : parent.width / 2 - Theme.paddingSmall

//        Rectangle {
//            anchors.fill: parent

//            border.color: {
//                if (suggestedButtonMouseArea.pressed)
//                    return Theme.highlightColor

//                return isFollowing ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity) : Theme.primaryColor
//            }

//            border.width: Theme.paddingSmall / 4

//            radius: Theme.paddingSmall
//            color: isFollowing ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity) : "transparent"

//            Image {
//                id: suggestedIcon
//                source: "image://theme/icon-cover-play?" + (suggestedButtonMouseArea.pressed ? Theme.highlightColor : Theme.primaryColor)
//                anchors.centerIn: parent
//            }
//        }

//        onClicked: showSuggestionsButtonClicked()
//    }
}
