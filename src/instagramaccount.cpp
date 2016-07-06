#include "instagramaccount.h"
#include <QCoreApplication>
#include "instagramclient.h"
#include "instagramaccountmanager.h"

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

QString InstagramAccount::userName() const
{
    return _userNameConfItem->value().toString();
}

void InstagramAccount::setUserName(const QString userName)
{
    _userNameConfItem->set(userName);
}

QString InstagramAccount::fullName() const
{
    return _fullNameConfItem->value().toString();
}

void InstagramAccount::setFullName(QString fullName)
{
    _fullNameConfItem->set(fullName);
}

DConfCookieJar *InstagramAccount::cookieJar() const
{
    return _cookieJar;
}

void InstagramAccount::save()
{
    _cookieJar->save();
}


