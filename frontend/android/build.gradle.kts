buildscript {
    repositories {
        maven { url = uri("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/") }
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.1")
        // 移除了 Kotlin Gradle Plugin 依赖
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val flutterBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(flutterBuildDir)

subprojects {
    layout.buildDirectory.value(flutterBuildDir.dir(name))
}

subprojects {
    evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
