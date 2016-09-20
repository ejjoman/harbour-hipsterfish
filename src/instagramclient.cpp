#include "instagramclient.h"
#include <QNetworkRequest>
#include <QNetworkInterface>
#include <QUuid>
#include <QMessageAuthenticationCode>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkCookie>
#include <QUrlQuery>
#include <QJSEngine>
#include <QNetworkProxy>
#include <limits.h>
#include <QTimeZone>
#include <QElapsedTimer>

#include "instagramaccountmanager.h"
#include "3rdparty/qt-json/json.h"

const QString InstagramClient::SETTINGS_PATH = QString("/apps/").append(APP_NAME).append("/");
InstagramClient *InstagramClient::_instance = 0;

InstagramClient::InstagramClient(QObject *parent)
    : QObject(parent),
      apiNetworkAccessManager(new QNetworkAccessManager(this)),
      loginNetworkAccessManager(new QNetworkAccessManager(this)),
      _currentAccount(NULL),
      callbacks(new QMap<QUuid, QJSValue>())
{
    connect(apiNetworkAccessManager, SIGNAL(finished(QNetworkReply*)), this, SLOT(apiRequestFinished(QNetworkReply*)));
    connect(loginNetworkAccessManager, SIGNAL(finished(QNetworkReply*)), this, SLOT(loginFinished(QNetworkReply*)));

    phoneIDConfItem = new MGConfItem(SETTINGS_PATH + "phoneID", this);
    guidConfItem = new MGConfItem(SETTINGS_PATH + "GUID", this);
    deviceIDConfItem = new MGConfItem(SETTINGS_PATH + "deviceID", this);

}

void InstagramClient::login(QString username, QString password, QJSValue callback)
{
    qDebug() << SETTINGS_PATH;
    qDebug() << phoneIDConfItem->key();

    QJsonObject json;
    json["phone_id"] = phoneID();
    //json["_csrftoken"] = createCleanedUuid().remove(QChar('-'));
    json["username"] = username;
    json["guid"] = guid();
    json["device_id"] = deviceID();
    json["password"] = password;
    json["login_attempt_count"] = 0;

    QByteArray body = this->getSignedBody(json);

    qDebug() << "Signed Body:" << body;


    auto key = QUuid::createUuid();

    if (!callback.isUndefined())
        callbacks->insert(key, callback);

    QNetworkRequest req(QUrl("https://i.instagram.com/api/v1/accounts/login/"));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded; charset=UTF-8");
    req.setAttribute(QNetworkRequest::User, key);

    this->setRequiredHeaders(req);

    loginNetworkAccessManager->setCookieJar(DConfCookieJar::createTemporaryCookieJar(this));
    loginNetworkAccessManager->post(req, body);
}

InstagramAccount *InstagramClient::currentAccount() const
{
    return _currentAccount;
}

void InstagramClient::setCurrentAccount(InstagramAccount *account)
{
    if (_currentAccount == account)
        return;

    _currentAccount = account;
    this->apiNetworkAccessManager->setCookieJar(account->cookieJar());

    emit currentAccountChanged();
}

void InstagramClient::apiRequestFinished(QNetworkReply *reply)
{
    qDebug() << qPrintable("Request finished");

    auto response = QString::fromUtf8(reply->readAll());
    auto json = QtJson::parse(response);

    //qDebug() << reply->rawHeaderPairs();
    //qDebug() << response;

    QUuid key = reply->request().attribute(QNetworkRequest::User).value<QUuid>();
    auto cb = this->callbacks->take(key);

    if (!cb.isUndefined())
        cb.call(QJSValueList {cb.engine()->toScriptValue(json)});

    auto statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    if (statusCode != 200)
        this->handleRequestError(json.toMap()["message"].toString());
}

