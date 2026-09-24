find_package(Qt6 REQUIRED COMPONENTS Test QuickTest)

qt_add_executable(tst_achievementmodel
    tst_achievementmodel.cpp
    ${CMAKE_SOURCE_DIR}/achievementmodel.cpp
    ${CMAKE_SOURCE_DIR}/achievementmodel.h
    ${CMAKE_SOURCE_DIR}/rastructs.h
)
target_include_directories(tst_achievementmodel PRIVATE ${CMAKE_SOURCE_DIR})
target_link_libraries(tst_achievementmodel PRIVATE Qt6::Core Qt6::Test)
add_test(NAME achievementmodel COMMAND tst_achievementmodel)

qt_add_executable(tst_qml
    tst_qml.cpp
    ${CMAKE_SOURCE_DIR}/userinfomodel.cpp
    ${CMAKE_SOURCE_DIR}/userinfomodel.h
    ${CMAKE_SOURCE_DIR}/gameinfomodel.cpp
    ${CMAKE_SOURCE_DIR}/gameinfomodel.h
    ${CMAKE_SOURCE_DIR}/achievementmodel.cpp
    ${CMAKE_SOURCE_DIR}/achievementmodel.h
    ${CMAKE_SOURCE_DIR}/achievementsortfilterproxymodel.cpp
    ${CMAKE_SOURCE_DIR}/achievementsortfilterproxymodel.h
    ${CMAKE_SOURCE_DIR}/rastructs.h
)
target_include_directories(tst_qml PRIVATE ${CMAKE_SOURCE_DIR})
target_compile_definitions(tst_qml PRIVATE RA2SNES_TEST_FIXTURES="${CMAKE_CURRENT_SOURCE_DIR}/qml/fixtures")
target_link_libraries(tst_qml PRIVATE Qt6::QuickTest Qt6::Qml Qt6::Quick)
add_test(NAME qml COMMAND tst_qml -input ${CMAKE_CURRENT_SOURCE_DIR}/qml)
