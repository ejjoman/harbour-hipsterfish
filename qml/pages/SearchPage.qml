import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

import "../common"
import "../delegates"

import "../js/Utils.js" as Utils

Page {
    readonly property string _rankToken: InstagramClient.currentAccount.userID.toString() + "_" + InstagramClient.createCleanedUuid()

    readonly property var currentModelItem: getModelItem(tabBar.selectedCategory)

    function getModelItem(category) {
        for(var i in models)
            if (models[i].key === category)
                return models[i];

        return null;
    }

    onCurrentModelItemChanged: console.debug(currentModelItem.model.query)

    property var models: [
        {
            key: InstagramClient.TopSearch,
            loaded: false,
            model: topModel
        },
        {
            key: InstagramClient.UsersSearch,
            loaded: false,
            model: usersModel
        },
        {
            key: InstagramClient.TagsSearch,
            loaded: false,
            model: tagsModel
        },
        {
            key: InstagramClient.PlacesSearch,
            loaded: false,
            model: placesModel
        }
    ]

    JSONListModel {
        id: topModel
        query: "$.[hashtags,users,places].*"

        attachedProperties: ({
            "user": {},
            "place": {},
            "hashtag": {}
        })

        sortFuntion: function(a, b) {
            return a.position - b.position;
        }
    }

    JSONListModel {
        id: usersModel
        query: "$.users.*"
    }

    JSONListModel {
        id: tagsModel
        query: "$.results.*"
    }

    JSONListModel {
        id: placesModel
        query: "$.items.*"
    }

    function executeSearch() {
        if (searchField.text.length == 0)
            return;

        var current = getModelItem(tabBar.selectedCategory)

        console.debug(current.loaded)

        if (current.loaded === true)
            return;



        InstagramClient.search(tabBar.selectedCategory, searchField.text, 50, _rankToken, function(result) {
            console.log(JSON.stringify(result, null, 4))

            if (result.status === "ok") {
                current.loaded = true;
                current.model.updateJSONModel(result, true)
            }
        });
    }

    Item {
        id: tabBar

        property var tabs: [
            {
                category: InstagramClient.TopSearch,
                icon: 'image://theme/icon-m-levels'
            },
            {
                category: InstagramClient.UsersSearch,
                icon: 'image://theme/icon-m-person'
            },
            {
                category: InstagramClient.TagsSearch,
                iconText: "#"
            },
            {
                category: InstagramClient.PlacesSearch,
                icon: 'image://theme/icon-m-location'
            }
        ]

        property int selectedCategory: InstagramClient.TopSearch
        onSelectedCategoryChanged: executeSearch()

//        anchors {
//            top: parent.top
//            left: parent.left
//            right: parent.right
//        }

        parent: listView.contentItem
        y: listView.headerItem.y

        width: parent.width
        height: col.childrenRect.height //Theme.itemSizeSmall

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

        Column {
            id: col

            anchors {
                left: parent.left
                right: parent.right
                //top: parent.top
            }

            SearchField {
                id: searchField

                anchors {
                    left: parent.left
                    right: parent.right
                    //top: parent.top
                }

                onTextChanged: {
                    models.forEach(function(current) {
                        current.loaded = false;
                        current.model.clear()
                    })

                    executeSearch()
                }
            }

            Row {
                anchors {
                    left: parent.left
                    right: parent.right
                    //top: parent.top
                }
                //anchors.top: searchField.bottom

                Repeater {
                    id: sectionRepeater
                    model: tabBar.tabs

                    delegate: BackgroundItem {
                        id: tabDelegate

                        property bool isSelected: tabBar.selectedCategory === modelData.category


                        width: tabBar.width / sectionRepeater.count
                        height: Theme.itemSizeSmall

                        Image {
                            id: icon
                            height: Theme.iconSizeMedium
                            width: Theme.iconSizeMedium
                            anchors.centerIn: parent
                            source: modelData.icon ? modelData.icon + (tabDelegate.isSelected ? '?' + Theme.highlightColor : '') : ""
                            visible: source != ""
                        }

                        Label {
                            text: modelData.iconText ? modelData.iconText : ""
                            visible: !icon.visible
                            anchors.centerIn: parent
                            color: tabDelegate.isSelected ? Theme.highlightColor : Theme.primaryColor
                            font {
                                pixelSize: Theme.iconSizeMedium
                                italic: true
                            }
                        }

                        onClicked: tabBar.selectedCategory = modelData.category
                    }
                }
            }
        }
    }

    SilicaListView {
        id: listView

        anchors.fill: parent

        currentIndex: -1
        clip: true
        model: currentModelItem.model.model
        spacing: Theme.paddingSmall

        header: Item {
            width: listView.width
            height: tabBar.height
        }

        delegate: Item {
            id: delegateWrapper

            readonly property string resultType: {

                if (currentModelItem.key === InstagramClient.UsersSearch || (currentModelItem.key === InstagramClient.TopSearch && Object.keys(model.user).length > 0))
                    return "user";

                if (currentModelItem.key === InstagramClient.TagsSearch || (currentModelItem.key === InstagramClient.TopSearch && Object.keys(model.hashtag).length > 0))
                    return "hashtag";

                if (currentModelItem.key === InstagramClient.PlacesSearch || (currentModelItem.key === InstagramClient.TopSearch && Object.keys(model.place).length > 0))
                    return "place";

                return undefined;
            }

            height: loader.height
            width: parent.width

            Loader {
                id: loader
                width: parent.width
                sourceComponent: {
                    switch (delegateWrapper.resultType) {
                    case "user":
                        return userDelegate;

                    case "hashtag":
                        return hashtagDelegate;

                    case "place":
                        return placeDelegate;
                    }

                    return null;
                }
            }

            Component {
                id: userDelegate

                UserListItem {
                    modelData: currentModelItem.key === InstagramClient.UsersSearch ? model : model.user
                }
            }

            Component {
                id: hashtagDelegate

                ListItem {
                    id: listItem
                    property var modelData: currentModelItem.key === InstagramClient.TagsSearch ? model : model.hashtag

                    contentHeight: row.height

                    Row {
                        id: row
                        height: background.height + Theme.paddingMedium * 2

                        anchors {
                            //fill: parent
                            left: parent.left
                            right: parent.right
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin

                            verticalCenter: parent.verticalCenter
                        }

                        spacing: Theme.paddingMedium

                        Item {
                            id: iconWrapper

                            anchors.verticalCenter: parent.verticalCenter

                            width: Theme.itemSizeExtraSmall
                            height: Theme.itemSizeExtraSmall

                            Rectangle {
                                id: background
                                radius: width / 2

                                anchors.fill: parent

                                color: "#FFF"
                                opacity: .2
                            }

                            Label {
                                text: "#"

                                anchors.centerIn: background
                                color: Theme.primaryColor //listItem.down ? Theme.highlightColor : Theme.primaryColor
                                font {
                                    pixelSize: Theme.iconSizeMedium - Theme.paddingMedium
                                    //italic: true
                                }
                            }
                        }



                        Column {
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                text: modelData.name
                            }

                            Label {
                                text: qsTr("%Ln post(s)", "", modelData.media_count)
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                            }
                        }
                    }

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("../pages/HashtagPage.qml"), {"hashtag": modelData.name})
                    }
                }
            }

            Component {
                id: placeDelegate

                ListItem {
                    id: listItem
                    property var modelData: currentModelItem.key === InstagramClient.PlacesSearch ? model : model.place

                    contentHeight: row.height

                    Row {
                        id: row
                        height: icon.height + Theme.paddingMedium * 2

                        anchors {
                            //fill: parent
                            left: parent.left
                            right: parent.right
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin

                            verticalCenter: parent.verticalCenter
                        }

                        spacing: Theme.paddingMedium

                        Item {
                            id: iconWrapper

                            anchors.verticalCenter: parent.verticalCenter

                            width: Theme.itemSizeExtraSmall
                            height: Theme.itemSizeExtraSmall

                            Rectangle {
                                id: background
                                radius: width / 2

                                anchors.fill: parent

                                color: "#FFF"
                                opacity: .2
                            }

                            Image {
                                id: icon
                                source: "image://theme/icon-m-location"
                                anchors.centerIn: background
                            }
                        }



                        Column {
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                text: modelData.title
                            }

                            Label {
                                text: modelData.subtitle
                                visible: text.length > 0
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                            }
                        }
                    }

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("../pages/LocationPage.qml"), {
                                           "locationID": modelData.location.pk,
                                           "lat": modelData.location.lat,
                                           "lon": modelData.location.lng,
                                           "name": modelData.location.name,
                                           "city": modelData.location.city
                                       })
                    }
                }
            }
        }
    }

    property bool _isFirstActivation: true
    onStatusChanged: {
        if (status === PageStatus.Active && _isFirstActivation) {
            _isFirstActivation = false;
            searchField.forceActiveFocus()
        }
    }

    //Component.onCompleted: searchField.forceActiveFocus()
}