void InstagramClient::loginFinished(QNetworkReply *reply)
{
    QByteArray response = reply->readAll();
    qDebug() << qPrintable(response);

    QJsonParseError error;
    auto json = QJsonDocument::fromJson(response, &error).toVariant();
    auto jsonMap = json.toMap();



    InstagramAccount *account = 0;

    if (reply->error() == QNetworkReply::NoError && error.error == QJsonParseError::NoError && jsonMap["status"].toString() == "ok") {
        auto loggedInUserObj = jsonMap["logged_in_user"].toMap();

        auto userID = loggedInUserObj["pk"].toLongLong();
        auto userName = loggedInUserObj["username"].toString();
        auto fullName = loggedInUserObj["full_name"].toString();

        bool hadAccount = InstagramAccountManager::instance()->allAccounts().count() > 0;

        account = InstagramAccountManager::instance()->createAccount(userID, userName, fullName, qobject_cast<DConfCookieJar*>(reply->manager()->cookieJar()), !hadAccount);
    }

    QUuid key = reply->request().attribute(QNetworkRequest::User).value<QUuid>();
    auto cb = this->callbacks->take(key);

    if (!cb.isUndefined())
        cb.call(QJSValueList {cb.engine()->toScriptValue(json), cb.engine()->toScriptValue(account)});

}

QString InstagramClient::phoneID() const
{
    QString phoneID = phoneIDConfItem->value().toString();

    if (phoneID.isEmpty()) {
        phoneID = createCleanedUuid();
        phoneIDConfItem->set(phoneID);
    }

    return phoneID;
}

QString InstagramClient::guid() const
{
    QString guid = guidConfItem->value().toString();

    if (guid.isEmpty()) {
        guid = createCleanedUuid();
        guidConfItem->set(guid);
    }

    return guid;
}

QString InstagramClient::deviceID() const
{
    QString deviceID = deviceIDConfItem->value().toString();

    if (deviceID.isEmpty()) {
        deviceID = QString("android-").append(createCleanedUuid().remove(QChar('-')).left(16));
        deviceIDConfItem->set(deviceID);
    }

    return deviceID;
}

QString InstagramClient::createCleanedUuid() const
{
    // Create a new UUID and remove '{' and '}' from the beginning and end of the string
    return QUuid::createUuid().toString().mid(1, 36);
}

int InstagramClient::timezoneOffset() const
{
    return QDateTime::currentDateTime().offsetFromUtc();
}

QByteArray InstagramClient::getSignedBody(QJsonObject json) const
{
    QJsonDocument doc(json);
    QByteArray jsonData = doc.toJson(QJsonDocument::Compact);

    return this->getSignedBody(jsonData);
}

QByteArray InstagramClient::getSignedBody(QByteArray data) const
{
    return QByteArray("signed_body=").append(signData(data)).append("&ig_sig_key_version=4&d=0");
}

QByteArray InstagramClient::signData(QByteArray data) const
{
    QMessageAuthenticationCode code(QCryptographicHash::Sha256);
    code.setKey(QByteArrayLiteral(INSTAGRAM_SIGNATURE_KEY));
    code.addData(data);

    return code.result().toHex().append(".").append(data);
}

//QNetworkAccessManager *InstagramClient::createNetworkAccessManager(QJSValue callback)
//{
//    // remember the callback with a key so we can access it later in the QNetworkAccessManager::finished slot
//    auto key = QUuid::createUuid();
//    if (!callback.isUndefined()) {
//        callbacks->insert(key, callback);
//    }

//    QNetworkAccessManager *m = new QNetworkAccessManager(this);
//    m->setCookieJar(this->currentAccount()->cookieJar());

//    connect(m, &QNetworkAccessManager::finished, [this, key](QNetworkReply *reply) {
//        qDebug() << "sendRequest: got response.";

//        auto response = reply->readAll();
//        auto json = QJsonDocument::fromJson(response);

//        auto cb = this->callbacks->take(key);

//        if (!cb.isUndefined())
//            cb.call(QJSValueList { cb.engine()->toScriptValue(json.toVariant())});
//    });

//    return m;
//}

void InstagramClient::updateTimeline(QJSValue callback)
{
    return this->updateTimeline(QString::null, callback);
}

