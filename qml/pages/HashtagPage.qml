import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

import "../common"

import "../js/jsonpath.js" as JSONPath
import "../js/Utils.js" as Utils


Page {
    readonly property string _rankToken: InstagramClient.createCleanedUuid()

    property string hashtag
    property var visitedTags: []

    property int _postsCount: 0

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

            PageHeader {
                title: "#" + hashtag
            }

            Column {
                id: contentColumn

                anchors {
                    left: parent.left
                    right: parent.right
                }

                spacing: Theme.paddingLarge

                Column {
                    id: relatedTagsWrapper

                    opacity: visible ? 1 : 0
                    visible: relatedTagsModel.count > 0 ? 1 : 0
                    Behavior on opacity { FadeAnimator {}}

                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    SectionHeader {
                        text: qsTr("Related")
                    }

                    Flow {
                        anchors {
                            left: parent.left
                            right: parent.right

                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                        }

                        spacing: Theme.paddingLarge

                        Repeater {
                            model: relatedTagsModel.model

                            delegate: MouseArea {
                                id: relatedTagMouseArea

                                height: relatedTagLabel.height
                                width: relatedTagLabel.width

                                Label {
                                    id: relatedTagLabel

                                    //anchors.centerIn: parent
                                    text: "#" + model.name
                                    color: relatedTagMouseArea.pressed ? Theme.highlightColor : Theme.primaryColor
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                onClicked: {
                                    var visited = visitedTags;
                                    visited.splice(0, 0, hashtag);

                                    pageStack.push(Qt.resolvedUrl("HashtagPage.qml"), {"hashtag": model.name, "visitedTags": visited})
                                }
                            }
                        }
                    }
                }

                Column {
                    id: topPostsWrapper

                    opacity: visible ? 1 : 0
                    visible: topItemsModel.count > 0
                    Behavior on opacity { FadeAnimator {}}

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
                    id: feedWrapper

                    opacity: visible ? 1 : 0
                    visible: feedItemsModel.count > 0
                    Behavior on opacity { FadeAnimator {}}

                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    SectionHeader {
                        text: qsTr("Most Recent (%Ln post(s))", "", _postsCount)
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

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: feedItemsModel.isLoading && feedItemsModel.count == 0
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

        function init() {
            InstagramClient.loadTagInfos(hashtag, function(result) {
                if (result["status"] !== "ok")
                    return;

                _postsCount = result["media_count"]
            })

            InstagramClient.loadRelatedTags(hashtag, visitedTags, function(result) {
                if (result["status"] !== "ok")
                    return;

                relatedTagsModel.updateJSONModel(result, true);
            })

            loadData(true)
        }

        function loadData(clear) {
            _loadData(clear, 3)
        }

        function _loadData(clear, pagesToLoad) {
            isLoading = true

            var nextID = canLoadMore && !clear ? nextMaxID : "";

            InstagramClient.loadTagFeed(hashtag, nextID, _rankToken, function(result) {
                if (result["status"] !== "ok")
                    return;

                console.log(result["num_results"])

                topItemsModel.updateJSONModel(result, clear)
                updateJSONModel(result, clear)

                if (result.more_available)
                    nextMaxID = result.next_max_id;
                else
                    nextMaxID = "";

                if (nextMaxID != "" && pagesToLoad-1 > 0)
                    _loadData(false, pagesToLoad-1)
                else
                    isLoading = false;
            });
        }
    }

    InstagramModel {
        id: relatedTagsModel
        query: "$.related.*"

        attachedProperties: ({
            "type": null,
            "id": null,
            "name": null
        })
    }

    Component.onCompleted: feedItemsModel.init()
}
