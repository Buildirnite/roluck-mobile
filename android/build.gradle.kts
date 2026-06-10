allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Algunos plugins (p. ej. file_picker) fijan un compileSdk antiguo (34) en su
// propio build.gradle y no heredan el de la app. Como dependencias transitivas
// más nuevas exigen compilar contra API 36+, forzamos el compileSdk de todos
// los módulos de librería Android a 36. Se registra ANTES de evaluationDependsOn
// para que los subproyectos aún no estén evaluados al añadir el afterEvaluate.
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                compileSdk = 36
                // Algunos plugins (p. ej. flutter_avif) fijan Java en 11 mientras el
                // Kotlin Gradle Plugin usa por defecto el JVM del JDK que corre Gradle
                // (21), provocando "Inconsistent JVM Target Compatibility". Alineamos
                // ambos a 17 para todas las librerías.
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
        // Forzar el jvmTarget de Kotlin a 17 en cada subproyecto para que coincida
        // con la tarea de Java y evitar el fallo de compatibilidad de JVM target.
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }

        // flutter_avif_android 3.1.0 incluye por error DOS definiciones de la misma
        // clase FlutterAvifPlugin (una en .kt y otra en .java, idénticas), lo que
        // provoca "Redeclaration: class FlutterAvifPlugin" al compilar Kotlin
        // (kotlinc recibe los .java como source roots y un exclude no basta).
        // Borramos el .java duplicado del módulo; el .kt es la versión canónica.
        // Se re-aplica solo si el cache de pub se repara.
        if (project.name == "flutter_avif_android") {
            val dupJava = project.file("src/main/java/com/teknorota/flutter_avif/FlutterAvifPlugin.java")
            if (dupJava.exists()) {
                dupJava.delete()
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