void InstagramClient::updateTimeline(QString maxID, QJSValue callback)
{
    qDebug() << "Update timeline...";

    QUrlQuery q;
    q.addQueryItem("phone_id", phoneID());
    q.addQueryItem("timezone_offset", QString::number(timezoneOffset()));

    if (!maxID.isEmpty())
        q.addQueryItem("max_id", maxID);

    QUrl url("https://i.instagram.com/api/v1/feed/timeline/");
    url.setQuery(q);

    executeGetRequest(url, callback);
}

void InstagramClient::loadCommentsForMedia(QString mediaID, QJSValue callback)
{
    return loadCommentsForMedia(mediaID, QString::null, callback);
}

void InstagramClient::loadCommentsForMedia(QString mediaID, QString maxID, QJSValue callback)
{
    QUrl url(QString("https://i.instagram.com/api/v1/media/%1/comments/").arg(mediaID));

    if (!maxID.isEmpty()) {
        QUrlQuery q;
        q.addQueryItem("max_id", maxID);

        url.setQuery(q);
    }

    executeGetRequest(url, callback);
}

void InstagramClient::sendComment(QString mediaID, QString comment, QJSValue callback)
{
    QJsonObject json;
    json["_uid"] = QString::number(currentAccount()->userID());
    json["_uuid"] = guid();
    json["comment_text"] = comment.trimmed();

    QByteArray body = this->getSignedBody(json);

    QUrl url(QString("https://i.instagram.com/api/v1/media/%1/comment/").arg(mediaID));
    executePostRequest(url, body, callback);
}

void InstagramClient::deleteComments(QString mediaID, QStringList commentIDs, QJSValue callback)
{
    QJsonObject json;
    json["_uid"] = QString::number(currentAccount()->userID());
    json["_uuid"] = guid();
    json["comment_ids_to_delete"] = commentIDs.join(QChar(','));

    QByteArray body = this->getSignedBody(json);

    QUrl url(QString("https://i.instagram.com/api/v1/media/%1/comment/bulk_delete/").arg(mediaID));
    executePostRequest(url, body, callback);

}

void InstagramClient::loadLikers(QString mediaID, QJSValue callback)
{
    QUrl url(QString("https://i.instagram.com/api/v1/media/%1/likers/").arg(mediaID));
    executeGetRequest(url, callback);
}

void InstagramClient::like(QString mediaID, QJSValue callback)
{
    QJsonObject json;
    json["module_name"] = QString("feed_timeline");
    json["media_id"] = mediaID;
    json["_uid"] = QString::number(currentAccount()->userID());
    json["_uuid"] = guid();

    QByteArray body = this->getSignedBody(json);

    QUrl url(QString("https://i.instagram.com/api/v1/media/%1/like/").arg(mediaID));
    executePostRequest(url, body, callback);
}

void InstagramClient::unlike(QString mediaID, QJSValue callback)
{
    QJsonObject json;
    json["module_name"] = QString("feed_timeline");
    json["media_id"] = mediaID;
    json["_uid"] = currentAccount()->userID();
    json["_uuid"] = guid();

    QByteArray body = this->getSignedBody(json);

    QUrl url(QString("https://i.instagram.com/api/v1/media/%1/unlike/").arg(mediaID));
    executePostRequest(url, body, callback);
}

void InstagramClient::discover(QString maxID, QJSValue callback)
{
    static QString sessionID;

    if (maxID.isEmpty() || sessionID.isEmpty())
        sessionID = createCleanedUuid();

    QUrlQuery q;
    q.addQueryItem("is_prefetch", "false");
    q.addQueryItem("session_id", sessionID);

    if (!maxID.isEmpty())
        q.addQueryItem("max_id", maxID);

    QUrl url("https://i.instagram.com/api/v1/discover/explore/");
    url.setQuery(q);

    executeGetRequest(url, callback);
}

void InstagramClient::loadUserInfo(qlonglong userID, QJSValue callback)
{
    qDebug() << "load by id" << userID;
    QUrl url(QString("https://i.instagram.com/api/v1/users/%1/info/").arg(userID));
    executeGetRequest(url, callback);
}

