import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property real lat: 0
    property real lon: 0
    property string marker: "pin-l"
    property string mapID: "mapbox.dark"
    property string accessToken: "pk.eyJ1IjoiZWpqb21hbiIsImEiOiJjaXJtZDhpd2MwMDNvaHhrd2FtMHZzODkzIn0.uTM0Kz_5R4K0-T2rcY3M3A"
    property int zoom: 15

    Image {
        id: mapImage
        anchors.fill: parent
        source: "https://api.mapbox.com/v4/%1/%2%3,%4,%5/%6x%7.png?access_token=%8".arg(mapID).arg(marker ? marker + "(%3,%4)/" : "").arg(lon).arg(lat).arg(zoom).arg(width).arg(height).arg(accessToken)

        opacity: mapImage.status === Image.Ready ? 1 : 0

        Behavior on opacity {
            FadeAnimator {}
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: mapImage.status !== Image.Ready
        visible: running
        size: BusyIndicatorSize.Medium
    }


}
