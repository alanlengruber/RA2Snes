#include <QtQuickTest>
#include <QQmlEngine>
#include <QTemporaryDir>
#include <QDir>
#include <QFile>
#include "userinfomodel.h"
#include "gameinfomodel.h"
#include "achievementmodel.h"
#include "achievementsortfilterproxymodel.h"

// O Ra2snes de verdade arrasta USB, rede e websocket. Este dublê imita só a
// superfície que o QML toca: as propriedades lidas na carga, os slots chamados
// em clique ou ao fechar a janela (no-ops aqui) e todos os sinais.
class FakeRa2snes : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString console READ console NOTIFY consoleChanged)
    Q_PROPERTY(QString appDirPath READ appDirPath CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY newUpdate)
    Q_PROPERTY(bool ignore READ ignore WRITE ignoreUpdates NOTIFY ignoreChanged)
    Q_PROPERTY(bool websocket READ websocket WRITE enableWebSocket NOTIFY websocketChanged)
    Q_PROPERTY(bool customFirmware READ customFirmware NOTIFY firmwareChanged)
    Q_PROPERTY(QString richPresence READ richPresence NOTIFY updatedRichText)
    Q_PROPERTY(int refreshCalls READ refreshCalls NOTIFY refreshCallsChanged)

public:
    int refreshCalls() const { return m_refreshCalls; }
    QString console() const { return QStringLiteral("SNES"); }
    QString appDirPath() const { return m_appDir.path(); }
    QString version() const { return QStringLiteral("test"); }
    QString latestVersion() const { return QString(); }
    bool ignore() const { return true; }
    bool websocket() const { return false; }
    bool customFirmware() const { return false; }
    QString richPresence() const { return m_richPresence; }

    // Os testes disparam as mensagens de status que o Ra2snes real emite.
    Q_INVOKABLE void emitDisplayMessage(const QString &message, bool isError)
    {
        emit displayMessage(message, isError);
    }

    // No app real, isto marca o fim do carregamento do jogo (setupFinished).
    Q_INVOKABLE void emitEnableModeSwitching() { emit enableModeSwitching(); }

    // Mesma ordem do ra2snes.cpp ao terminar de carregar um jogo (sessionStarted).
    Q_INVOKABLE void emitGameLoaded()
    {
        emit achievementModelReady();
        emit enableModeSwitching();
    }

    // Console desconectado / volta ao menu: o app limpa as conquistas.
    Q_INVOKABLE void emitGameCleared() { emit clearedAchievements(); }

    Q_INVOKABLE void emitUpdatedRichText() { emit updatedRichText(); }

public slots:
    void signIn(const QString &, const QString &, const bool &) {}
    void signOut() {}
    void saveUISettings(const int &, const int &, const bool &, const bool &, const bool &, const bool &, const QString) {}
    void changeMode() {}
    void autoChange(const bool &) {}
    void refreshRAData() { ++m_refreshCalls; emit refreshCallsChanged(); }
    void beginUpdate() {}
    void ignoreUpdates(bool) {}
    void enableWebSocket(bool) {}

signals:
    void loginSuccess();
    void loginFailed(const QString &error);
    void changeModeFailed(const QString &reason);
    void achievementModelReady();
    void signedOut();
    void clearedAchievements();
    void displayMessage(const QString &error, const bool &iserror);
    void consoleChanged();
    void themeChanged();
    void disableModeSwitching();
    void enableModeSwitching();
    void newUpdate();
    void ignoreChanged();
    void updatedRichText();
    void websocketChanged();
    void firmwareChanged();
    void refreshCallsChanged();

private:
    QString m_richPresence = QStringLiteral("Kong Quest - Gangplank Galley");
    int m_refreshCalls = 0;

public:
    FakeRa2snes()
    {
        // Um tema "de terceiro" na pasta themes/ do app, como um usuário instalaria.
        QDir(m_appDir.path()).mkpath(QStringLiteral("themes"));
        QFile::copy(QStringLiteral(RA2SNES_TEST_FIXTURES "/LegacyDark.qml"),
                    m_appDir.path() + QStringLiteral("/themes/LegacyDark.qml"));
    }

private:
    // Pasta de app vazia: a janela varre themes/ e sounds/ dela.
    QTemporaryDir m_appDir;
};

// Dispara, a partir do QML, os mesmos caminhos que o app percorre num
// desbloqueio ao vivo: o unlockAchievement() real e os sinais reais de jogo.
class TestHooks : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE bool unlock(int id)
    {
        return AchievementModel::instance()->unlockAchievement(id, QDateTime::currentDateTime()) != nullptr;
    }

    Q_INVOKABLE void emitBeaten() { emit GameInfoModel::instance()->beatenGame(); }
    Q_INVOKABLE void setTheme(const QString &name) { UserInfoModel::instance()->theme(name); }
    Q_INVOKABLE void setCompact(bool compact) { UserInfoModel::instance()->compact(compact); }
    Q_INVOKABLE void setAvatar(const QUrl &url) { UserInfoModel::instance()->pfp(url); }
    Q_INVOKABLE void setBeaten(bool beaten) { GameInfoModel::instance()->beaten(beaten); }
    Q_INVOKABLE void setMastered(bool mastered) { GameInfoModel::instance()->mastered(mastered); }
    Q_INVOKABLE void emitMastered() { emit GameInfoModel::instance()->masteredGame(); }
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
        game->md5hash(QStringLiteral("d323e6bb4ccc85fd7b416f58350bc1a2"));

        UserInfoModel *user = UserInfoModel::instance();
        user->username(QStringLiteral("SuperNinTaylor"));
        user->hardcore(true);
        user->hardcore_score(8205);
        user->softcore_score(12);
        user->theme(QStringLiteral("Dark"));
        user->width(1000);
        user->height(700);
        user->icons(true);
        user->compact(false);

        // Estados variados de propósito: desbloqueada, com progresso, e os três
        // tipos com ícone — cada combinação exercita um ramo do delegate.
        const QStringList titles = {
            "DK: Donkey Kong", "Kremling Kurrency", "KONGQuest", "Lost World",
            "Bramble Scramble", "Krow's Nest", "Hot-Head Hop", "Kleever's Kiln",
            "Mainbrace Mayhem", "Gangplank Galley", "Lockjaw's Locker", "Topsail Trouble"
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
        qmlRegisterSingletonInstance("TestSupport", 1, 0, "TestHooks", &m_hooks);
    }

private:
    FakeRa2snes m_ra2snes;
    TestHooks m_hooks;
};

QUICK_TEST_MAIN_WITH_SETUP(ra2snes_qml, Setup)

#include "tst_qml.moc"
