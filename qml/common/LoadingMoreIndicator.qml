import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    width: parent ? parent.width : 0
    height: visible ? Theme.itemSizeMedium : 0

    BusyIndicator {
        anchors.centerIn: parent
        running: parent.visible
        size: BusyIndicatorSize.Medium
    }
}
