#include "instagramaccount.h"
#include <QCoreApplication>
#include "instagramclient.h"
#include "instagramaccountmanager.h"
#include <limits.h>

InstagramAccount::InstagramAccount(QObject *parent)
    : QObject(parent),
      _userID(-1)
{}

InstagramAccount::InstagramAccount(qlonglong userID, QObject *parent)
    : QObject(parent),
      _userID(userID),
      SETTINGS_PATH(InstagramAccountManager::ACCOUNTS_SETTINGS_PATH + QString("/") + QString::number(userID)),
      _cookieJar(new DConfCookieJar(SETTINGS_PATH + "/cookies")),
      _userNameConfItem(new MGConfItem(SETTINGS_PATH + "/username")),
      _fullNameConfItem(new MGConfItem(SETTINGS_PATH + "/fullname"))
{
    connect(_userNameConfItem, SIGNAL(valueChanged()), this, SIGNAL(userNameChanged()));
    connect(_fullNameConfItem, SIGNAL(valueChanged()), this, SIGNAL(fullNameChanged()));

    _cookieJar->load();
}

qlonglong InstagramAccount::userID() const
{
    return _userID;
}

QString InstagramAccount::userIDString() const
{
    return QString::number(userID());
}

QString InstagramAccount::userName() const
{
    if (_userID == -1)
        return QString();

    return _userNameConfItem->value().toString();
}

void InstagramAccount::setUserName(const QString userName)
{
    if (_userID == -1)
        return;

    _userNameConfItem->set(userName);
}

QString InstagramAccount::fullName() const
{
    if (_userID == -1)
        return QString();

    return _fullNameConfItem->value().toString();
}

void InstagramAccount::setFullName(QString fullName)
{
    if (_userID == -1)
        return;

    _fullNameConfItem->set(fullName);
}

DConfCookieJar *InstagramAccount::cookieJar() const
{
    if (_userID == -1)
        return 0;

    return _cookieJar;
}

void InstagramAccount::save()
{
    if (_userID == -1)
        return;

    _cookieJar->save();
}


