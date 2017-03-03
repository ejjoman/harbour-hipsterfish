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

    property alias viewPlaceholder: viewPlaceholder
    property alias header: view.header
    property alias footer: view.footer

    function _loadMore() {
        if (!model.canLoadMore || model.isLoading || view.quickScrollAnimating)
            return;

        if (model.count - (currentIndex+1) < 12 ) {
            console.log("!!! load moar !!!", currentIndex, (view.count-1))
            model.loadData(false)
        }
    }

    SilicaGridView {
        id: view

        anchors.fill: parent

        /*
        readonly property int itemsPerRow: {
            return (Screen.sizeCategory + 2) * (orientation & Orientation.PortraitMask ? 1 : 2);
        }
          */
        readonly property int itemsPerRow: mode === "grid" ? 3 : 1
        property int _currentIndex: 0

        currentIndex: 0

        cellWidth: mode === "grid" ? width / itemsPerRow : width
        cellHeight: mode === "grid" ? cellWidth : undefined //searchWrapper.searchIsActive ? Theme.itemSizeMedium : cellWidth
        quickScroll: false

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

                    readonly property bool isVideo: model.video_versions.count > 0
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

                    Image {
                        id: videoIndicator
                        visible: discoverDelegate.isVideo

                        anchors {
                            right: parent.right
                            rightMargin: Theme.paddingMedium
                            bottom: parent.bottom
                            bottomMargin: Theme.paddingMedium
                        }

                        source: "image://theme/icon-m-file-video"
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

        footer: LoadingMoreIndicator {
            visible: model.count > 0 && model.canLoadMore
        }

        ViewPlaceholder {
            id: viewPlaceholder
            enabled: view.count == 0 && !model.isLoading
            text: qsTr("No posts")
            verticalOffset: view.headerItem.height/2 - height/2
        }

        VerticalScrollDecorator {}

        BusyIndicator {
            running: model.count == 0 && model.isLoading
            anchors {
                centerIn: parent
                verticalCenterOffset: view.header ? view.headerItem.height / 2 : 0
            }

            size: BusyIndicatorSize.Large
        }
    }
}
