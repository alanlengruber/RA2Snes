#include <QtTest>
#include "achievementmodel.h"
#include "rastructs.h"

class TestAchievementModel : public QObject
{
    Q_OBJECT

private slots:
    void init();
    void cleanup();
    void modelStartsEmpty();
    void emitsPayloadOnLiveUnlock();
    void doesNotEmitOnSetUnlockedState();
    void getMatchesToVariantMap();
};

void TestAchievementModel::init()
{
    AchievementModel::instance()->clearAchievements();
}

void TestAchievementModel::cleanup()
{
    AchievementModel::instance()->clearAchievements();
}

void TestAchievementModel::modelStartsEmpty()
{
    QCOMPARE(AchievementModel::instance()->rowCount(), 0);
}

static AchievementInfo makeAchievement()
{
    AchievementInfo a;
    a.id = 42;
    a.title = "KONGQuest";
    a.description = "Clear Gangplank Galley";
    a.points = 7;
    a.badge_url = QUrl("https://media.retroachievements.org/Badge/12345.png");
    a.badge_locked_url = QUrl("https://media.retroachievements.org/Badge/12345_lock.png");
    a.target = 3;
    return a;
}

void TestAchievementModel::emitsPayloadOnLiveUnlock()
{
    AchievementModel *model = AchievementModel::instance();
    model->setAchievements({ makeAchievement() });

    QSignalSpy spy(model, &AchievementModel::achievementUnlocked);
    model->unlockAchievement(42, QDateTime::currentDateTime());

    QCOMPARE(spy.count(), 1);
    const QVariantMap payload = spy.takeFirst().at(0).toMap();
    QCOMPARE(payload.value("title").toString(), QStringLiteral("KONGQuest"));
    QCOMPARE(payload.value("points").toUInt(), 7u);
    QCOMPARE(payload.value("id").toUInt(), 42u);
    QVERIFY(payload.value("unlocked").toBool());
    QVERIFY(!payload.value("badgeUrl").toUrl().isEmpty());
}

void TestAchievementModel::doesNotEmitOnSetUnlockedState()
{
    AchievementModel *model = AchievementModel::instance();
    model->setAchievements({ makeAchievement() });

    QSignalSpy payloadSpy(model, &AchievementModel::achievementUnlocked);
    QSignalSpy soundSpy(model, &AchievementModel::unlockedChanged);

    model->setUnlockedState(0, true, QDateTime::currentDateTime());

    QCOMPARE(payloadSpy.count(), 0);
    QCOMPARE(soundSpy.count(), 0);
}

void TestAchievementModel::getMatchesToVariantMap()
{
    AchievementModel *model = AchievementModel::instance();
    const AchievementInfo a = makeAchievement();
    model->setAchievements({ a });

    QCOMPARE(model->get(0), model->toVariantMap(a));
}

QTEST_MAIN(TestAchievementModel)
#include "tst_achievementmodel.moc"
