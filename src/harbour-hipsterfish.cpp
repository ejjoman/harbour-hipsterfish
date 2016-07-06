#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QDebug>
#include "instagramclient.h"
#include "instagramaccount.h"
#include "instagramaccountmanager.h"

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/template.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //
    // To display the view, call "show()" (will show fullscreen on device).

    QGuiApplication *app = SailfishApp::application(argc, argv);
    app->setApplicationName(APP_NAME);

    qDebug() << "The Instagram key is" << INSTAGRAM_SIGNATURE_KEY;

    qmlRegisterSingletonType<InstagramClient>("harbour.hipsterfish.Instagram", 1, 0, "InstagramClient", &InstagramClient::qmlInstance);
    qmlRegisterUncreatableType<InstagramAccount>("harbour.hipsterfish.Instagram", 1, 0, "InstagramAccount", "InstagramAccount is only available through InstagramAccountManager.");
    qmlRegisterSingletonType<InstagramAccountManager>("harbour.hipsterfish.Instagram", 1, 0, "InstagramAccountManager", &InstagramAccountManager::qmlInstance);

    QQuickView *view = SailfishApp::createView();
    view->setSource(SailfishApp::pathTo("qml/harbour-hipsterfish.qml"));

    view->show();

    return app->exec();
}

