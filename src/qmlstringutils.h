#ifndef QMLSTRINGUTILS_H
#define QMLSTRINGUTILS_H

#include <QObject>

class QQmlEngine;
class QJSEngine;

class QmlStringUtils : public QObject
{
    Q_OBJECT

public:
    static QmlStringUtils *instance();
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine);

    Q_INVOKABLE QString replace(QString text, QString regex, QString after);
    Q_INVOKABLE QString toHtmlEscaped(QString text);

private:
    static QmlStringUtils *_instance;
    explicit QmlStringUtils(QObject *parent = 0);

};

#endif // QMLSTRINGUTILS_H
