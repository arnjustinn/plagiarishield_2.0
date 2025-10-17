// Top-level build.gradle.kts (Project-level)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Android Gradle plugin
        classpath("com.android.tools.build:gradle:8.1.0")
        // Kotlin Gradle plugin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        // Flutter plugin
        //classpath("dev.flutter:flutter-gradle-plugin:1.2.1") // version matches your Flutter setup
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directories (optional)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
