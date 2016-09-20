#include "qmlstringutils.h"
#include <QJSEngine>

QmlStringUtils *QmlStringUtils::_instance = 0;

QmlStringUtils::QmlStringUtils(QObject *parent) : QObject(parent)
{}

QmlStringUtils *QmlStringUtils::instance()
{
    if (_instance == 0)
        _instance = new QmlStringUtils();

    return _instance;
}

QObject *QmlStringUtils::qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);

    return instance();
}

QString QmlStringUtils::replace(QString text, QString regex, QString after)
{
    return text.replace(QRegExp(regex), after);
}

QString QmlStringUtils::toHtmlEscaped(QString text)
{
    return text.toHtmlEscaped();
}



