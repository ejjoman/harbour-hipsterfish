import QtQuick 2.0
import Sailfish.Silica 1.0

MouseArea {
    id: root

    property alias label: label.text
    property alias labelVisible: label.visible

    property alias iconSource: icon.source
    property bool hightlight: false

    width: Math.max(implicitWidth, Theme.buttonWidthSmall)
    height: Theme.itemSizeSmall * .5 + Theme.paddingSmall

    //width: showSuggestedButton ? parent.width - suggestedButtonMouseArea.width : implicitWidth

    readonly property int _maxWidth: width - 2*Theme.paddingSmall

    Rectangle {
        anchors.fill: parent

        border.color: {
            if (root.pressed)
                return Theme.highlightColor

            return hightlight ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity) : Theme.primaryColor
        }

        border.width: Theme.paddingSmall / 4

        radius: Theme.paddingSmall
        color: hightlight ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity) : "transparent"

        Row {
            id: row
            width: Math.min(implicitWidth, _maxWidth)
            anchors.centerIn: parent

            spacing: Theme.paddingSmall

            Image {
                id: icon
                visible: source !== null
            }

            Label {
                id: label

                font.pixelSize: Theme.fontSizeExtraSmall
                color: root.pressed ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
                width: Math.min(contentWidth, _maxWidth - icon.width - row.spacing)
            }
        }
    }
}
