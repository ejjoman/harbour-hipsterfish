import QtQuick 2.2
import QtQuick.Window 2.1
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0
import "../common"
import "../delegates"
import "../views"

Page {
    id: page

    SlideshowView {
        id: mainView
        itemWidth: width
        itemHeight: height
        clip: true
        cacheItemCount: count

        onCurrentIndexChanged: console.log(currentIndex)

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: tabBar.visible ? tabBar.top : parent.bottom
        }

        model: VisualItemModel {
            TimelineView {
                id: timelineView
                view: mainView
                index: VisualItemModel.index
            }

            SearchView {
                id: searchView
                view: mainView
                index: VisualItemModel.index
            }

            NotificationsView {
                id: notificationsView
                view: mainView
                index: VisualItemModel.index
            }

            MeView {
                id: meView
                view: mainView
                index: VisualItemModel.index
            }
        }
    }

    Item {
        id: tabBar

        property var tabs: [
            {
                key: 'timeline',
                icon: 'image://theme/icon-m-clock',
                tab: timelineView
            },
            {
                key: 'search',
                icon: 'image://theme/icon-m-search',
                tab: searchView
            },
            {
                key: 'notifications',
                icon: 'image://theme/icon-m-favorite',
                tab: notificationsView
            },
            {
                key: 'me',
                icon: 'image://theme/icon-m-person',
                tab: meView
            }
        ]

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        height: Theme.itemSizeSmall

        PanelBackground {
            z: -1

            anchors.centerIn: parent
            transformOrigin: Item.Center
            width: parent.width
            height: parent.height
        }

        Image {
            id: background
            fillMode: Image.PreserveAspectCrop
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignTop
            anchors.fill: parent
            source: "image://theme/graphic-gradient-edge?" + Theme.highlightColor
        }

        Row {
            Repeater {
                id: sectionRepeater
                model: tabBar.tabs

                delegate: BackgroundItem {
                    id: tabDelegate

                    property BaseView view: modelData.tab ? modelData.tab : null
                    property bool isCurrentView: view && view.isCurrent
                    property bool __init: true;

                    onIsCurrentViewChanged: {
                        if (__init) {
                            __init = false;
                            tabDelegate.view.init()
                        }
                    }

                    width: tabBar.width / sectionRepeater.count
                    height: tabBar.height

                    Image {
                        id: icon
                        height: Theme.iconSizeMedium
                        width: Theme.iconSizeMedium
                        anchors.centerIn: parent
                        source: modelData.icon + (tabDelegate.isCurrentView ? '?' + Theme.highlightColor : '')
                    }

                    onClicked: {
                        if (tabDelegate.isCurrentView)
                            tabDelegate.view.scrollToTop();
                        else
                            mainView.currentIndex = view.index;
                    }
                }
            }
        }
    }

//    Connections {
//        target: Qt.inputMethod
//        onVisibleChanged: tabBar.visible = !Qt.inputMethod.visible
//    }
}





