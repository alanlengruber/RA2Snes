#include <QtTest>
#include <QJsonObject>
#include "avatarurl.h"

// O login do RA devolve o nome de EXIBIÇÃO em "User", mas o avatar fica guardado
// pelo nome de usuário original. O endereço certo vem em "AvatarUrl".
class TestAvatarUrl : public QObject
{
    Q_OBJECT

private slots:
    void usesServerAvatarUrl()
    {
        const QJsonObject login{
            { "User", "Turbu" },
            { "AvatarUrl", "https://media.retroachievements.org/UserPic/alanlengruber.png?v=1789964438" }
        };

        QCOMPARE(avatarUrlFromLogin(login, "https://media.retroachievements.org/", "123"),
                 QUrl("https://media.retroachievements.org/UserPic/alanlengruber.png?v=1789964438"));
    }

    void resolvesRelativeServerAvatarUrl()
    {
        const QJsonObject login{ { "User", "Turbu" }, { "AvatarUrl", "/UserPic/alanlengruber.png" } };

        QCOMPARE(avatarUrlFromLogin(login, "https://media.retroachievements.org/", "123"),
                 QUrl("https://media.retroachievements.org/UserPic/alanlengruber.png"));
    }

    void fallsBackToLegacyPathWhenMissing()
    {
        const QJsonObject login{ { "User", "Turbu" } };

        QCOMPARE(avatarUrlFromLogin(login, "https://media.retroachievements.org/", "123"),
                 QUrl("https://media.retroachievements.org/UserPic/Turbu.png?v=123"));
    }

    void fallsBackToLegacyPathWhenEmpty()
    {
        const QJsonObject login{ { "User", "Turbu" }, { "AvatarUrl", "" } };

        QCOMPARE(avatarUrlFromLogin(login, "https://media.retroachievements.org/", "123"),
                 QUrl("https://media.retroachievements.org/UserPic/Turbu.png?v=123"));
    }
};

QTEST_APPLESS_MAIN(TestAvatarUrl)
#include "tst_avatarurl.moc"
