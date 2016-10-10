import QtQuick 2.1
import QtQuick.Layouts 1.1
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0
import harbour.hipsterfish.Utils 1.0
import "../common"
import "../delegates"
import "../js/Utils.js" as Utils

Item {
    id: root

    // cannot use int here because QML int can just handle integers of arround (+/-)2000000000
    property var userID
    property string username

    anchors.fill: parent

    function load() {
        InstagramClient.loadUserInfo(userID || username, function(result) {
            //console.debug(JSON.stringify(result, null, 4));

            if (result.status !== "ok")
                return;

            userID = result.user.pk;

            header.title = result.user.username;
            header.description = result.user.full_name;

            biographyLabel.text = StringUtils.toHtmlEscaped(result.user.biography)

            if (result.user.external_url)
                externalUrlLabel.text = "<a href='%1'>%1</a>".arg(result.user.external_url)

            if (result.user.profile_context)
                contextLabel.text = result.user.profile_context

            profilePicture.source = result.user.profile_pic_url
            postsDetailItem.value = result.user.media_count
            followersDetailItem.value = result.user.follower_count
            follwingDetailItem.value = result.user.following_count

            feedModel.loadData(true);
        })
    }

    Column {
        id: headerComponent

        parent: view.view.contentItem
        y: view.view.headerItem.y

        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }

        height: childrenRect.height + Theme.paddingLarge

        PageHeader {
            id: header

            // margins are coming from  the column
            rightMargin: 0
            leftMargin: 0
        }

        Column {
            anchors {
                left: parent.left
                right: parent.right
            }

            spacing: Theme.paddingLarge

            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                spacing: Theme.paddingLarge

                ProfilePicture {
                    id: profilePicture

                    width: Theme.itemSizeExtraLarge
                    height: width
                }

                Row {
                    Layout.fillWidth: true

                    spacing: Theme.paddingMedium

                    readonly property int itemWidth: ((width + spacing) / children.length) - spacing

                    ProfileDetailItem {
                        width: parent.itemWidth

                        id: postsDetailItem
                        label: qsTr("Posts")
                    }

                    ProfileDetailItem {
                        id: followersDetailItem

                        width: parent.itemWidth
                        label: qsTr("Followers")
                        abbreviate: true

                        onClicked: pageStack.push("../pages/FriendshipsPage.qml", {
                                                      userID: root.userID,
                                                      friendshipType: InstagramClient.Followers
                                                  })
                    }

                    ProfileDetailItem {
                        id: follwingDetailItem

                        width: parent.itemWidth
                        label: qsTr("Following")

                        onClicked: pageStack.push("../pages/FriendshipsPage.qml", {
                                                      userID: root.userID,
                                                      friendshipType: InstagramClient.Following
                                                  })
                    }
                }
            }

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                spacing: Theme.paddingSmall

                InstagramLabel {
                    id: biographyLabel

                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    wrapMode: Text.Wrap
                    visible: text.length > 0

                    font.pixelSize: Theme.fontSizeSmall
                }

                Label {
                    linkColor: Theme.highlightColor
                    id: externalUrlLabel

                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    wrapMode: Text.Wrap
                    visible: text.length > 0

                    font.pixelSize: Theme.fontSizeSmall

                    onLinkActivated: Qt.openUrlExternally(link)
                }


                Label {
                    id: contextLabel

                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    wrapMode: Text.Wrap
                    visible: text.length > 0

                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
        }
    }

    FeedView {
        id: view
        model: feedModel

        anchors.fill: parent

        view.header: Item {
            width: view.width
            height: headerComponent.height
        }
    }

    InstagramModel {
        id: feedModel
        query: "$.items.*"

        attachedProperties: ({
            "id": null,
            "has_liked": false,
            "video_versions": [],
            "caption": {
                "user": {
                    "profile_pic_url": "",
                    "username": ""
                },
                "text": "",
                "created_at": 0
            },
            "location": {
                "name": ""
            },
            "image_versions2": [],
            "view_count": 0,
            "like_count": 0,
            "user": {
                "profile_pic_url": "",
                "username": ""
            },
            "text": "",
            "comments": []
        })


        function loadData(clear) {
            isLoading = true

            var nextID = canLoadMore && !clear ? nextMaxID : "";

            InstagramClient.loadUserFeed(userID, nextID, function(result) {
                //console.log(JSON.stringify(result, null, 4))

                updateJSONModel(result, clear)

                if (result.more_available)
                    nextMaxID = result.next_max_id;
                else
                    nextMaxID = "";

                isLoading = false;
            });
        }
    }

}
