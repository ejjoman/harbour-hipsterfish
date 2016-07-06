import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

import "../common"
import "../delegates"

BaseView {
    id: root

    function scrollToTop() {
        listView.scrollToTop()
    }

    function init() {
        console.log("init...")
        refresh()
    }

    function refresh() {
        update(true)
    }

    function update(clear) {
        root.isLoading = true;

        var nextID = timeline.canLoadMore && !clear ? timeline.nextMaxID : "";

        InstagramClient.updateTimeline(nextID, function(result) {
            //timeline.json = result;
            timeline.updateJSONModel(result, clear)

            console.log(JSON.stringify(result, null, 4))

            if (result.more_available)
                timeline.nextMaxID = result.next_max_id;
            else
                timeline.nextMaxID = "";

            root.isLoading = false;
        })
    }

    property int currentIndex: 0
    onCurrentIndexChanged: loadMore();

    function loadMore() {
        if (!timeline.canLoadMore || root.isLoading || listView.quickScrollAnimating)
            return;

        if (timeline.count - (currentIndex+1) <= 2 ) {
            console.log("!!! load moar !!!", currentIndex, (timeline.count-1))
            update(false)
        }
    }

    JSONListModel {
        id: timeline
        query: "$.items.*"

        readonly property bool canLoadMore: nextMaxID !== ""
        property string nextMaxID: ""
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        spacing: Theme.paddingLarge * 2

        model: timeline.model
        //quickScrollEnabled: false

        onContentYChanged: {
            var idx = indexAt(0, contentY + height)

            if (idx >= 0)
                root.currentIndex = idx
        }

        onQuickScrollAnimatingChanged: root.loadMore();

        PullDownMenu {
            MenuItem {
                text: qsTr("Refresh")
                onClicked: root.refresh()
            }
        }

        header: Item {
            height: Theme.paddingSmall
            width: parent.width
        }

        delegate: PostDelegate {}

//        delegate: Label {
//            anchors.left: parent.left
//            anchors.right: parent.right

//            text: model.caption.text
//            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
//        }

        VerticalScrollDecorator {}
    }
}
