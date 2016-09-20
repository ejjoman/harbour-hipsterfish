import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"
import "../delegates"

Item {
    id: root

    readonly property int currentIndex: listView._currentIndex
    property InstagramModel model

    property alias listView: listView

    function _loadMore() {
        if (!model.canLoadMore || model.isLoading || listView.quickScrollAnimating)
            return;

        if (model.count - (currentIndex+1) <= 2 ) {
            console.log("!!! load moar !!!", currentIndex, (listView.count-1))
            model.loadData(false)
        }
    }

    SilicaListView {
        id: listView

        property int _currentIndex: -1
        on_CurrentIndexChanged: _loadMore()
        onQuickScrollAnimatingChanged: _loadMore();

        anchors.fill: parent
        //spacing: Theme.paddingLarge * 2
        clip: true
        model: root.model ? root.model.model : null

        onContentYChanged: {
            var idx = indexAt(0, contentY + height)

            if (idx >= 0)
                _currentIndex = idx
        }

        header: Item {
            height: Theme.paddingSmall
            width: listView.width
        }

        footer: LoadingMoreIndicator {
            visible: model.isLoading && listView.count > 0
        }

        delegate: PostDelegate {}

        VerticalScrollDecorator {}

        opacity: listView.count > 0 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { FadeAnimator {}}

        PullDownMenu {
            MenuItem {
                text: qsTr("Refresh")
                onClicked: model.loadData(true)
            }
        }
    }


}


