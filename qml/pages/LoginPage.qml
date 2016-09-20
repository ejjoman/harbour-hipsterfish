import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

Dialog {
    id: page

    property InstagramAccount account: null

    acceptDestination: Page {
        id: busyPage

        backNavigation: infoText != ""

        property string infoText: ""


        Column {
            anchors.centerIn: parent
            spacing: Theme.paddingLarge

            Label {
                width: busyPage.width - 2*Theme.horizontalPageMargin
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: Theme.highlightColor

                text: busyPage.infoText == "" ? "Please hold the line..." : busyPage.infoText
            }

            BusyIndicator {
                size: BusyIndicatorSize.Large
                anchors.horizontalCenter: parent.horizontalCenter
                running: busyPage.infoText == ""
            }
        }
    }

    canAccept: username.text.length > 0 && password.text.length > 0
    //acceptDestinationAction: PageStackAction.Replace

    onAccepted: {
        busyPage.infoText = ""

        InstagramClient.login(username.text, password.text, function(result, account) {
            console.debug(JSON.stringify(result, null, 4))
            console.debug(account);

            if (result["status"] === "ok" && account) {
                //InstagramClient.currentAccount = account;
                pageStack.replaceAbove(null, Qt.resolvedUrl("StartPage.qml"));
            } else {
                busyPage.infoText = result["message"]
            }
        })
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Login to Instagram")
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin

                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }

                //width: parent.width

                wrapMode: Text.WordWrap

                text: account ?
                          "Hi %1!<br/>Unfortunately, we need to re-login to Instagram. Maybe you changed your password or you weren't here for a long time?<br/><br/>Just provide me your current login details and I'll do the rest for you :)</p>".arg(account.userName)
                        : "Hi hipster!<br/>Welcome to Hipsterfish, the Instagram client for your beloved Sailfish OS!<br/><br/>Just provide me your login details, so I can serve you some cool content :)"

                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
            }

            TextField {
                id: username
                width: parent.width
                placeholderText: qsTr("Username")
                label: placeholderText
                inputMethodHints: Qt.ImhNoAutoUppercase

                text: account ? account.userName : ""
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

            Button {
                visible: !!account
                anchors.horizontalCenter: parent.horizontalCenter
                text: account ? qsTr("Not %1?").arg(account.userName) : ""
            }
        }
    }

    Component.onCompleted: {
        if (account)
            console.log("relogin...")
        else
            console.log("new login...")
    }
}


