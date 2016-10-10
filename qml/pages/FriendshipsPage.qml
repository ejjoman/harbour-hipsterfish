import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0
import harbour.hipsterfish.Utils 1.0

import "../common"
import "../delegates"

import "../js/jsonpath.js" as JSONPath

Page {
    id: root

    property var userID;
    property int friendshipType;

    property alias isLoading: friendshipsModel.isLoading;

    readonly property string _rankToken: InstagramClient.createCleanedUuid()

    InstagramModel {
        id: friendshipsModel
        query: "$.sections.*.users.*"

        attachedProperties: ({
            "username": null,
            "has_anonymous_profile_picture": false,
            "is_favorite": false,
            "has_chaining": true,
            "profile_pic_url": null,
            "profile_pic_id": null,
            "full_name": null,
            "pk": -1,
            "is_verified": false,
            "is_private": false,
            "following": false,
            "incoming_request": false,
            "outgoing_request": false,
            "friendshipstatus_loaded": false
        })

        property var _ids: []

        function loadData(clear) {
            isLoading = true;

            var nextID = !clear && friendshipsModel.canLoadMore ? friendshipsModel.nextMaxID : "";

            InstagramClient.loadFriendships(friendshipType, userID, "overview", nextID, _rankToken, function(result) {
                //console.log(JSON.stringify(result, null, 4))

                if (result.status !== "ok") {
                    isLoading = false;
                    return;
                }

                friendshipsModel.updateJSONModel(result, clear);

                if (result.big_list)
                    friendshipsModel.nextMaxID = result.next_max_id;
                else
                    friendshipsModel.nextMaxID = "";

                var indexedUserIDs = JSONPath.jsonPath(result, "$.sections.*.users[*].pk");
                var userIDs = [];

                for (var index in indexedUserIDs) {
                    userIDs.push(indexedUserIDs[index]);
                    _ids[indexedUserIDs[index]] = index;
                }

                InstagramClient.loadFriendshipStatus(userIDs, function(friendshipStatusResult) {
                    if (friendshipStatusResult.status !== "ok")
                        return;

                    for (var statusUserID in friendshipStatusResult.friendship_statuses) {
                        var status = friendshipStatusResult.friendship_statuses[statusUserID];
                        var userIndex = _ids[statusUserID]

                        var test = friendshipsModel.model.get(userIndex);


                        friendshipsModel.model.setProperty(userIndex, "following", status.following);
                        friendshipsModel.model.setProperty(userIndex, "incoming_request", status.incoming_request);
                        friendshipsModel.model.setProperty(userIndex, "outgoing_request", status.outgoing_request);
                        friendshipsModel.model.setProperty(userIndex, "is_private", status.is_private);

                        friendshipsModel.model.setProperty(userIndex, "friendshipstatus_loaded", true);

                        test = friendshipsModel.model.get(userIndex);
                    }
                })


                isLoading = false;
            })
        }
    }

    property int currentIndex: 0
    onCurrentIndexChanged: loadMore();

    function loadMore() {
        if (!friendshipsModel.canLoadMore || root.isLoading || friendshipsView.quickScrollAnimating)
            return;

        if (friendshipsModel.count - (currentIndex+1) <= 2)
            friendshipsModel.loadData(false)
    }

    SilicaListView {
        id: friendshipsView

        clip: true
        currentIndex: -1

        anchors.fill: parent
        model: friendshipsModel.model
        spacing: Theme.paddingLarge

        onContentYChanged: {
            var idx = indexAt(0, contentY + height)

            if (idx >= 0)
                root.currentIndex = idx
        }

        onQuickScrollAnimatingChanged: root.loadMore();

        header: PageHeader {
            title: friendshipType == InstagramClient.Followers ? qsTr("Followers") : qsTr("Following")
        }

        footer: LoadingMoreIndicator {
            visible: isLoading
        }

        delegate: UserListItem {
            modelData: model
            menu: contextMenu

            Component {
                id: contextMenu

                ContextMenu {
                    MenuItem {
                        text: qsTr("Show suggested friends")
                        visible: model.friendshipstatus_loaded && model.following
                    }

                    MenuItem {
                        text: model.following ? qsTr("Unfollow") : qsTr("Follow")
                        visible: model.friendshipstatus_loaded
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: friendshipsModel.loadData(true)
}