void InstagramClient::loadUserInfo(QString username, QJSValue callback)
{
    qDebug() << "load by name" << username;
    QUrl url(QString("https://i.instagram.com/api/v1/users/%1/usernameinfo/").arg(username));
    executeGetRequest(url, callback);
}

void InstagramClient::loadUserFeed(qlonglong userID, QString maxID, QJSValue callback)
{
    QUrl url(QString("https://i.instagram.com/api/v1/feed/user/%1/").arg(userID));

    if (!maxID.isEmpty()) {
        QUrlQuery q;
        q.addQueryItem("max_id", maxID);

        url.setQuery(q);
    }

    executeGetRequest(url, callback);
}

void InstagramClient::loadLocationFeed(qlonglong locationID, QString maxID, QString rankToken, QJSValue callback)
{
    QUrlQuery q;
    q.addQueryItem("rank_token", rankToken);

    if (!maxID.isEmpty())
        q.addQueryItem("max_id", maxID);

    QUrl url(QString("https://i.instagram.com/api/v1/feed/location/%1/").arg(locationID));
    url.setQuery(q);

    executeGetRequest(url, callback);
}

void InstagramClient::loadTagFeed(QString tag, QString maxID, QString rankToken, QJSValue callback)
{
    QUrlQuery q;
    q.addQueryItem("rank_token", rankToken);

    if (!maxID.isEmpty())
        q.addQueryItem("max_id", maxID);

    QUrl url(QString("https://i.instagram.com/api/v1/feed/tag/%1/").arg(tag));
    url.setQuery(q);

    executeGetRequest(url, callback);
}

void InstagramClient::loadRelatedTags(QString tag, QStringList visitedTags, QJSValue callback)
{
    if (visitedTags.isEmpty() || visitedTags.first() != tag)
        visitedTags.insert(0, tag);

    QVariantList visitedList;

    foreach (QString visitedTag, visitedTags) {
        QVariantMap visitedTagMap;
        visitedTagMap["id"] = visitedTag;
        visitedTagMap["type"] = "hashtag";

        visitedList << visitedTagMap;
    }

    QUrlQuery q;
    q.addQueryItem("visited", QtJson::serializeStr(visitedList));
    q.addQueryItem("related_types", "[\"hashtag\"]");

    QUrl url(QString("https://i.instagram.com/api/v1/tags/%1/related/").arg(tag));
    url.setQuery(q);

    executeGetRequest(url, callback);
}

void InstagramClient::loadTagInfos(QString tag, QJSValue callback)
{
    QUrl url(QString("https://i.instagram.com/api/v1/tags/%1/info/").arg(tag));
    executeGetRequest(url, callback);
}

void InstagramClient::loadFriendshipStatus(qlonglong userID, QJSValue callback)
{
    QUrl url(QString("https://i.instagram.com/api/v1/friendships/show/%1/").arg(userID));
    executeGetRequest(url, callback);
}

void InstagramClient::loadFriendshipStatus(QList<qlonglong> userIDs, QJSValue callback)
{
    QStringList ids;
    foreach (qlonglong userID, userIDs) {
        ids.append(QString::number(userID));
    }

    QUrlQuery q;
    q.addQueryItem("user_ids", ids.join(","));

    executePostRequest(QUrl("https://i.instagram.com/api/v1/friendships/show_many/"), q.toString(QUrl::FullyDecoded).toUtf8(), callback);
}

void InstagramClient::loadFollowers(qlonglong userID, QString maxID, QJSValue callback)
{
    static QString rankToken;

    if (maxID.isEmpty() || rankToken.isEmpty())
        rankToken = createCleanedUuid();


    QUrlQuery q;
    q.addQueryItem("module", "overview");
    q.addQueryItem("support_new_api", "true");
    q.addQueryItem("rank_token", rankToken);

    if (!maxID.isEmpty())
        q.addQueryItem("max_id", maxID);

    QUrl url(QString("https://i.instagram.com/api/v1/friendships/%1/followers/").arg(userID));
    url.setQuery(q);

    executeGetRequest(url, callback);
}

