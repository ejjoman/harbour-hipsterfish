# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-hipsterfish

QT += qml
CONFIG += link_pkgconfig sailfishapp c++11
PKGCONFIG += mlite5

SOURCES += src/harbour-hipsterfish.cpp \
    src/dconfcookiejar.cpp \
    src/instagramclient.cpp \
    src/instagramaccount.cpp \
    src/instagramaccountmanager.cpp

OTHER_FILES += qml/harbour-hipsterfish.qml \
    qml/cover/CoverPage.qml \
    rpm/harbour-hipsterfish.changes.in \
    rpm/harbour-hipsterfish.spec \
    rpm/harbour-hipsterfish.yaml \
    translations/*.ts \
    harbour-hipsterfish.desktop

# Load Instagram signature key
KEY_FILE = $$PWD/instagram_signature_key.key
!exists($$KEY_FILE) {
    error("Instagram signature key file not found: instagram_signature_key.key")
}

INSTAGRAM_SIGNATURE_KEY = $$cat($$KEY_FILE)

DEFINES += INSTAGRAM_SIGNATURE_KEY=\\\"$${INSTAGRAM_SIGNATURE_KEY}\\\" \
    APP_NAME=\\\"$${TARGET}\\\"

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

# to disable building translations every time, comment out the
# following CONFIG line
#CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-hipsterfish-de.ts

DISTFILES += \
    instagram_signature_key.key \
    instagram_signature_key_old.key \
    qml/pages/LoginPage.qml \
    qml/pages/StartPage.qml \
    qml/common/JSONListModel.qml \
    qml/js/jsonpath.js \
    qml/delegates/PostDelegate.qml \
    qml/pages/CommentsPage.qml \
    qml/common/ProfilePicture.qml \
    qml/views/TimelineView.qml \
    qml/common/BaseView.qml \
    qml/views/SearchView.qml \
    qml/views/NotificationsView.qml \
    qml/views/MeView.qml \
    qml/common/LoadingMoreIndicator.qml \
    qml/common/CommentEditor.qml

HEADERS += \
    src/dconfcookiejar.h \
    src/instagramclient.h \
    src/instagramaccount.h \
    src/instagramaccountmanager.h

include(3rdparty/qt-json/qt-json.pri)
