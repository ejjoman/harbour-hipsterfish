/* JSONListModel - a QML ListModel with JSON and JSONPath support
 *
 * Copyright (c) 2012 Romain Pokrzywka (KDAB) (romain@kdab.com)
 * Licensed under the MIT licence (http://opensource.org/licenses/mit-license.php)
 */

import QtQuick 2.0
import "../js/jsonpath.js" as JSONPath
import "../js/Utils.js" as Utils

Item {
    id: root
    //property variant json
    property string query: ""

    property ListModel model: ListModel { id: jsonModel; }
    property alias count: jsonModel.count

    property var attachedProperties
    property var sortFuntion: undefined

    //onJsonChanged: updateJSONModel(true)
    onQueryChanged: updateJSONModel(true)

    function clear() {
        jsonModel.clear()
    }

    function updateJSONModel(json, clearModel) {
        worker.sendMessage({
                               "clearModel" : clearModel,
                               "model": jsonModel,
                               "json": json,
                               "query": query,
                               "attachedProperties": attachedProperties,
                               "sortFuntion": sortFuntion
                           })
    }

    WorkerScript {
        id: worker
        source: "../js/JSONListModelWorker.js"
    }

//    function parseJSONString(jsonString, jsonPathQuery) {
//        var objectArray = JSON.parse(jsonString);
//        if ( jsonPathQuery !== "" )
//            objectArray = JSONPath.jsonPath(objectArray, jsonPathQuery);

//        return objectArray;
//    }
}
