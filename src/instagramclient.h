#ifndef INSTAGRAMCLIENT_H
#define INSTAGRAMCLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QJsonDocument>
#include <mlite5/MGConfItem>
#include <QCoreApplication>
#include <QJSValue>
#include "dconfcookiejar.h"
#include "instagramaccount.h"

class QQmlEngine;

class InstagramClient : public QObject
{
    Q_OBJECT

    Q_PROPERTY(InstagramAccount* currentAccount READ currentAccount WRITE setCurrentAccount NOTIFY currentAccountChanged)
    Q_PROPERTY(QString phoneID READ phoneID CONSTANT)

public:
    enum SearchCategory {
        TopSearch,
        UsersSearch,
        TagsSearch,
        PlacesSearch
    };

    Q_ENUMS(SearchCategory)

    static const QString SETTINGS_PATH;

    Q_INVOKABLE void login(QString username, QString password, QJSValue callback);

    InstagramAccount *currentAccount() const;
    void setCurrentAccount(InstagramAccount *account);

    static InstagramClient *instance();
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine);

    Q_INVOKABLE void updateTimeline(QJSValue callback);
    Q_INVOKABLE void updateTimeline(QString maxID, QJSValue callback);

    Q_INVOKABLE void loadCommentsForMedia(QString mediaID, QJSValue callback);
    Q_INVOKABLE void loadCommentsForMedia(QString mediaID, QString maxID, QJSValue callback);

    Q_INVOKABLE void sendComment(QString mediaID, QString comment, QJSValue callback);
    Q_INVOKABLE void deleteComments(QString mediaID, QStringList commentIDs, QJSValue callback);

    Q_INVOKABLE void loadLikers(QString mediaID, QJSValue callback);

    Q_INVOKABLE void like(QString mediaID, QJSValue callback);
    Q_INVOKABLE void unlike(QString mediaID, QJSValue callback);

    Q_INVOKABLE void discover(QString maxID, QJSValue callback);

    Q_INVOKABLE void loadUserInfo(qlonglong userID, QJSValue callback);
    Q_INVOKABLE void loadUserInfo(QString username, QJSValue callback);

    Q_INVOKABLE void loadUserFeed(qlonglong userID, QString maxID, QJSValue callback);
    Q_INVOKABLE void loadLocationFeed(qlonglong locationID, QString maxID, QString rankToken, QJSValue callback);
    Q_INVOKABLE void loadTagFeed(QString tag, QString maxID, QString rankToken, QJSValue callback);

    Q_INVOKABLE void loadRelatedTags(QString tag, QStringList visitedTags, QJSValue callback);
    Q_INVOKABLE void loadTagInfos(QString tag, QJSValue callback);

    Q_INVOKABLE void loadFriendshipStatus(qlonglong userID, QJSValue callback);
    Q_INVOKABLE void loadFriendshipStatus(QList<qlonglong> userIDs, QJSValue callback);

    Q_INVOKABLE void loadFollowers(qlonglong userID, QString maxID, QJSValue callback);
    Q_INVOKABLE void loadFollowing(QString module, qlonglong userID, QString maxID, QJSValue callback);

    Q_INVOKABLE void search(SearchCategory category, QString query, int count, QString rankToken, QJSValue callback);

    Q_INVOKABLE QString createCleanedUuid() const;

signals:
    void currentAccountChanged();
    void accountNeedsRelogin(InstagramAccount *account);

public slots:

private slots:
    void apiRequestFinished(QNetworkReply *reply);
    void loginFinished(QNetworkReply *reply);

private:
    static InstagramClient *_instance;

    MGConfItem *phoneIDConfItem;
    MGConfItem *guidConfItem;
    MGConfItem *deviceIDConfItem;

    QNetworkAccessManager *apiNetworkAccessManager;
    QNetworkAccessManager *loginNetworkAccessManager;

    InstagramAccount *_currentAccount;

    explicit InstagramClient(QObject *parent = 0);

    QString phoneID() const;
    QString guid() const;
    QString deviceID() const;

    int timezoneOffset() const;

    QByteArray getSignedBody(QJsonObject json) const;
    QByteArray getSignedBody(QByteArray data) const;
    QByteArray signData(QByteArray data) const;

    //QNetworkAccessManager *createNetworkAccessManager(QJSValue callback);

    void executeGetRequest(QUrl url, QJSValue callback);
    void executePostRequest(QUrl url, QByteArray postData, QJSValue callback);

    void setRequiredHeaders(QNetworkRequest &request);
    void handleRequestError(QString error);


    QMap<QUuid, QJSValue> *callbacks;
};

#endif // INSTAGRAMCLIENT_H
