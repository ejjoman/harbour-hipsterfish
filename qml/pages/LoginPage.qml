import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

Page {
    id: page

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Login to Instagram")
            }

            TextField {
                id: username
                width: parent.width
                placeholderText: qsTr("Username")
                label: placeholderText
                inputMethodHints: Qt.ImhNoAutoUppercase
            }

            PasswordField {
                id: password
                width: parent.width
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Login")
                onClicked: InstagramClient.login(username.text, password.text)
            }
        }
    }
}


