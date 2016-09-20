import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

import "../common"
import "../js/Utils.js" as Utils

BaseView {
    id: root
    isLoading: discoverModel.isLoading

    function scrollToTop() {
        gridView.scrollToTop()
    }

    function init() {
        console.log("init...")
        discoverModel.loadData(true)
    }

    property int currentIndex: -1
    onCurrentIndexChanged: loadMore();

    function loadMore() {
        // make sure currentIndex is up-to-date...
        gridView.updateCurrentIndex()

        if (!discoverModel.canLoadMore || root.isLoading || gridView.quickScrollAnimating)
            return;

        if (discoverModel.count - (currentIndex+1) <= 2 * gridView.itemsPerRow || (currentIndex == -1 && discoverModel.count > 0)) {
            console.log("!!! load moar !!!", currentIndex, (discoverModel.count-1))
            discoverModel.loadData(false)
        }
    }

    InstagramModel {
        id: discoverModel
        query: "$.items.*.media"

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
            isLoading = true;

            var nextID = canLoadMore && !clear ? nextMaxID : "";

            InstagramClient.discover(nextID, function(result) {
                // ensure every item has a video_versions property so the ListModel knows it.
                // otherwise this property is not accessable from the delegate :/
//                for (var o in result.items)
//                    if (!result.items[o].media.hasOwnProperty("video_versions"))
//                        result.items[o].media.video_versions = [];

                updateJSONModel(result, clear)
                gridView.forceLayout()

                if (result.more_available)
                    discoverModel.nextMaxID = result.next_max_id;
                else
                    discoverModel.nextMaxID = "";

                isLoading = false;

                // check again in case the list is not full
                loadMore();
            })
        }
    }

//    Item {
//        id: searchWrapper

//        property bool searchIsActive: false
//        property Item currentView: searchIsActive ? listView : gridView

//        width: parent.width
//        height: searchField.height

//        y: currentView.headerItem.y
//        parent: currentView.contentItem

//        FocusScope {
//            width: parent.width

//            SearchField {
//                id: searchField
//                focus: false
//                width: parent.width

//                placeholderText: qsTr("Search")

//                onTextChanged: updateSearchIsActive()
//                onActiveFocusChanged: updateSearchIsActive()
//                onFocusChanged: updateSearchIsActive()

//                function updateSearchIsActive() {
//                    console.log(text.length, activeFocus, focus)
//                    searchWrapper.searchIsActive = text.length > 0 || activeFocus || focus
//                }
//            }

//            MouseArea {
//                enabled: !searchWrapper.searchIsActive
//                anchors.fill: searchField

//                onClicked: {
//                    console.log("clicked")
//                    searchWrapper.searchIsActive = true
//                    searchField.forceActiveFocus()
//                }
//            }
//        }


//    }

    Item {
        id: searchWrapper
        readonly property bool searchIsActive: searchField.text.length > 0 || searchField.activeFocus

        height: searchField.height
        width: parent.width

        parent: gridView.contentItem
        y: gridView.headerItem.y

        SearchField {
            id: searchField
            width: parent.width
            placeholderText: qsTr("Search")
        }

        MouseArea {
            anchors.fill: searchField
            onClicked: pageStack.push("../pages/SearchPage.qml", null, PageStackAction.Immediate)
        }
    }



    SilicaGridView {
        id: gridView
        currentIndex: -1

        readonly property int itemsPerRow: {
            return (Screen.sizeCategory + 2) * (orientation & Orientation.PortraitMask ? 1 : 2);
        }

        anchors.fill: parent

        cellWidth: searchWrapper.searchIsActive ? width : width / itemsPerRow
        cellHeight: searchWrapper.searchIsActive ? Theme.itemSizeMedium : cellWidth

        model: discoverModel.model //!searchWrapper.searchIsActive ? discoverModel.model : null
        clip: true

        function updateCurrentIndex() {
            var idx = indexAt(itemsPerRow * cellWidth - (cellWidth / 2), contentY + height - (cellHeight / 2))

            if (idx >= 0)
                root.currentIndex = idx
        }

        onContentYChanged: updateCurrentIndex()
        onQuickScrollAnimatingChanged: root.loadMore();

        PullDownMenu {
            MenuItem {
                text: qsTr("Refresh")
                onClicked: discoverModel.loadData(true)
            }
        }

        // Placeholder for searchField
        header: Item {
            width: gridView.width
            height: searchWrapper.height
        }

        footer: LoadingMoreIndicator {
            visible: gridView.count > 0 && discoverModel.canLoadMore
        }

        delegate: Item {
            id: wrapper

            Loader {
                sourceComponent: searchWrapper.searchIsActive ? searchResultDelegateComponent : discoverDelegateComponent
            }

            Component {
                id: discoverDelegateComponent

                Item {
                    id: discoverDelegate

                    width: gridView.width / gridView.itemsPerRow
                    height: width

                    readonly property var bestMatch: Utils.getBestMatch(model.image_versions2.candidates, width, height, true)

                    Image {
                        id: img

                        anchors {
                            fill: parent
                            margins: Theme.paddingMedium / 8
                        }

                        source: discoverDelegate.bestMatch.url

                        sourceSize {
                            width: width
                            height: height
                        }

                        opacity: img.status === Image.Ready ? 1 : 0

                        Behavior on opacity {
                            FadeAnimator {}
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            pageStack.push("../pages/PostStreamPage.qml", {
                                               model: discoverModel,
                                               positionViewAtIndex: model.index
                                           })
                        }
                    }
                }
            }

            Component {
                id: searchResultDelegateComponent

                Item {
                    id: searchResultDelegate

                    width: gridView.width // gridView.itemsPerRow
                    height: Theme.itemSizeMedium

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Test"
                    }
                }
            }
        }



        VerticalScrollDecorator {}

        //opacity: gridView.count > 0 ? 1 : 0
        //Behavior on opacity { FadeAnimator {}}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: isLoading && gridView.count == 0
    }
}
