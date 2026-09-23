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

QTEST_MAIN(TestAchievementModel)
#include "tst_achievementmodel.moc"
