#ifndef DCONFCOOKIEJAR_H
#define DCONFCOOKIEJAR_H

#include <QNetworkCookieJar>
#include <mlite5/MGConfItem>

class DConfCookieJar : public QNetworkCookieJar
{
    Q_OBJECT

public:
    DConfCookieJar(QString settingsPath, QObject *parent = 0);
    void load();
    void save();

    bool isTemporary() const;
    void importFromTemporaryCookieJar(DConfCookieJar *temporaryCookieJar);

    static DConfCookieJar *createTemporaryCookieJar(QObject *parent = 0);

signals:

public slots:

private:
    DConfCookieJar(QObject *parent = 0);

    MGConfItem *_cookiesConfItem;
    bool _loaded;
    const bool _isTemporary;

};

#endif // DCONFCOOKIEJAR_H
