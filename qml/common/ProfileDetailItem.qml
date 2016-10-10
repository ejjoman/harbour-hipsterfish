import QtQuick 2.1
import QtQuick.Layouts 1.1
import Sailfish.Silica 1.0
import "../js/Utils.js" as Utils

MouseArea {
    id: postsDetailItem
    clip: true

    property int value: 0
    property alias label: label.text
    property bool abbreviate: false

    height: wrapper.childrenRect.height

    Column {
        id: wrapper
        clip: true
        width: parent.width
        spacing: 0

        Label {
            id: valueLabel
            font.pixelSize: Theme.fontSizeExtraLarge
            anchors {
                left: parent.left
                right: parent.right
            }

            horizontalAlignment: Qt.AlignHCenter

            text: abbreviate ? Utils.abbreviateNumber(value, 0) : value.toLocaleString()
        }

        Label {
            id: label
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeTiny

            anchors {
                left: parent.left
                right: parent.right
            }

            horizontalAlignment: width > 0 && contentWidth > Math.ceil(width) ? Qt.AlignLeft : Qt.AlignHCenter
            truncationMode: TruncationMode.Fade
        }
    }
}

