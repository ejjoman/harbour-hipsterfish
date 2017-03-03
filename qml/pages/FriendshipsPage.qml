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
        // data gets filtered in load callback function...
        //query: "$.sections.*.users.*"

        attachedProperties: ({
            "username": null,
            "has_anonymous_profile_picture": false,
            "is_favorite": false,
            "has_chaining": false,
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

        //property var _ids: []

        function loadData(clear) {
            console.log();

            isLoading = true;

            var nextID = !clear && friendshipsModel.canLoadMore ? friendshipsModel.nextMaxID : "";

            InstagramClient.loadFriendships(friendshipType, userID, "overview", nextID, _rankToken, function(result) {
                if (result.status !== "ok") {
                    isLoading = false;
                    return;
                }

                if (result.big_list)
                    friendshipsModel.nextMaxID = result.next_max_id;
                else
                    friendshipsModel.nextMaxID = "";

                var modelData = JSONPath.jsonPath(result, "$.sections.*.users.*");
                var userIDs = [];
                var indexedUserIDs = [];

                for (var i=0; i<modelData.length; i++) {
                    var userID = modelData[i].pk

                    userIDs.push(userID);
                    indexedUserIDs[userID] = i;
                }

                InstagramClient.loadFriendshipStatus(userIDs, function(friendshipStatusResult) {
                    if (friendshipStatusResult.status !== "ok") {
                        isLoading = false;
                        return;
                    }

                    for (var statusUserID in friendshipStatusResult.friendship_statuses) {
                        var status = friendshipStatusResult.friendship_statuses[statusUserID];
                        var userIndex = indexedUserIDs[statusUserID];

                        modelData[userIndex].following = status.following;
                        modelData[userIndex].incoming_request = status.incoming_request;
                        modelData[userIndex].outgoing_request = status.outgoing_request;
                        modelData[userIndex].is_private = status.is_private;
                        modelData[userIndex].friendshipstatus_loaded = true;
                    }

                    friendshipsModel.updateJSONModel(modelData, clear);
                    isLoading = false;
                })
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
            visible: friendshipsModel.count > 0 && friendshipsModel.canLoadMore
        }

        delegate: UserListItem {
            modelData: model
            showFollowButton: true
        }

        VerticalScrollDecorator {}

        BusyIndicator {
            running: friendshipsModel.count == 0 && friendshipsModel.isLoading
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
        }
    }

    Component.onCompleted: friendshipsModel.loadData(true)
}

