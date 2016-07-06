#ifndef INSTAGRAMACCOUNT_H
#define INSTAGRAMACCOUNT_H

#include <QObject>
#include "dconfcookiejar.h"
#include <mlite5/MGConfItem>

class InstagramAccount : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString userName READ userName NOTIFY userNameChanged)
    Q_PROPERTY(QString fullName READ fullName NOTIFY fullNameChanged)

public:
    explicit InstagramAccount(const qlonglong userID, QObject *parent = 0);

    qlonglong userID() const;

    QString userName() const;
    void setUserName(const QString userName);

    QString fullName() const;
    void setFullName(QString fullName);

    DConfCookieJar *cookieJar() const;
    void save();

signals:
    void userNameChanged();
    void fullNameChanged();

    void testChanged(int test);

public slots:

private:
    const qlonglong _userID;
    const QString SETTINGS_PATH;

    DConfCookieJar *_cookieJar;

    MGConfItem *_userNameConfItem;
    MGConfItem *_fullNameConfItem;

};

#endif // INSTAGRAMACCOUNT_H
