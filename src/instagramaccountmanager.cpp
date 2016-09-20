#include "instagramaccountmanager.h"
#include "instagramclient.h"
#include "instagramaccount.h"
#include <QDir>
#include <QQmlEngine>
#include <QJSEngine>

const QString InstagramAccountManager::ACCOUNTS_SETTINGS_PATH = InstagramClient::SETTINGS_PATH + QString("accounts");
InstagramAccountManager *InstagramAccountManager::_instance = 0;

InstagramAccountManager::InstagramAccountManager(QObject *parent)
    : QObject(parent),
      _accountsConfItem(new MGConfItem(ACCOUNTS_SETTINGS_PATH)),
      _defaultAccountConfItem(new MGConfItem(InstagramClient::SETTINGS_PATH + QString("defaultAccount"), this))
{
    connect(_accountsConfItem, &MGConfItem::valueChanged, this, &InstagramAccountManager::loadAccounts);
    connect(_defaultAccountConfItem, &MGConfItem::valueChanged, this, &InstagramAccountManager::defaultAccountChanged);

    loadAccounts();
}

InstagramAccountManager *InstagramAccountManager::instance()
{
    if (_instance == 0)
        _instance = new InstagramAccountManager();

    return _instance;
}

QObject *InstagramAccountManager::qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);

    return instance();
}

InstagramAccount *InstagramAccountManager::defaultAccount() const
{
    qlonglong defaultAccount = _defaultAccountConfItem->value().toLongLong();

    if (defaultAccount == 0 || !_accounts.contains(defaultAccount))
        return 0;

    return _accounts[defaultAccount];
}

void InstagramAccountManager::setDefaultAccount(const InstagramAccount *account)
{
    if (!_accounts.contains(account->userID()))
        return;

    _defaultAccountConfItem->set(account->userID());
}

QMap<qlonglong, InstagramAccount *> InstagramAccountManager::allAccounts() const
{
    return _accounts;
}

bool InstagramAccountManager::hasAccount() const
{
    return _accounts.count() > 0;
}

InstagramAccount *InstagramAccountManager::createAccount(qlonglong userID, QString userName, QString fullName, DConfCookieJar *cookieJar, bool isDefaultAccount)
{
    InstagramAccount *account;

    if (_accounts.contains(userID)) {
        account = _accounts[userID];
    } else {
        account = new InstagramAccount(userID, this);
        this->_accounts.insert(userID, account);
    }

    account->setUserName(userName);
    account->setFullName(fullName);
    account->cookieJar()->importFromTemporaryCookieJar(cookieJar);
    account->save();

    if (isDefaultAccount)
        setDefaultAccount(account);

    return account;
}

void InstagramAccountManager::loadAccounts()
{
    bool hadAccount = hasAccount();

    this->_accounts.clear();

    auto test = _accountsConfItem->listDirs();

    foreach (QString path, test) {
        qlonglong accountID = QDir(path).dirName().toLongLong();
        InstagramAccount *account = new InstagramAccount(accountID, this);

        this->_accounts.insert(accountID, account);
    }

    emit accountsChanged();

    if (hadAccount != hasAccount())
        emit hasAccountChanged();
}

