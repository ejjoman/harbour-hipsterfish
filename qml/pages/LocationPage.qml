import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

import "../common"

import "../js/jsonpath.js" as JSONPath
import "../js/Utils.js" as Utils


Page {
    readonly property string _rankToken: InstagramClient.createCleanedUuid()

    property var locationID
    property alias lat: map.lat
    property alias lon: map.lon
    property alias name: placeHeader.title
    property alias city: placeHeader.description



    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: wrapperColumn.height

        function _loadMore() {
            if (!feedItemsModel.canLoadMore || feedItemsModel.isLoading || quickScrollAnimating)
                return;

            if (contentHeight - height - contentY > feedView.cellHeight * 2)
                return;

            feedItemsModel.loadData(false)
        }

        onContentYChanged: {
            if (contentHeight - height - contentY <= feedView.cellHeight * 2)
                _loadMore()
        }

        onQuickScrollAnimatingChanged: _loadMore();

        Column {
            id: wrapperColumn

            anchors {
                left: parent.left
                right: parent.right
            }

            spacing: Theme.paddingLarge

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                PageHeader {
                    id: placeHeader
                }

                StaticMap {
                    id: map
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    height: Theme.itemSizeLarge * 3
                }
            }

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                SectionHeader {
                    text: qsTr("Top Posts")
                }

                NonInteractiveGridView {
                    id: topView

                    model: topItemsModel.model
                    width: parent.width

                    flickable: flickable

                    itemsPerRow: 3
                    cellWidth: width / itemsPerRow
                    cellHeight: cellWidth

                    delegate: Item {
                        width: topView.width / topView.itemsPerRow
                        height: width

                        readonly property var bestMatch: Utils.getBestMatch(model.image_versions2.candidates, width, height, true)

                        Image {
                            anchors {
                                fill: parent
                                margins: Theme.paddingMedium / 8
                            }

                            source: parent.bestMatch.url

                            sourceSize {
                                width: width
                                height: height
                            }

                            opacity: status === Image.Ready ? 1 : 0

                            Behavior on opacity {
                                FadeAnimator {}
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                pageStack.push("../pages/PostStreamPage.qml", {
                                                   model: topItemsModel,
                                                   positionViewAtIndex: model.index
                                               })

                                //root.mode = root.mode == "grid" ? "list" : "grid"
                            }
                        }
                    }
                }
            }

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                SectionHeader {
                    text: qsTr("Most Recent")
                }

                NonInteractiveGridView {
                    id: feedView
                    model: feedItemsModel.model
                    width: parent.width

                    flickable: flickable

                    itemsPerRow: 3
                    cellWidth: width / itemsPerRow
                    cellHeight: cellWidth

                    delegate: Item {
                        width: feedView.width / feedView.itemsPerRow
                        height: width

                        readonly property var bestMatch: Utils.getBestMatch(model.image_versions2.candidates, width, height, true)

                        Image {
                            anchors {
                                fill: parent
                                margins: Theme.paddingMedium / 8
                            }

                            source: parent.bestMatch.url

                            sourceSize {
                                width: width
                                height: height
                            }

                            opacity: status === Image.Ready ? 1 : 0

                            Behavior on opacity {
                                FadeAnimator {}
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                pageStack.push("../pages/PostStreamPage.qml", {
                                                   model: feedItemsModel,
                                                   positionViewAtIndex: model.index
                                               })

                                //root.mode = root.mode == "grid" ? "list" : "grid"
                            }
                        }
                    }
                }
            }
        }
    }

    InstagramModel {
        id: topItemsModel
        query: "$.ranked_items.*"

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
    }

    InstagramModel {
        id: feedItemsModel
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

            InstagramClient.loadLocationFeed(locationID, nextID, _rankToken, function(result) {
                //console.log(JSON.stringify(result, null, 4))

                topItemsModel.updateJSONModel(result, clear)
                updateJSONModel(result, clear)

                if (result.more_available)
                    nextMaxID = result.next_max_id;
                else
                    nextMaxID = "";

                isLoading = false;
            });
        }
    }



//    Column {
//        id: headerComponent

//        parent: view.view.contentItem
//        y: view.view.headerItem.y

//        anchors {
//            left: parent.left
//            right: parent.right
//        }

//        PageHeader {
//            id: placeHeader
//        }

//        StaticMap {
//            id: map
//            anchors {
//                left: parent.left
//                right: parent.right
//            }

//            height: Theme.itemSizeLarge * 3
//        }
//    }

//    FeedView {
//        id: view
//        model: feedModel

//        anchors.fill: parent

//        view.header: Item {
//            width: view.width
//            height: headerComponent.height
//        }

//        view {

//        }
//    }

//    InstagramModel {
//        id: feedModel
//        //query: "$.items.*"

//        attachedProperties: ({
//            "id": null,
//            "has_liked": false,
//            "video_versions": [],
//            "caption": {
//                "user": {
//                    "profile_pic_url": "",
//                    "username": ""
//                },
//                "text": "",
//                "created_at": 0
//            },
//            "location": {
//                "name": ""
//            },
//            "image_versions2": [],
//            "view_count": 0,
//            "like_count": 0,
//            "user": {
//                "profile_pic_url": "",
//                "username": ""
//            },
//            "text": "",
//            "comments": []
//        })

//        function loadData(clear) {
//            isLoading = true

//            var nextID = canLoadMore && !clear ? nextMaxID : "";

//            InstagramClient.loadLocationFeed(locationID, nextID, _rankToken, function(result) {
//                //console.log(JSON.stringify(result, null, 4))

//                var items = [];

//                if (count == 0 || clear) {
//                    var rankedItems = JSONPath.jsonPath(result, "$.ranked_items.*")

//                    for (var r in rankedItems) {
//                        rankedItems[r]._category = "top"
//                        items.push(rankedItems[r]);
//                    }
//                }

//                var feedItems = JSONPath.jsonPath(result, "$.items.*")
//                for (var f in feedItems) {
//                    feedItems[f]._category = "recent"
//                    items.push(feedItems[f]);
//                }

//                updateJSONModel(feedItems, clear)

//                if (result.more_available)
//                    nextMaxID = result.next_max_id;
//                else
//                    nextMaxID = "";

//                isLoading = false;
//            });
//        }
//    }



    Component.onCompleted: feedItemsModel.loadData(true)
}
