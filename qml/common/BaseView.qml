import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    //anchors.fill: parent

    property SlideshowView view: null

    width: view.width
    height: view.height

    property int index

    property bool isLoading: false
    property bool isCurrent: PathView.isCurrentItem

    function scrollToTop() {}
    function init() {}
}

