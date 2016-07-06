#include "dconfcookiejar.h"
#include <QNetworkCookie>
#include <QDateTime>
#include <QDebug>

DConfCookieJar::DConfCookieJar(QObject *parent)
    : QNetworkCookieJar(parent),
      _loaded(false),
      _isTemporary(true)
{}

DConfCookieJar::DConfCookieJar(QString settingsPath, QObject *parent)
    : QNetworkCookieJar(parent),
      _cookiesConfItem(new MGConfItem(settingsPath, parent)),
      _loaded(false),
      _isTemporary(false)
{}

void DConfCookieJar::load()
{
    if (_loaded || _isTemporary)
        return;

    _loaded = true;

    qDebug() << "Loading cookies...";

    QVariantList cookies = _cookiesConfItem->value().toList();

    if (cookies.count() > 0) {
        foreach(QVariant cookie, cookies) {
            QList<QNetworkCookie> parsedCookies = QNetworkCookie::parseCookies(cookie.value<QByteArray>());

            auto cookieData = parsedCookies[0];

            qDebug() << "Cookie " << cookieData.value();

            if (!cookieData.expirationDate().isValid() || cookieData.expirationDate().toUTC() < QDateTime::currentDateTime().toUTC())
                continue;

            insertCookie(cookieData);
        }
    }
}

void DConfCookieJar::save()
{
    if (_isTemporary)
        return;

    QList<QNetworkCookie> cookies = allCookies();

    QVariantList cookieData;

    foreach (QNetworkCookie cookie, cookies) {
        cookieData << cookie.toRawForm();
    }

    _cookiesConfItem->set(cookieData);
}

bool DConfCookieJar::isTemporary() const
{
    return _isTemporary;
}

void DConfCookieJar::importFromTemporaryCookieJar(DConfCookieJar *temporaryCookieJar)
{
    if (!temporaryCookieJar->isTemporary() || allCookies().count() > 0)
        return;

    foreach (QNetworkCookie cookie, temporaryCookieJar->allCookies())
        insertCookie(cookie);
}

DConfCookieJar *DConfCookieJar::createTemporaryCookieJar(QObject *parent)
{
    return new DConfCookieJar(parent);
}


