import QtQuick 2.0

JSONListModel {
    readonly property bool canLoadMore: nextMaxID !== ""
    property string nextMaxID: ""
    property bool isLoading: false

    function loadData(clear) {}
}

