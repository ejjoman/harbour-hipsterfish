import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import QtGraphicalEffects 1.0
import harbour.hipsterfish.Instagram 1.0
import harbour.hipsterfish.Utils 1.0

import "../pages"
import "../common"
import "../js/Utils.js" as Utils

Item {
    id: delegate

    function toggleLike() {
        if (hasLiked)
            InstagramClient.unlike(model.id, function(result) {
                console.debug(JSON.stringify(result))

                if (result.status !== "ok")
                    hasLiked = true
            })
        else
            InstagramClient.like(model.id, function(result) {
                console.debug(JSON.stringify(result))

                if (result.status !== "ok")
                    hasLiked = false
            })

        hasLiked = !hasLiked
    }

    anchors {
        left: parent.left
        right: parent.right
    }

    //width: parent ? parent.width : Screen.width
    height: column.height + Theme.paddingLarge * 2//childrenRect.height

    property bool hasLiked: model.has_liked

    onHasLikedChanged: {
        console.log();

        ListView.view.model.setProperty(model.index, "has_liked", model.has_liked)
        ListView.view.model.setProperty(model.index, "like_count", hasLiked ? model.like_count + 1 : model.like_count - 1)
    }

    // because of ListModel behaviour, internally video_versions is a ListModel, not an array
    property bool isVideo: model.video_versions.count > 0

    readonly property int _viewContentY: ListView.view.contentY

    property bool isInView: ((y >= ListView.view.contentY && y <= ListView.view.contentY + ListView.view.height)
                             || (y + height >= ListView.view.contentY && y + height <= ListView.view.contentY + ListView.view.height)
                             || (y <= ListView.view.contentY && y + height >= ListView.view.contentY + ListView.view.height))

    readonly property ListView view: ListView.view



    MouseArea {
        id: captionItem

        y: Math.min(Math.max(0, _viewContentY - parent.y), parent.height-height)
        z: 2

        height: userInfoRow.height + Theme.paddingMedium * 2

        anchors {
            left: parent.left
            right: parent.right
        }

        onClicked: pageStack.push(Qt.resolvedUrl("../pages/UserProfilePage.qml"), {"userID": model.user.pk})

        FastBlur {
            id: fastBlur
            anchors.fill: parent

            radius: 64

            source: ShaderEffectSource {
                id: fastBlurSource
                sourceItem: column
                sourceRect: Qt.rect(0, captionItem.y, fastBlur.width, fastBlur.height)
            }
        }

        ColorOverlay {
            id: colorOverlay
            source: fastBlur
            anchors.fill: fastBlur
            color: "#40000000"

            Rectangle {
                anchors.fill: parent
                color: Theme.highlightBackgroundColor
                opacity: captionItem.pressed ? 0.3 : 0
                visible: opacity > 0
            }
        }

        Row {
            id: userInfoRow

            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin

                verticalCenter: parent.verticalCenter
            }

            spacing: Theme.paddingMedium

            ProfilePicture {
                id: profilePicture

                source: model.caption.user.profile_pic_url
                width: Theme.itemSizeExtraSmall
                height: Theme.itemSizeExtraSmall

                //anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    text: model.caption.user.username
                    color: Theme.primaryColor
                }

                Label {
                    visible: !!model.location
                    text: model.location ? model.location.name : ''
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
        }
    }


    Item {
        id: wrapper
        height: column.height - captionItem.y - captionItem.height

        clip: true

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge * 2
        }

        Column {
            id: column

            y: captionItem.y

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            height: captionPlaceholder.height + imageContainer.height + actionButtonRow.height + separator.height + infoColumn.height + 4*Theme.paddingMedium//childrenRect.height
            spacing: Theme.paddingMedium

            Item {
                id: captionPlaceholder
                width: parent.width
                height: captionItem.height
            }



            Item {
                id: imageContainer

                anchors {
                    left: parent.left
                    right: parent.right
                }

                readonly property var bestMatch: Utils.getBestMatch(model.image_versions2.candidates, width, 0, false)
                height: bestMatch.height * width/bestMatch.width

                Image {
                    id: img
                    anchors.fill: parent
                    source: imageContainer.bestMatch.url
                    sourceSize {
                        width: width
                        height: height
                    }

                    opacity: img.status === Image.Ready ? 1 : 0

                    Behavior on opacity {
                        FadeAnimator {}
                    }
                }

                ProgressCircle {
                    anchors.centerIn: parent
                    visible: img.status !== Image.Ready
                    inAlternateCycle: true
                    value: img.progress
                }

                Loader {
                    anchors.fill: parent
                    active: isVideo

                    sourceComponent: Component {
                        Item {
                            anchors.fill: parent

                            MediaPlayer {
                                id: video
                                autoPlay: false
                                autoLoad: false
                                onStatusChanged: console.log(status)
                                onPlaybackStateChanged: console.log(playbackState)

                                source: getBestVideoMatch().url;

                                function getBestVideoMatch() {
                                    var video_versions = [];

                                    for (var i=0; i<model.video_versions.count; i++)
                                        video_versions.push(model.video_versions.get(i));

                                    var sorted = video_versions.sort(function(a, b) { return a.width - b.width})

                                    var largest = null;

                                    for (var key in sorted) {
                                        var width = sorted[key].width;

                                        if (!largest || largest.width < width) {
                                            largest = {key: key, width: width}
                                        }

                                        if (width >= parent.width) {
                                            //console.log("Found best match:", sorted[key].width + "x" + sorted[key].height);
                                            return sorted[key];
                                        }
                                    }

                                    //console.log("Found no good match, use largest instead:", sorted[largest.key].width + "x" + sorted[largest.key].height);

                                    return sorted[largest.key];
                                }
                            }

                            VideoOutput {
                                id: videoOutput
                                anchors.fill: parent
                                source: video
                            }

                            Item {
                                anchors.fill: parent
                                visible: isVideo

                                Rectangle {
                                    color: mouseArea.down ? Theme.primaryColor : Theme.highlightBackgroundColor
                                    opacity: .5
                                    radius: height/2
                                    anchors.fill: playbackImage
                                    visible: playbackImage.visible
                                }

                                Image {
                                    id: playbackImage
                                    anchors.centerIn: parent
                                    source: "image://theme/icon-l-play?" + (mouseArea.down ? Theme.highlightBackgroundColor : Theme.primaryColor)
                                    //sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                                    //sourceSize.width: Theme.iconSizeMedium

                                    visible: video.playbackState != MediaPlayer.PlayingState

                                    //visible: false
                                }


                                MouseArea {
                                    id: mouseArea

                                    property bool down: pressed && containsMouse
                                    anchors.fill: parent
                                    //enabled: video.playbackState != MediaPlayer.PlayingState
                                    onClicked: {
                                        if (video.playbackState != MediaPlayer.PlayingState)
                                            video.play()
                                        else
                                            video.pause()
                                    }
                                }
                            }

                            Connections {
                                target: delegate
                                onIsInViewChanged: {
                                    if (!delegate.isInView && video.playbackState == MediaPlayer.PlayingState)
                                        video.pause()
                                }
                            }
                        }
                    }
                }
            }

            Row {
                id: actionButtonRow
                height: Theme.iconSizeMedium

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }

                layoutDirection: Qt.RightToLeft

                IconButton {
                    highlighted: hasLiked
                    icon.source: "image://theme/icon-m-like?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)

                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium

                    onClicked: delegate.toggleLike()
                }

                IconButton {
                    icon.source: "image://theme/icon-m-chat?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)

                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("../pages/CommentsPage.qml"), {"mediaID": model.id})
                    }
                }

                IconButton {
                    icon.source: "image://theme/icon-m-share?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)

                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                }
            }

            Separator {
                id: separator

                color: Theme.primaryColor
                anchors {
                    //topMargin: Theme.paddingSmall
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
            }

            Column {
                id: infoColumn
                height: likesLabel.height + captionLabel.height + commentsLabel.height + timestampLabel.height //childrenRect.height

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }

                Label {
                    id: likesLabel
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    font.pixelSize: Theme.fontSizeSmall
                    text: isVideo ? qsTr("<b>%L1</b> views").arg(model.view_count) : qsTr("<b>%L1</b> likes").arg(model.like_count)
                }

                InstagramLabel {
                    id: captionLabel
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    font.pixelSize: Theme.fontSizeSmall
                    text: "<b>" + model.caption.user.username + "</b> " + StringUtils.toHtmlEscaped(model.caption.text)
                    wrapMode: Text.Wrap
                }

                InstagramLabel {
                    id: commentsLabel
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    font.pixelSize: Theme.fontSizeSmall
                    text: {
                        var text = "";

                        for (var i=0; i<model.comments.count; i++) {
                            var comment = comments.get(i);

                            text += "<b>" + comment.user.username + "</b> " + StringUtils.toHtmlEscaped(comment.text)

                            if (i < comments.count-1)
                                text += "<br/>"
                        }

                        return text;
                    }

                    wrapMode: Text.Wrap
                    visible: text !== ""
                }

    //            Repeater {
    //                model: comments

    //                delegate: Label {
    //                    anchors {
    //                        left: parent.left
    //                        right: parent.right
    //                    }

    //                    font.pixelSize: Theme.fontSizeSmall
    //                    text: "<b>" + model.user.username + "</b> " + model.text
    //                    wrapMode: Text.Wrap
    //                }
    //            }

                Label {
                    id: timestampLabel
                    text: Format.formatDate(new Date(model.caption.created_at * 1000), Formatter.DurationElapsed)
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }
        }
    }



}
