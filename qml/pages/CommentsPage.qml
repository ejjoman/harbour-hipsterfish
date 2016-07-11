import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0
import "../common"

Page {
    id: root
    property string mediaID;
    property bool isLoading: false;

    JSONListModel {
        id: comments
        query: "$.comments.*"

        readonly property bool canLoadMore: nextMaxID !== ""
        property string nextMaxID: ""
    }

    function loadComments(clear) {
        root.isLoading = true;

        var nextID = comments.canLoadMore && !clear ? comments.nextMaxID : "";

        InstagramClient.loadCommentsForMedia(mediaID, nextID, function(result) {
            console.log(JSON.stringify(result, null, 4))

            // reverse comments, because we use bottom-to-top direction in commentsView
            result.comments.sort(function(a, b) {
                return b.created_at - a.created_at
            });

            comments.updateJSONModel(result);

            if (result.has_more_comments)
                comments.nextMaxID = result.next_max_id;
            else
                comments.nextMaxID = "";

            root.isLoading = false;
        })
    }

    property int currentIndex: 0
    onCurrentIndexChanged: loadMore();

    function loadMore() {
        if (!comments.canLoadMore || root.isLoading || commentsView.quickScrollAnimating)
            return;

        if (comments.count - (currentIndex+1) <= 2 ) {
            console.log("!!! load moar !!!", currentIndex, (comments.count-1))
            loadComments(false)
        }
    }

    SilicaListView {
        id: commentsView

        verticalLayoutDirection: ListView.BottomToTop
        anchors.fill: parent
        model: comments.model
        spacing: Theme.paddingLarge

        onContentYChanged: {
            var idx = indexAt(0, contentY) // + height)

            if (idx >= 0)
                root.currentIndex = idx
        }

        onQuickScrollAnimatingChanged: root.loadMore();

        delegate: Item {
            height: childrenRect.height

            anchors {
                left: parent.left
                right: parent.right
            }

            Row {
                id: row

                anchors {
                    left: parent.left
                    right: parent.right

                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }

                spacing: Theme.paddingMedium

                ProfilePicture {
                    id: profilePicture

                    source: model.user.profile_pic_url

                    width: Theme.itemSizeExtraSmall
                    height: Theme.itemSizeExtraSmall
                }

                Column {
                    id: column

                    width: parent.width - parent.spacing - profilePicture.width
                    spacing: Theme.paddingSmall

                    Label {
                        id: commentLabel
                        width: parent.width
                        font.pixelSize: Theme.fontSizeSmall
                        text: "<b>" + model.user.username + "</b> " + model.text
                        wrapMode: Text.Wrap
                    }

                    Label {
                        id: timestampLabel
                        text: Format.formatDate(new Date(model.created_at * 1000), Formatter.DurationElapsed)
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: loadComments(true)
}

