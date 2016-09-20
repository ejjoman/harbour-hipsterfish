import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"
import "../delegates"
import "../js/Utils.js" as Utils

Item {
    id: root

    readonly property int currentIndex: view._currentIndex
    onCurrentIndexChanged: _loadMore();

    property InstagramModel model

    property alias view: view
    property string mode: "grid"

    function _loadMore() {
        if (!model.canLoadMore || model.isLoading || view.quickScrollAnimating)
            return;

        if (model.count - (currentIndex+1) <= 2 ) {
            console.log("!!! load moar !!!", currentIndex, (view.count-1))
            model.loadData(false)
        }
    }

    SilicaGridView {
        id: view

        anchors.fill: parent

        readonly property int itemsPerRow: mode === "grid" ? 3 : 1
        property int _currentIndex: 0

        currentIndex: 0

        cellWidth: mode === "grid" ? width / itemsPerRow : width
        cellHeight: mode === "grid" ? cellWidth : undefined //searchWrapper.searchIsActive ? Theme.itemSizeMedium : cellWidth

        model: root.model.model
        clip: true

        function updateCurrentIndex() {
            var idx = indexAt(itemsPerRow * cellWidth - (cellWidth / 2), contentY + height - (cellHeight / 2))

            if (idx >= 0)
                _currentIndex = idx
        }

        onContentYChanged: updateCurrentIndex()
        onQuickScrollAnimatingChanged: root._loadMore();

        delegate: Item {
            id: wrapper
            width: mode === "grid" ? view.width / view.itemsPerRow : view.width

            Loader {
                width: parent.width
                sourceComponent: mode === "grid" ? gridDelegate : listDelegate
            }

            Component {
                id: gridDelegate

                Item {
                    id: discoverDelegate

                    width: wrapper.width
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
                                               model: root.model,
                                               positionViewAtIndex: model.index
                                           })

                            //root.mode = root.mode == "grid" ? "list" : "grid"
                        }
                    }
                }
            }

            Component {
                id: listDelegate

                PostDelegate {}
            }
        }

        ViewPlaceholder {
            enabled: view.count == 0 && !model.isLoading
            text: qsTr("No posts")
            verticalOffset: view.headerItem.height/2 - height/2
        }

        ScrollDecorator {}
    }
}
