import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Utils 1.0

Label {
    id: root

    linkColor: Theme.highlightColor
    textFormat: Text.StyledText

    onLinkActivated: {
        if (link.indexOf("user?") === 0) {
            var username = link.replace("user?username=", "")
            pageStack.push(Qt.resolvedUrl("../pages/UserProfilePage.qml"), {"username": username})
        } else if(link.indexOf("hashtag?") === 0) {
            var tag = link.replace("hashtag?tag=", "")
            pageStack.push(Qt.resolvedUrl("../pages/HashtagPage.qml"), {"hashtag": tag})
        } else {
            Qt.openUrlExternally(link)
        }
    }

    Component.onCompleted: {
        // we use QString::replace here, because QRegularExpression has a better detection of word-characters (umlauts / non-latin charset) compared to built-in js-regex engine...
        var tmp = StringUtils.replace(text, "@([\\w.]+[\\w])", "<a href='user?username=\\1'>@\\1</a>")
        tmp = StringUtils.replace(tmp, "#([\\w.]+[\\w])", "<a href='hashtag?tag=\\1'>#\\1</a>")

        text = tmp
    }
}

