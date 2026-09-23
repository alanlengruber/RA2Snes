#include <QtQuickTest>
#include <QQmlEngine>
#include "userinfomodel.h"
#include "gameinfomodel.h"
#include "achievementmodel.h"
#include "achievementsortfilterproxymodel.h"

// O Ra2snes de verdade arrasta USB, rede e websocket. Os componentes só leem
// richPresence dele, então um dublê com essa única propriedade basta.
class FakeRa2snes : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString richPresence READ richPresence NOTIFY updatedRichText)

public:
    QString richPresence() const { return m_richPresence; }

signals:
    void updatedRichText();

private:
    QString m_richPresence = QStringLiteral("Kong Quest - Gangplank Galley");
};

// Os models reais (não dublês) ficam registrados: assim um nome de propriedade
// errado num componente vira warning em runtime, e o failOnWarning dos testes pega.
class Setup : public QObject
{
    Q_OBJECT

public slots:
    void qmlEngineAvailable(QQmlEngine *)
    {
        GameInfoModel *game = GameInfoModel::instance();
        game->title(QStringLiteral("Donkey Kong Country 2"));
        game->console(QStringLiteral("SNES/Super Famicom"));
        game->completion_count(20);
        game->achievement_count(80);
        game->point_count(100);
        game->point_total(835);
        game->missable_count(1);

        UserInfoModel *user = UserInfoModel::instance();
        user->username(QStringLiteral("SuperNinTaylor"));
        user->hardcore(true);
        user->hardcore_score(8205);
        user->softcore_score(12);

        // Estados variados de propósito: desbloqueada, com progresso, e os três
        // tipos com ícone — cada combinação exercita um ramo do delegate.
        const QStringList titles = {
            "DK: Donkey Kong", "Kremling Kurrency", "KONGQuest", "Lost World",
            "Bramble Scramble", "Krow's Nest", "Hot-Head Hop", "Kleever's Kiln"
        };
        const QStringList types = { "", "missable", "progression", "win_condition" };
        QList<AchievementInfo> achievements;
        for (int i = 0; i < titles.size(); ++i) {
            AchievementInfo a;
            a.id = 1000 + i;
            a.title = titles.at(i);
            a.description = QStringLiteral("Fixture achievement %1").arg(i);
            a.points = 2 + i;
            a.type = types.at(i % types.size());
            a.unlocked = (i % 3 == 0);
            if (a.unlocked)
                a.time_unlocked_string = QStringLiteral("September 22 2026, 9:00pm");
            if (i % 4 == 1) {
                a.target = 10;
                a.value = 4;
                a.percent = 40;
            }
            achievements.append(a);
        }
        AchievementModel::instance()->setAchievements(achievements);

        qmlRegisterType<AchievementSortFilterProxyModel>("CustomModels", 1, 0, "AchievementSortFilterProxyModel");
        qmlRegisterSingletonInstance("CustomModels", 1, 0, "AchievementModel", AchievementModel::instance());
        qmlRegisterSingletonInstance("CustomModels", 1, 0, "GameInfoModel", game);
        qmlRegisterSingletonInstance("CustomModels", 1, 0, "UserInfoModel", user);
        qmlRegisterSingletonInstance("CustomModels", 1, 0, "Ra2snes", &m_ra2snes);
    }

private:
    FakeRa2snes m_ra2snes;
};

QUICK_TEST_MAIN_WITH_SETUP(ra2snes_qml, Setup)

#include "tst_qml.moc"
