buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // هنا يتم تعريف الأدوات التي تستخدمها ملفات البناء
        // تأكد من أن نسخة AGP متوافقة مع نسخة Flutter لديك (غالباً Flutter يديرها، لكن جوجل سيرفسز نحن نضيفها)

        // ✅ هذا هو السطر الضروري لربط الفايربيز
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// إعدادات مجلد البناء الخاصة بفلاتر (لا تعدلها)
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// مهمة التنظيف
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}