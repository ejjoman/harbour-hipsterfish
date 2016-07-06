#ifndef INSTAGRAMACCOUNTMANAGER_H
#define INSTAGRAMACCOUNTMANAGER_H

#include <QObject>
#include <mlite5/MGConfItem>

class InstagramAccount;
class QQmlEngine;
class QJSEngine;
class DConfCookieJar;

class InstagramAccountManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(InstagramAccount* defaultAccount READ defaultAccount WRITE setDefaultAccount NOTIFY defaultAccountChanged)
    Q_PROPERTY(bool hasAccount READ hasAccount NOTIFY hasAccountChanged)

public:
    static const QString ACCOUNTS_SETTINGS_PATH;

    static InstagramAccountManager *instance();
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine);

    InstagramAccount *defaultAccount() const;
    void setDefaultAccount(const InstagramAccount *account);

    QMap<qlonglong, InstagramAccount*> allAccounts() const;

    bool hasAccount() const;

    InstagramAccount *createAccount(qlonglong userID, QString userName, QString fullName, DConfCookieJar *cookieJar, bool isDefaultAccount);

signals:
    void accountsChanged();
    void defaultAccountChanged();
    void hasAccountChanged();

public slots:

private slots:
    void loadAccounts();

private:
    static InstagramAccountManager *_instance;

    MGConfItem *_accountsConfItem;
    MGConfItem *_defaultAccountConfItem;

    QMap<qlonglong, InstagramAccount*> _accounts;

    explicit InstagramAccountManager(QObject *parent = 0);

};

#endif // INSTAGRAMACCOUNTMANAGER_H
