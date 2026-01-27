//android\build.gradle.kts

import org.jetbrains.kotlin.gradle.dsl.JvmTarget

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Classpath untuk Firebase Performance Plugin
        classpath("com.google.firebase:perf-plugin:1.4.2") 
    }
}

configurations.all {
    resolutionStrategy {
        eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.1.10")
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
