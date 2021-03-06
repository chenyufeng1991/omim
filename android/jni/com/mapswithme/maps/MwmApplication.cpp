#include "Framework.hpp"

#include "../core/jni_helper.hpp"

#include "../platform/Platform.hpp"

#include "map/information_display.hpp"
#include "map/location_state.hpp"


extern "C"
{
  JNIEXPORT void JNICALL
  Java_com_mapswithme_maps_MwmApplication_nativeInit(
      JNIEnv * env, jobject thiz,
      jstring apkPath, jstring storagePath, jstring tmpPath, jstring obbGooglePath,
      jstring flavorName, jstring buildType, jboolean isYota, jboolean isTablet)
  {
    android::Platform::Instance().Initialize(
        env, apkPath, storagePath, tmpPath, obbGooglePath, flavorName, buildType, isYota, isTablet);

    LOG(LDEBUG, ("Creating android::Framework instance ..."));

    if (!g_framework)
      g_framework = new android::Framework();

    LOG(LDEBUG, ("android::Framework created"));
  }

  JNIEXPORT jboolean JNICALL
  Java_com_mapswithme_maps_MwmApplication_nativeIsBenchmarking(JNIEnv * env, jobject thiz)
  {
    return static_cast<jboolean>(g_framework->NativeFramework()->IsBenchmarking());
  }

  JNIEXPORT jboolean JNICALL
  Java_com_mapswithme_maps_MwmApplication_hasFreeSpace(JNIEnv * env, jobject thiz, jlong size)
  {
    return android::Platform::Instance().HasAvailableSpaceForWriting(size);
  }

  JNIEXPORT void JNICALL
  Java_com_mapswithme_maps_MwmApplication_nativeAddLocalization(JNIEnv * env, jobject thiz, jstring name, jstring value)
  {
    g_framework->AddString(jni::ToNativeString(env, name),
                           jni::ToNativeString(env, value));
  }
}