void InstagramClient::loadFollowing(QString module, qlonglong userID, QString maxID, QJSValue callback)
{
    static QString rankToken;

    if (maxID.isEmpty() || rankToken.isEmpty())
        rankToken = createCleanedUuid();

    QUrlQuery q;
    q.addQueryItem("module", module);
    q.addQueryItem("support_new_api", "true");
    q.addQueryItem("rank_token", rankToken);

    if (!maxID.isEmpty())
        q.addQueryItem("max_id", maxID);

    QUrl url(QString("https://i.instagram.com/api/v1/friendships/%1/following/").arg(userID));
    url.setQuery(q);

    executeGetRequest(url, callback);
}

void InstagramClient::search(SearchCategory category, QString query, int count, QString rankToken, QJSValue callback)
{
    QUrl url;

    switch (category) {
    case InstagramClient::TopSearch:
        url = QUrl(QString("https://i.instagram.com/api/v1/fbsearch/topsearch/"));
        break;

    case InstagramClient::UsersSearch:
        url = QUrl(QString("https://i.instagram.com/api/v1/users/search/"));
        break;

    case InstagramClient::TagsSearch:
        url = QUrl(QString("https://i.instagram.com/api/v1/tags/search/"));
        break;

    case InstagramClient::PlacesSearch:
        url = QUrl(QString("https://i.instagram.com/api/v1/fbsearch/places/"));
        break;

    }

    QUrlQuery q;
    q.addQueryItem("timezone_offset", QString::number(timezoneOffset()));
    q.addQueryItem("count", QString::number(count));
    q.addQueryItem("rank_token", rankToken);

    if (category == InstagramClient::TopSearch)
        q.addQueryItem("context", "blended");

    if (category == InstagramClient::TopSearch || category == InstagramClient::PlacesSearch)
        q.addQueryItem("query", query);
    else
        q.addQueryItem("q", query);

    url.setQuery(q);

    executeGetRequest(url, callback);
}

void InstagramClient::executeGetRequest(QUrl url, QJSValue callback)
{
    auto key = QUuid::createUuid();

    if (!callback.isUndefined())
        callbacks->insert(key, callback);

    QNetworkRequest request(url);
    this->setRequiredHeaders(request);
    request.setAttribute(QNetworkRequest::User, key);

    qDebug() << request.url().toString();
    this->apiNetworkAccessManager->get(request);
}

void InstagramClient::executePostRequest(QUrl url, QByteArray postData, QJSValue callback)
{
    auto key = QUuid::createUuid();

    if (!callback.isUndefined())
        callbacks->insert(key, callback);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded; charset=UTF-8");
    this->setRequiredHeaders(request);
    request.setAttribute(QNetworkRequest::User, key);

    qDebug() << "executePostRequest" << request.url().toString();
    qDebug() << "postData:" << postData;

    this->apiNetworkAccessManager->post(request, postData);
}

void InstagramClient::setRequiredHeaders(QNetworkRequest &request)
{
    auto userAgent = QString("Instagram %1 Android (23/6.0.1; 480dpi; 1080x1776; OnePlus/oneplus; A0001; A0001; bacon; %2)").arg(INSTAGRAM_SIGNATURE_VERSION).arg(QLocale::system().name());
    qDebug() << userAgent;

    request.setHeader(QNetworkRequest::UserAgentHeader, userAgent);
    request.setRawHeader("X-IG-Connection-Type", "WIFI");
    request.setRawHeader("X-IG-Capabilities", "3Q==");
    request.setRawHeader("Accept-Language", QLocale::system().name().replace("_", "-").toUtf8());
}

void InstagramClient::handleRequestError(QString error)
{
    qDebug() << error;

    if (error == QStringLiteral("login_required"))
        emit accountNeedsRelogin(currentAccount());
}

InstagramClient *InstagramClient::instance()
{
    if (_instance == 0)
        _instance = new InstagramClient();

    return _instance;
}

QObject *InstagramClient::qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);

    return instance();
}
