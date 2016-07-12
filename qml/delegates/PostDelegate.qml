import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import QtGraphicalEffects 1.0

import harbour.hipsterfish.Instagram 1.0
import "../pages"
import "../common"

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
    height: wrapper.height //childrenRect.height

    property bool hasLiked: model.has_liked
    property bool isVideo: !!model.video_versions
    property bool isInView: !(y > ListView.view.contentBottom || y + height < ListView.view.contentY)

    Column {
        id: wrapper

        anchors {
            left: parent.left
            right: parent.right
        }

        height: userInfoRow.height + imageContainer.height + actionButtonRow.height + separator.height + infoColumn.height + 4*Theme.paddingMedium//childrenRect.height

        spacing: Theme.paddingMedium

        Row {
            id: userInfoRow
            height: profilePicture.height + Theme.paddingMedium

            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin
            }

            spacing: Theme.paddingMedium

            ProfilePicture {
                id: profilePicture

                source: model.caption.user.profile_pic_url
                width: Theme.itemSizeExtraSmall
                height: Theme.itemSizeExtraSmall

                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    text: model.user.username
                }

                Label {
                    visible: !!model.location
                    text: model.location ? model.location.name : ''
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
        }

        Item {
            id: imageContainer

            anchors {
                left: parent.left
                right: parent.right
            }

            height: getBestMatch().height * width/getBestMatch().width

            function getBestMatch() {
                var candidates = model.image_versions2.candidates;
                var sorted = candidates.sort(function(a, b) { return a.width - b.width})

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

            Image {
                id: img
                anchors.fill: parent
                source: imageContainer.getBestMatch().url

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
                            onStatusChanged: console.log(status)
                            onPlaybackStateChanged: console.log(playbackState)
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
                                enabled: video.playbackState != MediaPlayer.PlayingState
                                onClicked: {
                                    video.source = getBestVideoMatch().url;
                                    video.play()
                                }

                                function getBestVideoMatch() {
                                    var data = [];
                                    for (var i=0; i<model.video_versions.count; i++) {
                                        data.push(model.video_versions.get(i))
                                    }

                                    var sorted = data.sort(function(a, b) { return a.width - b.width})

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

            Label {
                id: captionLabel
                anchors {
                    left: parent.left
                    right: parent.right
                }

                font.pixelSize: Theme.fontSizeSmall
                text: "<b>" + model.caption.user.username + "</b> " + model.caption.text
                wrapMode: Text.Wrap
            }

            Label {
                id: commentsLabel
                anchors {
                    left: parent.left
                    right: parent.right
                }

                font.pixelSize: Theme.fontSizeSmall
                text: {
                    var text = "";

                    for (var i=0; i<comments.count; i++) {
                        var comment = comments.get(i);

                        text += "<b>" + comment.user.username + "</b> " + comment.text

                        if (i < comments.count-1)
                            text += "<br/>"
                    }

                    return text;
                }

                wrapMode: Text.Wrap
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
