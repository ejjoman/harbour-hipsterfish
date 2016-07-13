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
#include "instagramaccountmanager.h"
#include <QNetworkProxy>
#include <limits.h>
#include <QTimeZone>
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

void InstagramClient::login(QString username, QString password)
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

    QNetworkRequest req(QUrl("https://i.instagram.com/api/v1/accounts/login/"));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded; charset=UTF-8");

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

    QUuid key = reply->request().attribute(QNetworkRequest::User).value<QUuid>();

    auto cb = this->callbacks->take(key);

    if (!cb.isUndefined()) {
        auto response = reply->readAll();
        auto json = QtJson::parse(QString(response));
        cb.call(QJSValueList {cb.engine()->toScriptValue(json)});
    }
}

void InstagramClient::loginFinished(QNetworkReply *reply)
{
    QByteArray response = reply->readAll();
    qDebug() << qPrintable(response);

    QJsonParseError error;
    auto json = QJsonDocument::fromJson(response, &error);

    qDebug() << json.toJson();

    if (reply->error() != QNetworkReply::NoError || error.error != QJsonParseError::NoError || json.object()["status"].toString() != "ok") {
        auto statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        emit loginError(statusCode, json);
        return;
    }

    auto loggedInUserObj = json.object().value("logged_in_user").toObject();

    auto userID = loggedInUserObj.value("pk").toVariant().toLongLong();
    auto userName = loggedInUserObj.value("username").toString();
    auto fullName = loggedInUserObj.value("full_name").toString();

    bool hadAccount = InstagramAccountManager::instance()->allAccounts().count() > 0;

    auto account = InstagramAccountManager::instance()->createAccount(userID, userName, fullName, qobject_cast<DConfCookieJar*>(reply->manager()->cookieJar()), !hadAccount);

    emit accountCreated(account);
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
    q.addQueryItem("timezone_offset", QString::number(QDateTime::currentDateTime().offsetFromUtc()));

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

void InstagramClient::executeGetRequest(QUrl url, QJSValue callback)
{
    auto key = QUuid::createUuid();
    if (!callback.isUndefined()) {
        callbacks->insert(key, callback);
    }

    QNetworkRequest request(url);
    this->setRequiredHeaders(request);
    request.setAttribute(QNetworkRequest::User, key);




    qDebug() << "executeGetRequest" << request.url().toString();
    this->apiNetworkAccessManager->get(request);
}

void InstagramClient::executePostRequest(QUrl url, QByteArray postData, QJSValue callback)
{
    auto key = QUuid::createUuid();
    if (!callback.isUndefined()) {
        callbacks->insert(key, callback);
    }

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
    request.setHeader(QNetworkRequest::UserAgentHeader, "Instagram 8.4.0 Android (23/6.0.1; 480dpi; 1080x1776; OnePlus/oneplus; A0001; A0001; bacon; de_DE)");
    request.setRawHeader("X-IG-Connection-Type", "WIFI");
    request.setRawHeader("X-IG-Capabilities", "3Q==");
    request.setRawHeader("Accept-Language", QLocale::system().name().replace("_", "-").toUtf8());
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

