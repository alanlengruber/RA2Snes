#ifndef AVATARURL_H
#define AVATARURL_H

#include <QJsonObject>
#include <QString>
#include <QUrl>

// The login response's "User" is the display name, but avatars are stored under
// the original username, so building UserPic/<User>.png breaks after a rename.
// Like rcheevos (rc_api_process_login_response), prefer the server's AvatarUrl
// and only build the legacy path when it is missing. The server URL is already
// versioned; the legacy path gets a per-launch token to get past the 31-day cache.
inline QUrl avatarUrlFromLogin(const QJsonObject& login, const QString& mediaUrl, const QString& cacheToken)
{
    const QString serverUrl = login["AvatarUrl"].toString();
    if (!serverUrl.isEmpty())
        return QUrl(mediaUrl).resolved(QUrl(serverUrl));

    return QUrl(mediaUrl + "UserPic/" + login["User"].toString() + ".png?v=" + cacheToken);
}

#endif // AVATARURL_H
