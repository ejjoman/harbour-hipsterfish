import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0
import "../common"

Page {
    id: root

    property InstagramModel model
    property int positionViewAtIndex: -1

    PostStreamView {
        id: listView
        anchors.fill: parent
        model: root.model

        //onMoreDataRequested: root.update(false)
        //onRefreshRequested: refresh()
    }

    Component.onCompleted: {
        if (positionViewAtIndex >= 0)
            listView.listView.positionViewAtIndex(positionViewAtIndex, ListView.Beginning)
    }

}
