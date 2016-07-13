import QtQuick 2.0
import Sailfish.Silica 1.0

InverseMouseArea {
    property alias text: editor.text
    property int horizontalMargin: Theme.horizontalPageMargin
    readonly property bool hasFocus: editor.focus

    property bool isSending: false

    signal sendCommentClicked

    function forceActiveFocus() {
        editor.forceActiveFocus()
        editor.cursorPosition = editor.text.length
    }

    function clear() {
        editor.text = ""
    }

    function _send() {
        if (text.trim() === "" || isSending)
            return;

        editor.focus = false

        Qt.inputMethod.commit()
        sendCommentClicked()
    }

    width: parent ? parent.width : 0
    height: editor.height + 2*Theme.paddingLarge

    onClickedOutside: editor.focus = false

    TextArea {
        id: editor

        anchors {
            left: parent.left
            right: sendButtonWrapper.left
            bottom: parent.bottom
            bottomMargin: Theme.paddingMedium
        }

        enabled: !isSending

        focusOutBehavior: FocusBehavior.KeepFocus
        textLeftMargin: horizontalMargin
        textRightMargin: 0
        font.pixelSize: Theme.fontSizeSmall
        //: Placeholder text for the comment field
        //% "Your comment"
        placeholderText: qsTr("Write a comment...")
        labelVisible: false

        EnterKey.highlighted: true
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"

        EnterKey.enabled: text.trim().length > 0 || inputMethodComposing
        EnterKey.onClicked: _send()

        onTextChanged: text = text.replace("\n", "")
    }

    Item {
        id: sendButtonWrapper
        anchors {
            right: parent.right
            rightMargin: horizontalMargin
            verticalCenter: editor.top
            verticalCenterOffset: editor.textVerticalCenterOffset + (editor._editor.height - height)
        }

        width: sendButtonText.width
        height: sendButtonText.height

        BusyIndicator {
            running: isSending
            size: BusyIndicatorSize.Small

            anchors.centerIn: parent
        }

        Label {
            id: sendButtonText
            anchors.centerIn: parent
//            anchors {
//                right: parent.right
//                rightMargin: horizontalMargin
//                verticalCenter: editor.top
//                verticalCenterOffset: editor.textVerticalCenterOffset + (editor._editor.height - height)
//            }

            font.pixelSize: Theme.fontSizeSmall
            color: !sendButtonArea.enabled
                   ? Theme.secondaryColor
                   : sendButtonArea.pressed
                      ? Theme.highlightColor
                      : Theme.primaryColor

            opacity: !isLoading && (editor.activeFocus || sendButtonArea.enabled) ? 1.0 : 0.0

            text: qsTrId("Send")

            Behavior on opacity { FadeAnimation {} }
        }

        MouseArea {
            id: sendButtonArea
            anchors {
                fill: sendButtonText
                margins: -Theme.paddingLarge
            }
            enabled: !isSending && editor.text.length > 0
            onClicked: _send()
        }
    }


}
