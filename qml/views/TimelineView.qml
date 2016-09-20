import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.hipsterfish.Instagram 1.0

import "../common"
import "../delegates"

BaseView {
    id: root
    isLoading: timeline.isLoading

    function scrollToTop() {
        streamView.listView.scrollToTop()
    }

    function init() {
        console.log("init...")
        timeline.loadData(true)
    }

    InstagramModel {
        id: timeline
        query: "$.items.*"

        attachedProperties: ({
            "id": null,
            "has_liked": false,
            "video_versions": [],
            "caption": {
                "user": {
                    "profile_pic_url": "",
                    "username": ""
                },
                "text": "",
                "created_at": 0
            },
            "location": {
                "name": ""
            },
            "image_versions2": [],
            "view_count": 0,
            "like_count": 0,
            "user": {
                "profile_pic_url": "",
                "username": ""
            },
            "text": "",
            "comments": []
        })


        function loadData(clear) {
            isLoading = true

            var nextID = canLoadMore && !clear ? nextMaxID : "";

            InstagramClient.updateTimeline(nextID, function(result) {
                // ensure every item has a video_versions property so the ListModel knows it.
                // otherwise this property is not accessable from the delegate :/
//                for (var o in result.items)
//                    if (!result.items[o].hasOwnProperty("video_versions"))
//                        result.items[o].video_versions = [];

                updateJSONModel(result, clear)

                //console.log(JSON.stringify(result, null, 4))

                if (result.more_available)
                    nextMaxID = result.next_max_id;
                else
                    nextMaxID = "";

                isLoading = false;
            })
        }
    }

    PostStreamView {
        id: streamView
        anchors.fill: parent
        model: timeline
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: isLoading && timeline.count == 0
    }
}
